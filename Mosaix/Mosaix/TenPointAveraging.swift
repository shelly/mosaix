//
//  TenPointAveraging.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/18/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos
import MetalKit
import Metal


class RGBFloat : CustomStringConvertible {
    var r : CGFloat
    var g: CGFloat
    var b: CGFloat
    
    init(_ red : CGFloat, _ green : CGFloat, _ blue : CGFloat) {
        self.r = red
        self.g = green
        self.b = blue
    }
    
    init(_ red : Int, _ green : Int, _ blue : Int) {
        self.r = CGFloat(red)
        self.g = CGFloat(green)
        self.b = CGFloat(blue)
    }
    
    func get(_ index: Int) -> CGFloat {
        if (index == 0) {
            return self.r
        } else if (index == 1) {
            return self.g
        } else {
            return self.b
        }
    }
    
    static func -(left: RGBFloat, right: RGBFloat) -> CGFloat {
        return abs(left.r-right.r) + abs(left.g-right.g) + abs(left.b-right.b)
    }
    
    static func ==(left: RGBFloat, right: RGBFloat) -> Bool {
        return left.r == right.r && left.g == right.g && left.b == right.b
    }
    
    var description : String {
        return "(\(self.r), \(self.g), \(self.b))"
    }
}

struct TenPointAverageConstants {
    static let rows = 3
    static let cols = 3
}

class TenPointAverage {
    var totalAvg : RGBFloat = RGBFloat(0,0,0)
    var gridAvg : [[RGBFloat]] = Array(repeating: Array(repeating: RGBFloat(0,0,0), count: 3), count: 3)
    
    static func -(left: TenPointAverage, right: TenPointAverage) -> CGFloat {
        var diff : CGFloat = 0.0
        diff += abs(left.totalAvg - right.totalAvg)
        for row in 0..<TenPointAverageConstants.rows {
            for col in 0..<TenPointAverageConstants.cols {
                diff += abs(left.gridAvg[row][col] - right.gridAvg[row][col])
            }
        }
        return diff
    }
    
    static func ==(left: TenPointAverage, right: TenPointAverage) -> Bool {
        for i in 0 ..< 3 {
            for j in 0 ..< 3 {
                if !(left.gridAvg[i][j] == right.gridAvg[i][j]) {
                    return false
                }
            }
        }
        return true
    }
}

class MetalPipeline {
    let device : MTLDevice
    let commandQueue : MTLCommandQueue
    let library: MTLLibrary
    let NinePointAverage : MTLFunction
    var pipelineState : MTLComputePipelineState? = nil
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()
        self.library = self.device.newDefaultLibrary()!
        self.NinePointAverage = self.library.makeFunction(name: "findNinePointAverage")!
        do {
            self.pipelineState = try self.device.makeComputePipelineState(function: self.NinePointAverage)
        } catch {
            print("Error initializing pipeline state!")
        }
    }
    
    func getImageTexture(image: CGImage) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self.device)
        return try textureLoader.newTexture(with: image)
    }
    
    private func getImageTextureRaw(image: CGImage) -> MTLTexture {
        let rawData = calloc(image.height * image.width * 4, MemoryLayout<UInt8>.size)
        let bytesPerRow = 4 * image.width
        let options = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let context = CGContext(
            data: rawData,
            width: image.width,
            height: image.height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: options
        )

        context?.draw(image, in : CGRect(x:0, y: 0, width: image.width, height: image.height))
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: image.width,
            height: image.height,
            mipmapped: true
        )

        let texture : MTLTexture = self.device.makeTexture(descriptor: textureDescriptor)
        texture.replace(region: MTLRegionMake2D(0, 0, image.width, image.height),
                        mipmapLevel: 0,
                        slice: 0,
                        withBytes: rawData!,
                        bytesPerRow: bytesPerRow,
                        bytesPerImage: bytesPerRow * image.height)
        free(rawData)
        return texture
    }
    
    func processImageTexture(texture: MTLTexture, complete : @escaping ([UInt32]) -> Void) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(self.pipelineState!)
        commandEncoder.setTexture(texture, at: 0)
        let bufferCount = 3 * 9
        let bufferLength = MemoryLayout<UInt32>.size * bufferCount
        let resultBuffer = self.device.makeBuffer(length: bufferLength)
        commandEncoder.setBuffer(resultBuffer, offset: 0, at: 0)
        let gridSize : MTLSize = MTLSize(width: 9, height: 1, depth: 1)
        let threadGroupSize : MTLSize = MTLSize(width: 512, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            let results : [UInt32] = Array(UnsafeBufferPointer(start: resultBuffer.contents().assumingMemoryBound(to: UInt32.self), count: bufferCount))
//            print("\(results)")
            complete(results)
        })
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

class TenPointAveraging: PhotoProcessor {

    
    private var inProgress : Bool
    private var storage : TPAStorage
    private static var imageManager : PHImageManager?
    private var totalPhotos : Int
    private var photosComplete : Int
    private static var metal : MetalPipeline? = nil
    
