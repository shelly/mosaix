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
    func insert(asset : String, tpa: TenPointAverage) -> Void
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: String, diff: Float)?
    func isMember(_ asset: String) -> Bool
    func toString() -> String
    static func fromString(storageString : String) -> TPAStorage?
}
