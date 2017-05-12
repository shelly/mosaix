//
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit
import AVFoundation

class CompositePhotoViewController: UIViewController {
    
    var mosaicCreator: MosaicCreator!
    var video: AVURLAsset!
    @IBOutlet weak var compositePhoto: UIImageView! = UIImageView()
    @IBOutlet weak var saveButton: UIBarButtonItem! = UIBarButtonItem()
    var compositePhotoImage: UIImage = UIImage()
    var canSavePhoto = false
    var results: [UIImage] = []
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("beginning mosaic")
        self.compositePhoto.contentMode = UIViewContentMode.scaleAspectFit
        self.compositePhotoImage = self.mosaicCreator.compositeImage
        self.compositePhoto.image = self.compositePhotoImage
        
        do {
            var lastRefresh : CFAbsoluteTime = 0
            if (false) {
                let benchmarker = MosaicBenchmarker(creator: self.mosaicCreator)
                benchmarker.addVariable(name: "TPA Thread Width", next: {() -> Any? in
                    self.mosaicCreator.imageSelector.tpa.threadWidth *= 2
                    if (self.mosaicCreator.imageSelector.tpa.threadWidth > 64) {
                        return nil
                    }
                    return self.mosaicCreator.imageSelector.tpa.threadWidth
                })
                benchmarker.addVariable(name: "Selection Thread Worker Pool Size", next: {() -> Any? in
                    self.mosaicCreator.imageSelector.numThreads *= 2
                    if (self.mosaicCreator.imageSelector.numThreads > 32) {
                        return nil
                    }
                    return self.mosaicCreator.imageSelector.numThreads
                })
                try benchmarker.begin(tick: {() -> Void in
    //  var           self.compositePhoto.image = self.mosaicCreator.compositeImage
                }, complete: {() -> Void in
    //                self.compositePhoto.image = self.mosaicCreator.compositeImage
                })
            } else {
                try self.mosaicCreator.begin(tick: {() -> Void in
                    //                print("tick!")
                    let newTime = CFAbsoluteTimeGetCurrent()
                    if (newTime - lastRefresh > 0.25) {
                        self.compositePhotoImage = self.mosaicCreator.compositeImage
                        self.compositePhoto.image = self.compositePhotoImage
                        lastRefresh = newTime
                    }
                }, complete: {() -> Void in
                    // This will be called when the mosaic is complete.
                    print("Mosaic complete!")
                    
                    self.compositePhotoImage = self.mosaicCreator.compositeImage
                    self.compositePhoto.image = self.compositePhotoImage
                    self.canSavePhoto = true

                    self.results.append(self.mosaicCreator.compositeImage)

                })
                
            }

        print("self.results.size", self.results.count)
        //TODO: if results array is larger than 1, create a video out of it and save it down 
            if (self.results.count > 1) {
                saveResultAsMovie()
            }
        
            
        } catch {
            print("oh shit")
        }
    }
    
    func saveResultAsMovie() {
        //convert self.results into a movie
        
        //save it to the Photo Album
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func savePhoto() {
        
        if (self.canSavePhoto) {
            UIImageWriteToSavedPhotosAlbum(self.compositePhotoImage, nil, nil, nil)
        }
        
    }
}
