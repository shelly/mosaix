//
//  ImageSelection.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit

struct ImageChoice {
    var position    : (row: Int, col: Int)
    var image       : UIImage
    var region      : Region
    var fit         : CGFloat // Represents how good the fit is. Zero is best.
}

enum ImageSelectionError: Error {
    case PreprocessingIncomplete
    case LibraryAccessDenied
    case LibraryAccessNotDetermined
}

protocol ImageSelection {
    init(refImage : UIImage)
    func select(gridSizePoints : Int, quality: Int, onSelect : @escaping (ImageChoice) -> Void) throws -> Void
}
