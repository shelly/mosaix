//
//  TPAStorage.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/5/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos


protocol TPAStorage : NSCoding {
    
    var pListPath : String {get set}
    var tpaIds: [String] {get set}
    var tpaData : [UInt32] {get set}
    
    init()
    func insert(asset : String, tpa: TenPointAverage) -> Void
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: String, diff: Float)?
    func isMember(_ asset: String) -> Bool

}
