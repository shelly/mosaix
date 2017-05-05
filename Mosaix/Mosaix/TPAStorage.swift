//
//  TPAStorage.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/5/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos


protocol TPAStorage {
    init()
    func insert(asset : PHAsset, tpa: TenPointAverage) -> Void
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: PHAsset, diff: Float)?
    func isMember(_ asset: PHAsset) -> Bool
    func toString() -> String
    static func fromString(storageString : String) -> TPAStorage?
}
