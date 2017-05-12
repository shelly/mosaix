//
//  TPAArray.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/9/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation


class TPAArray: NSObject, TPAStorage, NSCoding {
    var pListPath : String = "array.plist"
    private var assets: Set<String>
    var tpaIds: [String]
    var tpaData : [UInt32]
    
    required override init() {
        self.assets = []
        self.tpaIds = []
        self.tpaData = []
    }
    
    func insert(asset : String, tpa: TenPointAverage) -> Void {
        self.assets.insert(asset)
        self.tpaIds.append(asset)
        for i in 0 ..< TenPointAverageConstants.gridsAcross {
            for j in 0 ..< TenPointAverageConstants.gridsAcross {
                for k in 0 ..< 3 {
                    self.tpaData.append(UInt32(tpa.gridAvg[i][j].get(k)))
                }
            }
        }
    }
    
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: String, diff: Float)? {
        return nil
    }
    
    func isMember(_ asset: String) -> Bool {
        return self.assets.contains(asset)
    }

    //NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        self.assets = aDecoder.decodeObject(forKey: "assets") as! Set<String>
        self.tpaIds = aDecoder.decodeObject(forKey: "tpaIds") as! [String]
        self.tpaData = aDecoder.decodeObject(forKey: "tpaData") as! [UInt32]
//        print("Decoding averages")
//        self.averages = aDecoder.decodeObject(forKey: "identifier_averages") as! [String : TenPointAverage]
    }
    
    
    func encode(with aCoder: NSCoder) -> Void{
//        print("Trying to encode averages")
//        aCoder.encode(self.averages, forKey: "identifier_averages")
        aCoder.encode(self.assets, forKey: "assets")
        aCoder.encode(self.tpaIds, forKey: "tpaIds")
        aCoder.encode(self.tpaData, forKey: "tpaData")
//        print("Averages encoded")
    }

}
