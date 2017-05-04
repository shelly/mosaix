//
//  ViewController.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit
import Metal

class ChoosePhotoViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
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
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .savedPhotosAlbum
            
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if (info[UIImagePickerControllerOriginalImage]) != nil{
            pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            dismiss(animated: true, completion: { self.performSegue(withIdentifier: "ChoosePhotoToCreateMosaic", sender: self)})
        }else{
            dismiss(animated: true, completion: nil)
        }
    }
    
    //Restarts the process of picking an image 
    @IBAction func backToChoosePhoto(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChoosePhotoToCreateMosaic" {
            if let CreateMosaicViewController = segue.destination as? CreateMosaicViewController {
                CreateMosaicViewController.image = pickedImage
            }
        }
    }

}

