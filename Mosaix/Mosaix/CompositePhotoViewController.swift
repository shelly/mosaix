//
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit

class CompositePhotoViewController: UIViewController {
    
    var mosaicCreator: MosaicCreator!
    @IBOutlet weak var compositePhoto: UIImageView! = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("beginning mosaic")
        self.compositePhoto.contentMode = UIViewContentMode.scaleAspectFit
        self.compositePhoto.image = self.mosaicCreator.compositeImage
        
        do {
            try self.mosaicCreator.begin(tick: {() -> Void in
//                print("tick!")
                self.compositePhoto.image = self.mosaicCreator.compositeImage
            }, complete: {() -> Void in
                // This will be called when the mosaic is complete.
                print("Mosaic complete!")
                self.compositePhoto.image = self.mosaicCreator.compositeImage
            })
        } catch {
            print("oh shit")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
