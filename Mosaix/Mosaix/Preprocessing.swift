//
//  Preprocessing.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/18/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation

enum LibraryPreprocessingError: Error {
    case PreprocessingInProgress
    case LibraryAccessIssue
}

protocol LibraryPreprocessing {
    
    func begin(complete : @escaping () -> Void) throws -> Void
    func progress() -> Int
}
