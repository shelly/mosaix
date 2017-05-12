//
//  ViewController.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit
import Metal
import AVFoundation

class ChoosePhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var video: AVURLAsset!
    var pickedImage: UIImage!
    var imagePicker = UIImagePickerController()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func chooseImage() {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = ["public.image", "public.movie"]
            
            present(imagePicker, animated: true, completion: nil)
            
        }
    }
    
    
    @IBAction func takePicture() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
            
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func setMovie(movie: URL) {
        print("PATH", movie.path)
        //break down into frame by frame
        do {
            self.video = AVURLAsset(url: movie)
            let generator = AVAssetImageGenerator(asset: self.video)
            try self.pickedImage = UIImage(cgImage: generator.copyCGImage(at: CMTimeMake(0, video.duration.timescale), actualTime: nil))
        } catch {
            print("Issue with taking frame of video.")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if ((info[UIImagePickerControllerMediaType] as! String) == "public.movie") {
            //turn movie into an array of UIImages and save to self.pickedImages
            setMovie(movie: (info[UIImagePickerControllerMediaURL] as! URL))
        }
        if ((info[UIImagePickerControllerMediaType] as! String) == "public.image") {
            pickedImage = (info[UIImagePickerControllerOriginalImage] as! UIImage)
            
        }
        
        dismiss(animated: true, completion: { self.performSegue(withIdentifier: "ChoosePhotoToCreateMosaic", sender: self)})
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChoosePhotoToCreateMosaic" {
            if let CreateMosaicViewController = segue.destination as? CreateMosaicViewController {
                CreateMosaicViewController.video = self.video
                CreateMosaicViewController.image = self.pickedImage
            }
        }
    }

}

