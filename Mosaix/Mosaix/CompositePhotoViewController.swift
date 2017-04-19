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
        
        DispatchQueue.global().async{
            do {
                try self.mosaicCreator.begin()
                self.compositePhoto.image = self.mosaicCreator.compositeImage
            }
            catch {
                print("Error with dispatching mosaicCreator.begin.")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
