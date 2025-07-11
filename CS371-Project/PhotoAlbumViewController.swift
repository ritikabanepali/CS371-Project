//
//  PhotoAlbumViewController.swift
//  CS371-Project
//
//  Created by Julia on 7/9/25.
//

import UIKit
import PhotosUI

class PhotoAlbumViewController: UIViewController, PHPickerViewControllerDelegate {

    // Connect this to your UIImageView in storyboard
    // Connect this to your "Add Photo" button in storyboard (IBAction)
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func addPhotosButtonTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Any setup if needed
    }

    // Delegate method
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
    }
}
