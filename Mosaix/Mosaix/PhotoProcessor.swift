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
    init(timer: MosaicCreationTimer, parallel: Bool)
    var threadWidth: Int { get set }
    func preprocess(complete : @escaping () -> Void) throws -> Void
    func preprocessProgress() -> Int
    
    func findNearestMatch(tpa: TenPointAverage) -> (String, Float)?
    func processPhoto(image: CGImage, synchronous: Bool, complete: @escaping (TenPointAverage?) throws -> Void) -> Void
    func progress() -> Int
}
