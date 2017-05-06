//
//  TPADictionary.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/5/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos

class TPADictionary : NSObject, TPAStorage {
    
    public var pListPath = "dictionary.plist"

    private var averages : [PHAsset : TenPointAverage]
    
    required override init() {
        self.averages = [:]
        super.init()
    }
    
    func insert(asset: PHAsset, tpa: TenPointAverage) {
        self.averages[asset] = tpa
    }
    
    func isMember(_ asset: PHAsset) -> Bool {
        return (self.averages[asset] != nil)
    }
    
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: PHAsset, diff: Float)? {
        var bestFit : PHAsset? = nil
        var bestDiff : CGFloat = 0.0
        for (asset, assetTPA) in self.averages {
            let diff = assetTPA - refTPA
            if (bestFit == nil || diff < bestDiff) {
                bestFit = asset
                bestDiff = diff
            }
        }
        if (bestFit != nil) {
            return (bestFit!, Float(bestDiff))
        } else {
            return nil
        }
    }
    
    //NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        print("Decoding averages")
        self.averages = [:]
        var averages: [PHAsset : TenPointAverage] = [:]
        
        let identifiers : [String: TenPointAverage] = aDecoder.decodeObject(forKey: "identifier_averages") as! [String : TenPointAverage]
        
        for (identifier, assetTPA) in identifiers {
            let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            asset.enumerateObjects({ (asset, _, _) in
                averages[asset] = assetTPA
            })
        }
        
        self.averages = averages
    }
    
    
    func encode(with aCoder: NSCoder) -> Void{
        print("Trying to encode averages")
        var identifiers : [String : TenPointAverage] = [:]
        for (asset, assetTPA) in self.averages {
            identifiers[asset.localIdentifier] = assetTPA
        }
        aCoder.encode(identifiers, forKey: "identifier_averages")
        print("Averages encoded")
    }
    
}
