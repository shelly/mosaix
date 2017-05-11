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
    var pickedImages: [UIImage] = []
    var imagePicker = UIImagePickerController()
    
    
    
    override func viewDidLoad() {
        pickedImages = []
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
    
    func setPickedImagesToMovie(movie: URL) {
        //break down into frame by frame
        
//        let video = AVURLAsset(url: movie)
//        let length = video.duration
//        let imgGenerator = AVAssetImageGenerator(asset: video)
        
        //save to self.pickedImages
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if ((info[UIImagePickerControllerMediaType] as! String) == "public.movie") {
            //turn movie into an array of UIImages and save to self.pickedImages
            setPickedImagesToMovie(movie: (info[UIImagePickerControllerMediaURL] as! URL))
        }
        if ((info[UIImagePickerControllerMediaType] as! String) == "public.image") {
            pickedImages.append((info[UIImagePickerControllerOriginalImage] as! UIImage))
            dismiss(animated: true, completion: { self.performSegue(withIdentifier: "ChoosePhotoToCreateMosaic", sender: self)})
        }else{
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChoosePhotoToCreateMosaic" {
            if let CreateMosaicViewController = segue.destination as? CreateMosaicViewController {
                CreateMosaicViewController.imagesArray = pickedImages
            }
        }
    }

}