    init() {
        self.inProgress = false
        self.storage = KDTree()
        self.totalPhotos = 0
        self.photosComplete = 0
        if (TenPointAveraging.imageManager == nil) {
            TenPointAveraging.imageManager = PHImageManager()
        }
        if (TenPointAveraging.metal == nil) {
            TenPointAveraging.metal = MetalPipeline()
        }
    }
    
    func preprocess(complete: @escaping () -> Void) throws -> Void {
        guard (self.inProgress == false) else {
            throw LibraryProcessingError.PreprocessingInProgress
        }
        self.inProgress = true
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                
                let userAlbumsOptions = PHFetchOptions()
                userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
                let userAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumSyncedAlbum, options: userAlbumsOptions)
                
                
                
                //                self.processAllPhotos(fetchResult: PHAsset.fetchAssets(with: .image, options: fetchOptions), complete: {() -> Void in
                self.processAllPhotos(userAlbums: userAlbums, complete: {() -> Void in
                    //Save to file
                    complete()
                })
            case .denied, .restricted:
                print("Library Access Denied!")
            case .notDetermined:
                print("Library Access Not Determined!")
            }
        }
    }
    
    private func loadFromFile() {
//        let manager = NSFileManager.defaultManager()
//        let dirURL = manager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainmask, appropriateForURL: nil, create: false, error: nil))
    }
    
    func findNearestMatch(tpa: TenPointAverage) -> (PHAsset, Float)? {
        return self.storage.findNearestMatch(to: tpa)
    }
    
 
    private func processAllPhotos(userAlbums: PHFetchResult<PHAssetCollection>, complete: @escaping () -> Void) {
        
        userAlbums.enumerateObjects({(collection: PHAssetCollection, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if collection.estimatedAssetCount > 0 {
                stop.pointee = true
                let fetchResult = PHAsset.fetchAssets(in: collection, options: PHFetchOptions())
                self.totalPhotos = fetchResult.count
                print("Processing all photos from \(collection.localizedTitle)")
                self.photosComplete = 0
                var i : Int = 0
                fetchResult.enumerateObjects({(asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                    if (asset.mediaType == .image && !self.storage.isMember(asset)) {
                        //Asynchronously grab image and save the values.
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        let _ = autoreleasepool {
                            TenPointAveraging.imageManager?.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: options,
                                                                         resultHandler: {(result, info) -> Void in
                                                                            if (result != nil) {
                                                                                i += 1
                                                                                //                                                        if (i > 600) {
                                                                                //                                                            stop.pointee = true
                                                                                //                                                            self.inProgress = false
                                                                                //                                                            complete()
                                                                                //                                                        }
                                                                                self.processPhoto(image: result!.cgImage!, complete: {(tpa) -> Void in
                                                                                    if (tpa != nil) {
                                                                                        self.storage.insert(asset: asset, tpa: tpa!)
                                                                                    }
                                                                                    self.photosComplete += 1
                                                                                    if (self.photosComplete == self.totalPhotos) {
                                                                                        self.inProgress = false
                                                                                        complete()
                                                                                    } else if (self.photosComplete % 20 == 0) {
                                                                                        print("\(self.photosComplete)/\(self.totalPhotos)")
                                                                                    }
                                                                                })
                                                                            } else {
                                                                                self.photosComplete += 1
                                                                                if (self.photosComplete == self.totalPhotos) {
                                                                                    self.inProgress = false
                                                                                    complete()
                                                                                }
                                                                            }
                            })
                        }
                    }
                })

            }
        })
    }
    
    func processPhoto(image: CGImage, complete: @escaping (TenPointAverage?) throws -> Void) -> Void {
        //Computes the average
        var texture : MTLTexture? = nil
        do {
            texture = try TenPointAveraging.metal?.getImageTexture(image: image)
        } catch {
            print("Error getting image texture!")
            do {
                try complete(nil)
            } catch {
                print("error in callback for null TPA")
            }
        }
        if (texture != nil) {
            TenPointAveraging.metal?.processImageTexture(texture: texture!, complete: {(result : [UInt32]) -> Void in
                let tba = TenPointAverage()
                for i in 0 ..< 3 {
                    for j in 0  ..< 3 {
                        let index = 9 * i + (3 * j)
                        tba.totalAvg.r += CGFloat(result[index])/9
                        tba.totalAvg.g += CGFloat(result[index+1])/9
                        tba.totalAvg.b += CGFloat(result[index+2])/9
                        tba.gridAvg[i][j] = RGBFloat(Int(result[index]), Int(result[index+1]), Int(result[index+2]))
                    }
                }
                do {
                    try complete(tba)
                } catch {
                    print("Error in completion callback for processing photo.")
                }
            })
        }
    }
    
    func preprocessProgress() -> Int {
        if (!self.inProgress) {return 0}
        return Int(100.0 * Float(self.photosComplete) / Float(self.totalPhotos))
    }
    
    func progress() -> Int {
        return 0 //TODO 
    }
    
}
