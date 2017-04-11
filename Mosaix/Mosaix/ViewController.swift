//
//  ViewController.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit
import Metal

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    // The Metal device we use to perform Metal operations
    var device: MTLDevice!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var chooseButton: UIButton!
    var imagePicker = UIImagePickerController()
    
    @IBAction func chooseImage() {
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            print("Button capture")
            
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func takePicture() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("Photo capture")
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        print("OK DONE!!!")
        self.dismiss(animated: true, completion: { () -> Void in
            
        })
        
        imageView.image = image
    }


}

