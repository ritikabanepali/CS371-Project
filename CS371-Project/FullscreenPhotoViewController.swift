//
//  FullscreenPhotoViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/13/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class FullscreenPhotoViewController: UIViewController {
    
    var images: [UIImage] = []
    var likes: [Int] = []
    var currentIndex: Int = 0
    var tripID: String?
    var pageIndicatorStack: UIStackView!
    var imageDocumentIDs: [String] = []
    var imageURLs: [String] = []
    var ownerID: String?
    var didStyleButtons = false

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var likeCountLabel: UILabel!
    
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
        if gesture.direction == .left, currentIndex < images.count - 1 {
            currentIndex += 1
        } else if gesture.direction == .right, currentIndex > 0 {
            currentIndex -= 1
        }
        imageView.image = images[currentIndex]
        updatePageIndicator()
        updateLikeButtonState()
    }
    
    // image likes & delete
    func imageKey(for index: Int) -> String? {
        guard let tripID = tripID else { return nil }
        let key = "savedImageURLs_\(tripID)"
        let urls = UserDefaults.standard.stringArray(forKey: key) ?? []
        return index < urls.count ? urls[index] : nil
    }
    
    @IBAction func likeButtonTapped(_ sender: UIButton) {
        likeButton.tintColor = .systemPink

        guard let tripID = tripID,
              let ownerID = ownerID,
              currentIndex < imageDocumentIDs.count else { return }

        let docID = imageDocumentIDs[currentIndex]
        let imageRef = Firestore.firestore()
            .collection("Users")
            .document(ownerID)
            .collection("trips")
            .document(tripID)
            .collection("images")
            .document(docID)

        imageRef.getDocument { snapshot, error in
            guard let doc = snapshot, doc.exists, let data = doc.data(),
                  let currentLikes = data["likes"] as? Int else { return }

            let likedKey = "likedPhotos_\(tripID)_\(self.getCurrentUserID() ?? "")"
            var liked = UserDefaults.standard.stringArray(forKey: likedKey) ?? []
            
            let docID = self.imageDocumentIDs[self.currentIndex]
            let isLiked = liked.contains(docID)

            
            let newLikes = isLiked ? max(currentLikes - 1, 0) : currentLikes + 1

            imageRef.updateData(["likes": newLikes])

            if isLiked {
                liked.removeAll { $0 == docID }
            } else {
                liked.append(docID)
            }
            UserDefaults.standard.set(liked, forKey: likedKey)


            self.likes[self.currentIndex] = newLikes
            self.updateLikeButtonState()
            
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        // change trash icon (styling)
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        let filledTrash = UIImage(systemName: "trash.circle.fill", withConfiguration: config)
        deleteButton.setImage(filledTrash, for: .normal)
        
        // short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performDeletion()
        }
        
    }
    
    func performDeletion() {
        guard let tripID = tripID,
              let ownerID = ownerID,
              currentIndex < imageDocumentIDs.count else { return }

        let docID = imageDocumentIDs[currentIndex]
        let imageRef = Firestore.firestore()
            .collection("Users")
            .document(ownerID)
            .collection("trips")
            .document(tripID)
            .collection("images")
            .document(docID)

        imageRef.delete { error in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
                return
            }

            self.images.remove(at: self.currentIndex)
            self.imageDocumentIDs.remove(at: self.currentIndex)
            self.imageURLs.remove(at: self.currentIndex)
            self.likes.remove(at: self.currentIndex)

            if self.images.isEmpty {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.currentIndex = min(self.currentIndex, self.images.count - 1)
                self.imageView.image = self.images[self.currentIndex]
                self.updateLikeButtonState()
                self.updatePageIndicator()
                self.styleButtons()
            }

            if let navController = self.navigationController,
               let photoVC = navController.viewControllers.first(where: { $0 is PhotoAlbumViewController }) as? PhotoAlbumViewController {
                photoVC.needsRefresh = true
            }
        }
    }

    // likes
    func updateLikeButtonState() {
        guard let tripID = tripID,
              let userID = getCurrentUserID(),
              currentIndex < imageURLs.count else { return }

        let docID = imageDocumentIDs[currentIndex]
        let liked = UserDefaults.standard.stringArray(forKey: "likedPhotos_\(tripID)_\(userID)") ?? []
        let isLiked = liked.contains(docID)

        let iconName = isLiked ? "heart.circle.fill" : "heart.circle"

        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        likeButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)

        let count = likes.indices.contains(currentIndex) ? likes[currentIndex] : 0
        likeCountLabel.text = "\(count)"
        likeCountLabel.isHidden = count == 0
    }
    
    func loadLikes() {
        guard let tripID = tripID, let ownerID = ownerID else { return }

        likes = Array(repeating: 0, count: imageDocumentIDs.count)
        let db = Firestore.firestore()

        for (index, docID) in imageDocumentIDs.enumerated() {
            let ref = db.collection("Users").document(ownerID)
                .collection("trips").document(tripID)
                .collection("images").document(docID)

            ref.getDocument { snapshot, error in
                if let data = snapshot?.data(), let count = data["likes"] as? Int {
                    self.likes[index] = count

                    if index == self.currentIndex {
                        DispatchQueue.main.async {
                            self.updateLikeButtonState()
                        }
                    }
                }

            }
        }
    }
    
    // styling
    func styleButtons(){
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)

        // Trash icon
        let largeTrash = UIImage(systemName: "trash.circle", withConfiguration: config)
        deleteButton.setImage(largeTrash, for: .normal)
        
        // Like icon (default state)
        let heart = UIImage(systemName: "heart.circle", withConfiguration: config)
        likeButton.setImage(heart, for: .normal)
    }

    
    func getCurrentUserID() -> String? {
        return UserManager.shared.currentUserID
    }
    
    // Indicator
    func updatePageIndicator() {
        
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
