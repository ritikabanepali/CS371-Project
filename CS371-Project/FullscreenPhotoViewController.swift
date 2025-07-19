//
//  FullscreenPhotoViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/13/25.
//

import UIKit



class FullscreenPhotoViewController: UIViewController {
    
    var images: [UIImage] = []
    var likes: [Int] = []
    var currentIndex: Int = 0
    var tripID: String?
    var pageIndicatorStack: UIStackView!
    
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
        
        loadLikes()
        styleButtons()
        updateLikeButtonState()
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if pageIndicatorStack == nil {
            createIndicator()
            updatePageIndicator()
        }
        
        positionIndicator()
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
        
        updatePageIndicator()
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
        guard let key = imageKey(for: currentIndex),
              let tripID = tripID,
              let userID = getCurrentUserID() else { return }
        
        let likedKey = "likedPhotos_\(tripID)_\(userID)"
        var liked = UserDefaults.standard.stringArray(forKey: likedKey) ?? []
        
        if liked.contains(key) {
            liked.removeAll { $0 == key }
            likes[currentIndex] = max(likes[currentIndex] - 1, 0)
        } else {
            liked.append(key)
            likes[currentIndex] += 1
        }
        
        UserDefaults.standard.set(liked, forKey: likedKey)
        UserDefaults.standard.set(likes, forKey: "likes_\(tripID)_\(userID)")
        
        updateLikeButtonState()
    }
    
    
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        // change trash icon (styling)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        let filledTrash = UIImage(systemName: "trash.circle.fill", withConfiguration: config)
        deleteButton.setImage(filledTrash, for: .normal)
        
        // short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.performDeletion()
        }
        
    }
        
        func performDeletion() {
            guard let tripID = tripID,
                  let key = imageKey(for: currentIndex) else { return }
            
            let defaults = UserDefaults.standard
            var saved = defaults.stringArray(forKey: "savedImageURLs_\(tripID)") ?? []
            saved.removeAll { $0 == key }
            defaults.set(saved, forKey: "savedImageURLs_\(tripID)")
            
            var liked = defaults.stringArray(forKey: "likedPhotos") ?? []
            liked.removeAll { $0 == key }
            defaults.set(liked, forKey: "likedPhotos")
            
            images.remove(at: currentIndex)
            
            if let navController = navigationController,
               let photoVC = navController.viewControllers.first(where: { $0 is PhotoAlbumViewController }) as? PhotoAlbumViewController {
                photoVC.needsRefresh = true
            }
            
            if images.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                currentIndex = min(currentIndex, images.count - 1)
                imageView.image = images[currentIndex]
                updateLikeButtonState()
                updatePageIndicator()
                
                // Reset trash icon to unfilled for next image
                styleButtons()
            }
        }
        
        
        
        //MARK: likes
        
        
        func updateLikeButtonState() {
            guard let key = imageKey(for: currentIndex),
                  let tripID = tripID,
                  let userID = getCurrentUserID() else { return }
            
            let liked = UserDefaults.standard.stringArray(forKey: "likedPhotos_\(tripID)_\(userID)") ?? []
            let isLiked = liked.contains(key)
            let iconName = isLiked ? "heart.circle.fill" : "heart.circle"
            
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            likeButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        }
        
        
        
        func loadLikes() {
            guard let tripID = tripID,
                  let userID = getCurrentUserID() else { return }
            
            let key = "likes_\(tripID)_\(userID)"
            let savedLikes = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
            
            // Ensure same size as images
            if savedLikes.count == images.count {
                likes = savedLikes
            } else {
                likes = Array(repeating: 0, count: images.count)
            }
        }
        
        
        //MARK: styling
        func styleButtons(){
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let largeTrash = UIImage(systemName: "trash.circle", withConfiguration: config)
            deleteButton.setImage(largeTrash, for: .normal)
            
        }
        
        func getCurrentUserID() -> String? {
            return UserManager.shared.currentUserID
        }
        
        //MARK: Indicator
        func updatePageIndicator() {
            print("Dots count: \(images.count), Current: \(currentIndex)")
            
            pageIndicatorStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            
            let maxVisible = 7
            let total = images.count
            let current = currentIndex
            
            let start: Int
            if total <= maxVisible {
                start = 0
            } else {
                let half = maxVisible / 2
                if current <= half {
                    start = 0
                } else if current >= total - half - 1 {
                    start = total - maxVisible
                } else {
                    start = current - half
                }
            }
            
            let end = min(start + maxVisible, total)
            
            for i in start..<end {
                let dot = UIView()
                dot.translatesAutoresizingMaskIntoConstraints = false
                dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
                dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
                dot.layer.cornerRadius = 4
                dot.backgroundColor = (i == currentIndex) ? .white : UIColor.white.withAlphaComponent(0.4)
                pageIndicatorStack.addArrangedSubview(dot)
            }
        }
        
        func createIndicator() {
            pageIndicatorStack = UIStackView()
            pageIndicatorStack.axis = .horizontal
            pageIndicatorStack.alignment = .center
            pageIndicatorStack.distribution = .equalSpacing
            pageIndicatorStack.spacing = 6
            pageIndicatorStack.translatesAutoresizingMaskIntoConstraints = true
            pageIndicatorStack.backgroundColor = .clear // remove debug color
            
            view.addSubview(pageIndicatorStack)
        }
        
        func positionIndicator() {
            guard let image = imageView.image else { return }
            
            // Compute actual image frame inside imageView when aspectFit is used
            let imageSize = image.size
            let viewSize = imageView.bounds.size
            
            let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let displaySize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            
            let imageOrigin = CGPoint(
                x: imageView.frame.origin.x + (viewSize.width - displaySize.width) / 2,
                y: imageView.frame.origin.y + (viewSize.height - displaySize.height) / 2
            )
            
            let imageFrame = CGRect(origin: imageOrigin, size: displaySize)
            
            // Position the indicator
            let stackWidth = CGFloat(min(images.count, 7)) * 8 + CGFloat(min(images.count, 7) - 1) * pageIndicatorStack.spacing
            pageIndicatorStack.frame = CGRect(
                x: imageFrame.midX - stackWidth / 2,
                y: imageFrame.maxY - 20,
                width: stackWidth,
                height: 10
            )
        }
        
    }
