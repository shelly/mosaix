//
//  NaiveImageSelection.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import UIKit

class MetalImageSelection: ImageSelection {
    private var referenceImage : UIImage
    
    required init(refImage: UIImage) {
        self.referenceImage = refImage
    }
    
    func select(gridSizePoints : Int, onSelect : @escaping (ImageChoice) -> Void) throws -> Void {
        return
    }
}
