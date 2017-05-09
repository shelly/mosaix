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


class RGBFloat : NSObject, NSCoding {

    var r : CGFloat
    var g: CGFloat
    var b: CGFloat
    
    init(_ red : CGFloat, _ green : CGFloat, _ blue : CGFloat) {
        
        self.r = red
        self.g = green
        self.b = blue
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
    
    override var description : String {
        return "(\(self.r), \(self.g), \(self.b))"
    }
    
    //For NSCoding
    
    func encode(with aCoder: NSCoder) -> Void {
        aCoder.encode(r, forKey: "r")
        aCoder.encode(g, forKey: "g")
        aCoder.encode(b, forKey: "b")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.r = aDecoder.decodeObject(forKey: "r") as! CGFloat
        self.g = aDecoder.decodeObject(forKey: "g") as! CGFloat
        self.b = aDecoder.decodeObject(forKey: "b") as! CGFloat
    }
    
    
}

struct TenPointAverageConstants {
    static let rows = 3
    static let cols = 3
}

class TenPointAverage : NSObject, NSCoding {
    var totalAvg : RGBFloat = RGBFloat(0,0,0)
    var gridAvg : [[RGBFloat]] = Array(repeating: Array(repeating: RGBFloat(0,0,0), count: 3), count: 3)
    
    override init () {
        super.init()
        //Setup if necessary
    }
    
    static func -(left: TenPointAverage, right: TenPointAverage) -> CGFloat {
        var diff : CGFloat = 0.0
        for row in 0..<TenPointAverageConstants.rows {
            for col in 0..<TenPointAverageConstants.cols {
                diff += pow(abs(left.gridAvg[row][col] - right.gridAvg[row][col]), 2)
            }
        }
        return sqrt(diff)
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
    
    //For NSCoding
    
    func encode(with aCoder: NSCoder) -> Void {
        aCoder.encode(totalAvg, forKey: "totalAvg")
        aCoder.encode(gridAvg, forKey: "gridAvg")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.totalAvg = aDecoder.decodeObject(forKey: "totalAvg") as! RGBFloat
        self.gridAvg = aDecoder.decodeObject(forKey: "gridAvg") as! [[RGBFloat]]
    }
}

class MetalPipeline {
    let device : MTLDevice
    let commandQueue : MTLCommandQueue
    let library: MTLLibrary
    let NinePointAverage : MTLFunction
    let PhotoNinePointAverage : MTLFunction
    var pipelineState : MTLComputePipelineState? = nil
    var photoPipelineState : MTLComputePipelineState? = nil
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()
        self.library = self.device.newDefaultLibrary()!
        self.NinePointAverage = self.library.makeFunction(name: "findNinePointAverage")!
        self.PhotoNinePointAverage = self.library.makeFunction(name: "findPhotoNinePointAverage")!
        do {
            self.pipelineState = try self.device.makeComputePipelineState(function: self.NinePointAverage)
            self.photoPipelineState = try self.device.makeComputePipelineState(function: self.PhotoNinePointAverage)
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
    
    func processImageTexture(texture: MTLTexture, synchronous: Bool, threadWidth: Int, complete : @escaping ([UInt32]) -> Void) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(self.pipelineState!)
        commandEncoder.setTexture(texture, at: 0)
        let bufferCount = 3 * 9
        let bufferLength = MemoryLayout<UInt32>.size * bufferCount
        let resultBuffer = self.device.makeBuffer(length: bufferLength)
        commandEncoder.setBuffer(resultBuffer, offset: 0, at: 0)
        let gridSize : MTLSize = MTLSize(width: 9, height: 1, depth: 1)
        let threadGroupSize : MTLSize = MTLSize(width: threadWidth, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            let results : [UInt32] = Array(UnsafeBufferPointer(start: resultBuffer.contents().assumingMemoryBound(to: UInt32.self), count: bufferCount))
//            print("\(results)")
            complete(results)
        })
        commandBuffer.commit()
        if (synchronous) {
            commandBuffer.waitUntilCompleted()
        }
    }
    
    func processEntirePhotoTexture(texture: MTLTexture, synchronous: Bool, gridSize: Int,  numGridSpaces: Int, threadWidth: Int, complete: @escaping ([UInt32]) -> Void) {
        
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(self.photoPipelineState!)
        commandEncoder.setTexture(texture, at: 0)
        if (texture.width % gridSize != 0 || texture.height % gridSize != 0) {
            print("oh poopy")
        }
        
        let paramBufferLength = MemoryLayout<UInt32>.size * 1;
        let options = MTLResourceOptions()
        let params = UnsafeMutableRawPointer.allocate(bytes: MemoryLayout<UInt32>.size, alignedTo: 1)
        params.storeBytes(of: UInt32(gridSize), as: UInt32.self)
        let paramBuffer = self.device.makeBuffer(bytes: params, length: paramBufferLength, options: options)
        commandEncoder.setBuffer(paramBuffer, offset: 0, at: 0)
        
        
        print("num grid squares: \(numGridSpaces)")
        let bufferCount = 3 * 9 * numGridSpaces
        let bufferLength = MemoryLayout<UInt32>.size * bufferCount
        let resultBuffer = self.device.makeBuffer(length: bufferLength)
        commandEncoder.setBuffer(resultBuffer, offset: 0, at: 1)
        
        let gridSize : MTLSize = MTLSize(width: 9, height: 1, depth: 1)
        let threadGroupSize : MTLSize = MTLSize(width: threadWidth, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            let results : [UInt32] = Array(UnsafeBufferPointer(start: resultBuffer.contents().assumingMemoryBound(to: UInt32.self), count: bufferCount))
            //            print("\(results)")
            complete(results)
        })
        commandBuffer.commit()
        if (synchronous) {
            commandBuffer.waitUntilCompleted()
        }
    }
}

