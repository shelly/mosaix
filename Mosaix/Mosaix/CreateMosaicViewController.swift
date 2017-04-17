//
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit


class CreateMosaicViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    var mosaicCreator: MosaicCreator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        // Do any additional setup after loading the view.
        mosaicCreator = MosaicCreator(reference: image)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Transitions to other screens
    
    //Forget/save any settings
    @IBAction func cancelCreateMosaicView() {
        
    }
    
    //Save any settings
    @IBAction func goToOptions() {
        
    }
    
    //Launch composite photo creation
    @IBAction func createCompositePhoto() {
        print("Creating composite photo!!")
        do {
            try mosaicCreator.begin()
        }
        catch {
            print("We broke it!!")
        }
    }

    //Restarting createMosaic screen 
    @IBAction func backToCreateMosaic(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    
}
