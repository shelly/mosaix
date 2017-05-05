//
//  Processing.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/18/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos

enum LibraryProcessingError: Error {
    case PreprocessingInProgress
    case LibraryAccessIssue
}

protocol PhotoProcessor {
    func preprocess(complete : @escaping () -> Void) throws -> Void
    func preprocessProgress() -> Int
    
    func findNearestMatch(tpa: TenPointAverage) -> (PHAsset, Float)?
    func processPhoto(image: CGImage, complete: @escaping (TenPointAverage?) throws -> Void) -> Void
    func progress() -> Int
}
