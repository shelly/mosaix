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
    private var averages : [String : TenPointAverage]
    var tpaIds: [String]
    var tpaData : [UInt32]

    
    required override init() {
        self.averages = [:]
        self.tpaIds = []
        self.tpaData = []
        super.init()
    }
    
    func insert(asset: String, tpa: TenPointAverage) {
        self.averages[asset] = tpa
        self.tpaIds.append(asset)
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
    
    //NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        print("Decoding averages")
        self.tpaIds = aDecoder.decodeObject(forKey: "tpaIds") as! [String]
        self.tpaData = aDecoder.decodeObject(forKey: "tpaData") as! [UInt32]
        self.averages = aDecoder.decodeObject(forKey: "identifier_averages") as! [String : TenPointAverage]
    }
    
    
    func encode(with aCoder: NSCoder) -> Void{
        print("Trying to encode averages")
        aCoder.encode(self.averages, forKey: "identifier_averages")
        aCoder.encode(self.tpaIds, forKey: "tpaIds")
        aCoder.encode(self.tpaData, forKey: "tpaData")
        print("Averages encoded")
    }
    
}
