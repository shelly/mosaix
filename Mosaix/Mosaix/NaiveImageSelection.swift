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
    
    private func findBestMatch(row: Int, col: Int, topLeft: (x: Int, y: Int), bottomRight: (x: Int, y: Int), onSelect : @escaping (ImageChoice) -> Void) {
        allPhotos?.enumerateObjects({(asset: PHAsset, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            if (asset.mediaType == .image) {
                self.imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: PHImageRequestOptions(),
                                               resultHandler: {(result, info) -> Void in
                                                if (result != nil) {
                                                    let choice = ImageChoice(position: (row, col), image: result!, topLeft: topLeft, bottomRight: bottomRight)
                                                    stop.pointee = true
                                                    onSelect(choice)
                                                }
                })
            }
        })
    }
    
    func select(gridSizePoints: Int, onSelect: @escaping (ImageChoice) -> Void) throws -> Void {
        if (allPhotos == nil) {
            throw ImageSelectionError.PreprocessingIncomplete
        }
        let numRows : Int = Int(self.referenceImage.size.height) / gridSizePoints
        let numCols : Int = Int(self.referenceImage.size.width) / gridSizePoints
        for row in 0 ... numRows-1 {
            for col in 0 ... numCols-1 {
                let topLeft : (Int, Int) = (col * gridSizePoints, row * gridSizePoints)
                let bottomRight : (Int, Int) = ((col + 1) * gridSizePoints, (row+1) * gridSizePoints)
                findBestMatch(row: row, col: col, topLeft: topLeft, bottomRight: bottomRight, onSelect: onSelect)
            }
        }
    }
}
