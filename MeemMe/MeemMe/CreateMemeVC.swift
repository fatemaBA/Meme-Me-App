//
//  ViewController.swift
//  MeemMe
//
//  Created by Fato0omAH on 8/13/19.
//  Copyright © 2019 Fatema. All rights reserved.
//

import UIKit

class CreateMemeVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    //MARK: Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    //MARK: Meme struct
    struct Meme {
        var topText: String
        var bottomText: String
        var originalImage: UIImage
        var memedImage: UIImage
    }
    
    //MARK: life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //enable the camera button only if the device has a camera
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        // set the "top" and "bottom" textFields font and default values
        self.topText.text = "TOP"
        setupTextFieldStyle(self.topText)
        self.bottomText.text = "BOTTOM"
        setupTextFieldStyle(self.bottomText)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        subscribeToKeyboardNotifications()
        subscribeToKeyboardHideNotifications()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
        unsubscribeFromKeyboardHideNotifications()
    }
    
    // MARK: Actions
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        // show photo album
        openImagePicker(.photoLibrary)
        
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        // open the camera
        openImagePicker(.camera)
    }
    
    @IBAction func share(_ sender: Any) {
        //generate memed image
        let memeImage = self.generateMemedImage()
        
        //view the activity controller
        let controller = UIActivityViewController(activityItems: [memeImage], applicationActivities: nil)
        present(controller, animated: true, completion: nil)
        
        //save the memed image if no problem accured
        controller.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, arrayRetunedItems: [Any]?, error: Error?) in
            if completed {
                self.save(memedImage: memeImage)
            }else {
                print("cancel")
            }
            
        }
    }
    
    //MARK: UIImagePickerControllerDelegate functions
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        
        //show the picked image in the imageView and dismiss controller
        if let imagePicked = info[.originalImage] as? UIImage {
            self.imageView.image = imagePicked
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: UITextFieldDelegate functions
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //erase the default text when user starts editing
        if textField.text == "TOP" || textField.text == "BOTTOM"{
            textField.text = ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //hide keybord when user presses return
        textField.resignFirstResponder()
        return true;
    }
    
    //MARK: keyboard fuctions
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        //shift the view only if the textFied that is being edited is bottomText
        if self.bottomText.isEditing {
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardHideNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardHideNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        //shift the view back to its original state when the keybord is hidden
        view.frame.origin.y = 0
    }
    
    //MARK: set textField font function
    func setupTextFieldStyle(_ textField: UITextField) {
        
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth: -3
        ]
        
        textField.backgroundColor = .clear
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        textField.autocapitalizationType = .allCharacters
        textField.delegate = self
        
    }
    
    //MARK: present imagePickerController based on source type
    func openImagePicker(_ type: UIImagePickerController.SourceType){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        if type == .camera {
            imagePicker.sourceType = .camera
        }else {
            imagePicker.sourceType = .photoLibrary
        }
        present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK: generate and save memed image functions
    func generateMemedImage() -> UIImage {
        
        // Hide toolbar and navbar
        hideToolbars(true)
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show toolbar and navbar
        hideToolbars(false)
        
        return memedImage
    }
    
    func hideToolbars(_ hide: Bool) {
        self.toolbar.isHidden = hide
        self.navigationBar.isHidden = hide
    }
    
    func save(memedImage: UIImage) {
        // Create the meme
        let meme = Meme(topText: topText.text!, bottomText: bottomText.text!, originalImage: imageView.image!, memedImage: memedImage)
    }
    
}

