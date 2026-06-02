//
//  ViewController.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/1/27.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        let button1 = UIButton(frame: CGRect(x: view.bounds.width/2-50, y: view.bounds.height/2-100, width: 100, height: 50))
        view.addSubview(button1)
        button1.setTitle("相机美颜", for: .normal)
        button1.setTitleColor(.black, for: .normal)
        button1.addTarget(self, action: #selector(buttonAction1), for: .touchUpInside)
        
        let button2 = UIButton(frame: CGRect(x: view.bounds.width/2-50, y: view.bounds.height/2-50, width: 100, height: 50))
        view.addSubview(button2)
        button2.setTitle("图片美颜", for: .normal)
        button2.setTitleColor(.black, for: .normal)
        button2.addTarget(self, action: #selector(buttonAction2), for: .touchUpInside)
    }
    
    //MARK: Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image: UIImage!
        image = info[.originalImage]  as? UIImage
        
        picker.dismiss(animated: true) {[self] in
            if image != nil {
                let controller = BeautyImageController()
                controller.image = image
                controller.modalPresentationStyle = .fullScreen
                present(controller, animated: true)
            }
        }
    }
    
    //MARK: Action
    @objc func buttonAction1() {
        let controller = BeautyFilterController()
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    
    @objc func buttonAction2() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .fullScreen
        present(imagePicker, animated: true)
    }

}

