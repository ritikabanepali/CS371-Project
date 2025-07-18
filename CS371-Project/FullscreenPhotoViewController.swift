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
    var likedImages: Set<String> = []
    var tripID: String?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!


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
        
        styleButtons()
        
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
        updateLikeButtonState()
    }
    
    //MARK: image likes & delete
    func imageKey(for index: Int) -> String? {
        guard let tripID = tripID else { return nil }
        let key = "savedImageURLs_\(tripID)"
        let urls = UserDefaults.standard.stringArray(forKey: key) ?? []
        return index < urls.count ? urls[index] : nil
    }
    
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        guard let key = imageKey(for: currentIndex) else { return }
        var liked = UserDefaults.standard.stringArray(forKey: "likedPhotos") ?? []

        if liked.contains(key) {
            liked.removeAll { $0 == key }
            likeButton.setImage(UIImage(systemName: "heart.circle"), for: .normal)
        } else {
            liked.append(key)
            likeButton.setImage(UIImage(systemName: "heart.circle.fill"), for: .normal)
        }

        UserDefaults.standard.set(liked, forKey: "likedPhotos")
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        guard let tripID = tripID,
              let key = imageKey(for: currentIndex) else { return }

        // Remove image URL from saved list
        let defaults = UserDefaults.standard
        var saved = defaults.stringArray(forKey: "savedImageURLs_\(tripID)") ?? []
        saved.removeAll { $0 == key }
        defaults.set(saved, forKey: "savedImageURLs_\(tripID)")

        // Also remove from liked list
        var liked = defaults.stringArray(forKey: "likedPhotos") ?? []
        liked.removeAll { $0 == key }
        defaults.set(liked, forKey: "likedPhotos")

        // Remove from local images
        images.remove(at: currentIndex)

        // Tell PhotoAlbumViewController to refresh on return
        if let navController = navigationController,
           let photoVC = navController.viewControllers.first(where: { $0 is PhotoAlbumViewController }) as? PhotoAlbumViewController {
            photoVC.needsRefresh = true
        }

        // Navigate back or update displayed image
        if images.isEmpty {
            navigationController?.popViewController(animated: true)
        } else {
            currentIndex = min(currentIndex, images.count - 1)
            imageView.image = images[currentIndex]
            updateLikeButtonState()
        }
    }

    
    func updateLikeButtonState() {
        guard let key = imageKey(for: currentIndex) else { return }
        let liked = UserDefaults.standard.stringArray(forKey: "likedPhotos") ?? []
        let isLiked = liked.contains(key)
        let iconName = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
    
    //MARK: styling
    func styleButtons(){
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        let largeTrash = UIImage(systemName: "trash.circle", withConfiguration: config)
        deleteButton.setImage(largeTrash, for: .normal)
        
    }





}
