//
//  FullscreenPhotoViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/13/25.
//

import UIKit

class FullscreenPhotoViewController: UIViewController {

    var images: [UIImage] = []
    var currentIndex: Int = 0
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = images[currentIndex]
        imageView.contentMode = .scaleAspectFit
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }

    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            if currentIndex < images.count - 1 {
                currentIndex += 1
                imageView.image = images[currentIndex]
            }
        } else if gesture.direction == .right {
            if currentIndex > 0 {
                currentIndex -= 1
                imageView.image = images[currentIndex]
            }
        }
    }

}
