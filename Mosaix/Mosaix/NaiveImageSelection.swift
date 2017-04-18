//
//  NaiveImageSelection.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit
import Photos

struct NaiveSelectionConstants {
    static let skipSize = 26 //Number of pixels to skip over when checking
}

enum NaiveSelectionError: Error {
    case InvalidSkipSize
    case RegionMismatch
}

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

class NaiveImageSelection: ImageSelection {
    private var referenceImage : UIImage
    private var allPhotos : PHFetchResult<PHAsset>?
    private var imageManager : PHImageManager
    
    required init(refImage: UIImage) {
        self.referenceImage = refImage
        self.imageManager = PHImageManager()
        self.allPhotos = nil
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
                case .authorized:
                    let fetchOptions = PHFetchOptions()
                    self.allPhotos = PHAsset.fetchAssets(with: fetchOptions)
                case .denied, .restricted:
                    print("Library Access Denied!")
                case .notDetermined:
                    print("Library Access Not Determined!")
            }
        }
    }
    
    private func compareRegions(refRegion: Region, otherImage: UIImage, otherRegion: Region) throws -> CGFloat {
        guard (refRegion.width == otherRegion.width && refRegion.height == otherRegion.height) else {
            throw NaiveSelectionError.RegionMismatch
        }
        guard (NaiveSelectionConstants.skipSize >= 0) else {
            throw NaiveSelectionError.InvalidSkipSize
        }
        var fit : CGFloat = 0.0
        
        var refRGB : (red: CGFloat, blue: CGFloat, green: CGFloat) = (0,0,0)
        var othRGB : (red: CGFloat, blue: CGFloat, green: CGFloat) = (0,0,0)
        
        for deltaY in stride(from: 0, to: refRegion.height - 1, by: 1 + NaiveSelectionConstants.skipSize) {
//            print("row \(deltaY+1)/\(refRegion.height) (current fit: \(fit))")
            for deltaX in stride(from: 0, to: refRegion.width - 1, by: 1 + NaiveSelectionConstants.skipSize) {
                let refPoint = CGPoint(x:Int(refRegion.topLeft.x) + deltaX,y:Int(refRegion.topLeft.y) + deltaY)
                let refColor = self.referenceImage.getPixelColor(pos: refPoint)
                
                let otherPoint = CGPoint(x:Int(otherRegion.topLeft.x) + deltaX, y: Int(otherRegion.topLeft.y) + deltaY)
                let otherColor = otherImage.getPixelColor(pos: otherPoint)
                
                refColor.getRed(&refRGB.red, green: &refRGB.green, blue: &refRGB.blue, alpha: nil)
                otherColor.getRed(&othRGB.red, green: &othRGB.green, blue: &othRGB.blue, alpha: nil)
                fit += abs(refRGB.red - othRGB.red) + abs(refRGB.blue - othRGB.blue) + abs(refRGB.green - othRGB.green)
            }
        }
        return fit
    }
    
    private func findBestMatch(row: Int, col: Int, refRegion: Region, onSelect : @escaping (ImageChoice) -> Void) {
        print("(\(row), \(col)) finding best match (coordinates \(refRegion.topLeft) <-> \(refRegion.bottomRight)")
        var bestMatch : ImageChoice? = nil
        allPhotos?.enumerateObjects({(asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if (asset.mediaType == .image) {
                let targetSize = CGSize(width: refRegion.width, height: refRegion.height)
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.default, options: options,
                                               resultHandler: {(result, info) -> Void in
                                                if (result != nil) {
//                                                    print("  has image")
                                                    do {
                                                        let choiceRegion = Region(topLeft: CGPoint.zero, bottomRight: CGPoint(x: refRegion.width, y: refRegion.height))
                                                        let fit : CGFloat = try self.compareRegions(refRegion: refRegion, otherImage: result!, otherRegion: choiceRegion)
                                                        if (bestMatch == nil || fit < bestMatch!.fit) {
                                                            bestMatch = ImageChoice(position: (row, col), image: result!, region: choiceRegion, fit: fit)
                                                        }
                                                    } catch {
                                                        print("Region mismatch!!!")
                                                    }
                                                }
                })
            }
        })
        onSelect(bestMatch!)
    }
    
    func select(gridSizePoints: Int, onSelect: @escaping (ImageChoice) -> Void) throws -> Void {
        if (allPhotos == nil) {
            throw ImageSelectionError.PreprocessingIncomplete
        }
        let numRows : Int = Int(self.referenceImage.size.height) / gridSizePoints
        let numCols : Int = Int(self.referenceImage.size.width) / gridSizePoints
//        print("selecting with grid size \(gridSizePoints), \(numRows) rows, and \(numCols) columns.")
        for row in 0 ... numRows-1 {
            for col in 0 ... numCols-1 {
                let topLeft : CGPoint = CGPoint(x: col * gridSizePoints, y: row * gridSizePoints)
                let bottomRight : CGPoint = CGPoint(x: (col + 1) * gridSizePoints, y: (row+1) * gridSizePoints)
                findBestMatch(row: row, col: col, refRegion: Region(topLeft: topLeft, bottomRight: bottomRight), onSelect: onSelect)
            }
        }
    }
}
