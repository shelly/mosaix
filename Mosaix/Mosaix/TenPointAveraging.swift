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
    static let gridsAcross = 5
    static let numCells = TenPointAverageConstants.gridsAcross * TenPointAverageConstants.gridsAcross
}

class TenPointAverage : NSObject, NSCoding {
    var totalAvg : RGBFloat = RGBFloat(0,0,0)
    var gridAvg : [[RGBFloat]] = Array(repeating: Array(repeating: RGBFloat(0,0,0), count: TenPointAverageConstants.gridsAcross), count: TenPointAverageConstants.gridsAcross)
    
    override init () {
        super.init()
        //Setup if necessary
    }
    
    static func -(left: TenPointAverage, right: TenPointAverage) -> CGFloat {
        var diff : CGFloat = 0.0
        for row in 0 ..< TenPointAverageConstants.gridsAcross {
            for col in 0 ..< TenPointAverageConstants.gridsAcross {
                diff += pow(abs(left.gridAvg[row][col] - right.gridAvg[row][col]), 2)
            }
        }
        return sqrt(diff)
    }
    
    static func ==(left: TenPointAverage, right: TenPointAverage) -> Bool {
        for i in 0 ..< TenPointAverageConstants.gridsAcross {
            for j in 0 ..< TenPointAverageConstants.gridsAcross {
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

class TenPointAveraging: PhotoProcessor {
    private var inProgress : Bool
    private var storage : TPAArray
    private static var imageManager : PHImageManager?
    private var totalPhotos : Int
    private var photosComplete : Int
    static var metal : MetalPipeline? = nil
    private var timer : MosaicCreationTimer
    var threadWidth : Int = 1
    
    required init(timer: MosaicCreationTimer) {
        self.inProgress = false
        self.storage = TPAArray()
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
                        print("processed photos")
                        //Save to file
                        print("Asset 1:")
                        for i in 0 ..< TenPointAverageConstants.numCells {
                            let baseIndex = (TenPointAverageConstants.numCells * 1 + i) * 3
                            let one = self.storage.tpaData[baseIndex + 0]
                            let two = self.storage.tpaData[baseIndex + 1]
                            let thr = self.storage.tpaData[baseIndex + 2]
                            print(" \(one), \(two), \(thr))")
                        }
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
    
    func findNearestMatches(results: [UInt32], rows: Int, cols: Int, complete: @escaping ([String]) -> Void) -> Void {
        TenPointAveraging.metal!.processNearestAverages(refTPAs: results, otherTPAs: self.storage.tpaData, rows: rows, cols: cols, threadWidth: 32, complete: {(matchIndexes, diffs) -> Void in
            print("Ok, we're done processing nearest averages. Asset \(matchIndexes[0])")
            let numCells = TenPointAverageConstants.gridsAcross * TenPointAverageConstants.gridsAcross
            for j in 1 ..< 3 {
                var diff : Decimal = 0.0
                print("figuring out index \(j). Chose Asset \(matchIndexes[j]) (id=\(self.storage.tpaIds[Int(matchIndexes[j])]))")
                for i in 0 ..< numCells {
                    let baseIndex = (numCells * Int(matchIndexes[j]) + i) * 3
                    let one = self.storage.tpaData[baseIndex + 0]
                    let two = self.storage.tpaData[baseIndex + 1]
                    let thr = self.storage.tpaData[baseIndex + 2]
                    let refIndex = (numCells + j) * i
                    let un = results[refIndex]
                    let dos = results[refIndex + 1]
                    let tres = results[refIndex + 2]
                    print(" (\(one), \(two), \(thr)) vs (\(un), \(dos), \(tres))")
                    diff += pow(Decimal(one) - Decimal(un), 2) + pow(Decimal(two) - Decimal(dos), 2) + pow(Decimal(thr) - Decimal(tres), 2)
                }
                print(" Reporting diff of \(diffs[j]). Actually, it's \(diff)")
            }
            
            var assetIds : [String] = []
            for i in 0 ..< matchIndexes.count {
                let index: Int = Int(matchIndexes[i])
                assetIds.append(self.storage.tpaIds[index])
            }
            
            
//            complete(matchIndexes.map({(tpaIndex) -> String in
//                
//                return self.storage.tpaIds[Int(tpaIndex)]
//            }))
            complete(assetIds)
        })
    }
    

    private func processAllPhotos(userAlbums: PHFetchResult<PHAssetCollection>, complete: @escaping (_ changed: Bool) -> Void) {
        var changed: Bool = false
        userAlbums.enumerateObjects({(collection: PHAssetCollection, albumIndex: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            stop.pointee = true
            let options = PHFetchOptions()
//            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ["8B2771E5-C81A-46D9-B9CC-799256008AB1/L0/001", "2E78586A-BC28-49B6-BAEF-A7692C8126D0/L0/001"], options: options)
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
            TenPointAveraging.metal?.processImageTexture(texture: texture!, width: image.width, height: image.height, threadWidth: self.threadWidth, complete: {(result : [UInt32]) -> Void in
                let tba = TenPointAverage()
                for i in 0 ..< TenPointAverageConstants.numCells {
                    let index = i * 3
                    let row = i / TenPointAverageConstants.gridsAcross
                    let col = i % TenPointAverageConstants.gridsAcross
                    tba.totalAvg.r += CGFloat(result[index])/CGFloat(TenPointAverageConstants.numCells)
                    tba.totalAvg.g += CGFloat(result[index+1])/CGFloat(TenPointAverageConstants.numCells)
                    tba.totalAvg.b += CGFloat(result[index+2])/CGFloat(TenPointAverageConstants.numCells)
                    tba.gridAvg[row][col] = RGBFloat(CGFloat(Int(result[index])), CGFloat(Int(result[index+1])), CGFloat(Int(result[index+2])))
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
            .appendingPathComponent(String(TenPointAverageConstants.gridsAcross) + self.storage.pListPath)
        
        if let stored = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path) as? TPAArray {
            
            self.storage = stored 
            print("self.storage successfully loaded from file.\n")
            
        }
    }
    
    private func saveStorageToFile() -> Void {
        
        print("Trying to save storage to file.\n")
        
        let toStore = NSKeyedArchiver.archivedData(withRootObject: self.storage)
        
        let fileURL = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(String(TenPointAverageConstants.gridsAcross) + self.storage.pListPath)
        
        do {
            try toStore.write(to: fileURL)
        } catch {
            print("Could not store self.storage to file.\n")
        }
        
    }
    
}
