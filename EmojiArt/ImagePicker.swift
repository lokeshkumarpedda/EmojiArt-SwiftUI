//
//  ImagePicker.swift
//  EmojiArt
//
//  Created by apple on 05/06/21.
//

import SwiftUI
import UIKit

typealias PickerImageHandler = (UIImage?) -> Void

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType : UIImagePickerController.SourceType
    var handlePickedImage: PickerImageHandler
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    typealias UIViewControllerType = UIImagePickerController
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(handlePickedImage: handlePickedImage)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate , UINavigationControllerDelegate{
        var handlePickedImage: PickerImageHandler
        
        init(handlePickedImage: @escaping PickerImageHandler) {
            self.handlePickedImage = handlePickedImage
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            handlePickedImage(nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            handlePickedImage(info[.originalImage] as? UIImage)
        }
    }
}
