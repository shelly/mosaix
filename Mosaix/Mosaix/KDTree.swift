//
//  KDTree.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/5/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos


class KDTree : TPAStorage {

    public var pListPath = "kdtree.plist"
    
    required override init() {
        
    }
    
    func insert(asset: PHAsset, tpa: TenPointAverage) {
        
    }
    
    func isMember(_ asset: PHAsset) -> Bool {
        return false
    }
    
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: PHAsset, diff: Float)? {
        return nil
    }
    
    //NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        
    }
    
    func encode(with aCoder: NSCoder) -> Void{
        
    }
}
