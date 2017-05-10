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
    @IBOutlet weak var qualitySlider: UISlider! = UISlider()
    @IBOutlet weak var sizeSlider: UISlider! = UISlider()
    @IBOutlet weak var goButton: UIButton! = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.image = image
        goButton.isHidden = true
        // Do any additional setup after loading the view.
        mosaicCreator = MosaicCreator(reference: image, tpaParallel: true, selectionParallel: true)
        
        do {
            try mosaicCreator.preprocess(complete: {
                self.goButton.isHidden = false
            })
        } catch {
            print("Call to preprocess caused an error.")
        }
        
        qualitySlider.minimumValue = Float(MosaicCreationConstants.qualityMin)
        qualitySlider.maximumValue = Float(MosaicCreationConstants.qualityMax)
        sizeSlider.minimumValue = Float(MosaicCreationConstants.gridSizeMin)
        sizeSlider.maximumValue = Float(MosaicCreationConstants.gridSizeMax)
        
        let qualitySliderDefault = Float(MosaicCreationConstants.qualityMax - MosaicCreationConstants.qualityMin)/2
        let sizeSliderDefault = Float(MosaicCreationConstants.gridSizeMax - MosaicCreationConstants.gridSizeMin)/2
        
        qualitySlider.value = qualitySliderDefault
        sizeSlider.value = sizeSliderDefault
        
        do {
            try mosaicCreator.setQuality(quality: Int(qualitySliderDefault))
            try mosaicCreator.setGridSizePoints(Int(sizeSliderDefault))
        }
        catch {
            print("Issue with initial setting of setting quality/grid size points.\n")
        }
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
    
    @IBAction func qualityChanged(sender: UISlider){
        let value = Int(sender.value)
        do {
            try mosaicCreator.setQuality(quality: value)
        }
        catch {
            print("Error with setting quality.\n")
        }
        
        
    }

    @IBAction func sizeChanged(sender: UISlider){
        let value = Int(sender.value)
        do {
            try mosaicCreator.setGridSizePoints(value)
        }
        catch {
            print("Error with setting grid size.\n")
        }
        
    }
    
    
    @IBAction func createCompositePhoto() {
        
    }

    //Restarting createMosaic screen 
    @IBAction func backToCreateMosaic(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CreateMosaicToCompositePhoto" {
            if let CompositePhotoViewController = segue.destination as? CompositePhotoViewController {
                CompositePhotoViewController.mosaicCreator = mosaicCreator
            }
        }
    }
    
}