class TenPointAveraging: PhotoProcessor {
    private var inProgress : Bool
    private var storage : TPAStorage
    private static var imageManager : PHImageManager?
    private var totalPhotos : Int
    private var photosComplete : Int
    static var metal : MetalPipeline? = nil
    private var timer : MosaicCreationTimer
    var threadWidth : Int = 1
    
    required init(timer: MosaicCreationTimer) {
        self.inProgress = false
        self.storage = KDTree()
        self.totalPhotos = 0
        self.photosComplete = 0
        self.timer = timer
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
        let step = timer.task("TPA Preprocessing")
        DispatchQueue.global(qos: .background).async {
            self.loadStorageFromFile()
            step("Loading from file.")
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    let userAlbumsOptions = PHFetchOptions()
                    userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
                    let userAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumSyncedAlbum, options: userAlbumsOptions)
                    step("Fetching albums.")
                    self.processAllPhotos(userAlbums: userAlbums, complete: {(changed: Bool) -> Void in
                        step("Processing photos")
                        //Save to file
                        if (changed) {
                            self.saveStorageToFile()
                            step("Saving to file.")
                        }
                        DispatchQueue.main.async {
                            complete()
                        }
                    })
                case .denied, .restricted:
                    print("Library Access Denied!")
                case .notDetermined:
                    print("Library Access Not Determined!")
                }
            }
        }
    }
    
    func findNearestMatch(tpa: TenPointAverage) -> (String, Float)? {
        return self.storage.findNearestMatch(to: tpa)
    }
    

    private func processAllPhotos(userAlbums: PHFetchResult<PHAssetCollection>, complete: @escaping (_ changed: Bool) -> Void) {
        var changed: Bool = false
        userAlbums.enumerateObjects({(collection: PHAssetCollection, albumIndex: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            stop.pointee = true
            let options = PHFetchOptions()
//            options.fetchLimit = 1000
            let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            self.totalPhotos = fetchResult.count
            self.photosComplete = 0
            
            func step() {
                self.photosComplete += 1
//                print("\(self.photosComplete)/\(self.totalPhotos)")
                if (self.photosComplete == self.totalPhotos) {
                    self.inProgress = false
                    complete(changed)
                }
            }
            
            fetchResult.enumerateObjects({(asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                if (asset.mediaType == .image && !self.storage.isMember(asset.localIdentifier)) {
                    //Asynchronously grab image and save the values.
                    changed = true
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    let _ = autoreleasepool {
                        TenPointAveraging.imageManager?.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: options,
                                 resultHandler: {(result, info) -> Void in
                                    if (result != nil) {
                                        self.processPhoto(image: result!.cgImage!, synchronous: true, complete: {(tpa) -> Void in
                                            if (tpa != nil) {
                                                self.storage.insert(asset: asset.localIdentifier, tpa: tpa!)
                                            }
                                            step()
                                        })
                                    } else {
                                        step()
                                    }
                        })
                    }
                } else {
                    step()
                }
            })
        })
    }
    
    func processPhoto(image: CGImage, synchronous: Bool, complete: @escaping (TenPointAverage?) throws -> Void) -> Void {
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
            TenPointAveraging.metal?.processImageTexture(texture: texture!, synchronous: synchronous, threadWidth: self.threadWidth, complete: {(result : [UInt32]) -> Void in
                let tba = TenPointAverage()
                for i in 0 ..< 3 {
                    for j in 0  ..< 3 {
                        let index = 9 * i + (3 * j)
                        tba.totalAvg.r += CGFloat(result[index])/9
                        tba.totalAvg.g += CGFloat(result[index+1])/9
                        tba.totalAvg.b += CGFloat(result[index+2])/9
                        tba.gridAvg[i][j] = RGBFloat(CGFloat(Int(result[index])), CGFloat(Int(result[index+1])), CGFloat(Int(result[index+2])))
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
    
    //File Management
    
    private func loadStorageFromFile() -> Void {
        
        print("Trying to load storage from file.\n")

        let fileURL = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(self.storage.pListPath)
        
        if let stored = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? TPAStorage {
            
            self.storage = stored
            print("self.storage successfully loaded from file.\n")
            
        }
    }
    
    private func saveStorageToFile() -> Void {
        
        print("Trying to save storage to file.\n")
        
        let toStore = NSKeyedArchiver.archivedData(withRootObject: self.storage)
        
        let fileURL = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(self.storage.pListPath)
        
        do {
            try toStore.write(to: fileURL)
        } catch {
            print("Could not store self.storage to file.\n")
        }
        
    }
    
}
