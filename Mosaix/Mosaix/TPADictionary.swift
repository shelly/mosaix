//
//  TPADictionary.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/5/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos

class TPADictionary : TPAStorage {
    
    private var averages : [String : TenPointAverage]
    
    required init() {
        self.averages = [:]
    }
    
    func insert(asset: String, tpa: TenPointAverage) {
        self.averages[asset] = tpa
    }
    
    func isMember(_ asset: String) -> Bool {
        return (self.averages[asset] != nil)
    }
    
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: String, diff: Float)? {
        var bestFit : String? = nil
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
    
    func toString() -> String {
        return ""
    }
    
    static func fromString(storageString: String) -> TPAStorage? {
        return nil
    }
}
