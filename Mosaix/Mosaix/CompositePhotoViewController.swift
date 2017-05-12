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
                var drawingThreads : Int = 1
                benchmarker.addVariable(name: "Drawing Threads", next: {() -> Any? in
                    if (drawingThreads > 16) {
                        return nil
                    }
                    self.mosaicCreator.drawingThreads = drawingThreads
                    drawingThreads *= 2
                    return drawingThreads / 2
                })
                try benchmarker.begin(tick: {() -> Void in
                    return
                }, complete: {() -> Void in
                    return
                })
            } else {
                
                if (self.video != nil) {
                    makeMovie()
                    
                }
                else {
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

                    })
                }
            }
        
            
        } catch {
            print("oh no")
        }
    }
    
    func makeMosaic(generator: AVAssetImageGenerator, i : Int64) {
        do {
            print("i: \(i)")
            var actual = CMTime()
            let frameTime = CMTimeMake(i, self.video.duration.timescale)
            let image = try UIImage(cgImage: generator.copyCGImage(at: frameTime, actualTime: &actual))
            self.mosaicCreator.updateReference(new: image)
            try self.mosaicCreator.begin(tick: {
            }, complete: {() -> Void in
                self.compositePhotoImage = self.mosaicCreator.compositeImage
                self.compositePhoto.image = self.compositePhotoImage
                self.canSavePhoto = true
                self.savePhoto()
                self.makeMosaic(generator: generator, i: i + 3000)
            })
        } catch {
            print (error)
        }
    }
    
    func makeMovie() { //Make a movie out of self.video
        do {
            let generator = AVAssetImageGenerator(asset: self.video)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = kCMTimeZero
            generator.requestedTimeToleranceAfter = kCMTimeZero
            try makeMosaic(generator: generator, i: 1752000)
        } catch {
            print("Issue with taking frame of video.")
        }

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
