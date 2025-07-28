import UIKit
import PhotosUI
import Cloudinary
import FirebaseFirestore
import FirebaseAuth

let config = CLDConfiguration(cloudName: "dzemwygcg", secure: true)
let cloudinary = CLDCloudinary(configuration: config)

class PhotoAlbumViewController: UIViewController, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var photoAlbumTitle: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    @IBOutlet weak var photoCollection: UICollectionView!
    var tripID: String?
    var images: [UIImage] = []
    var needsRefresh = false
    var imageDocumentIDs: [String] = []
    var imageURLs: [String] = []
    var ownerID: String? {
        return Auth.auth().currentUser?.uid
    }
    var likes: [Int] = []
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        openCamera()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollection.dataSource = self
        photoCollection.delegate = self
        photoCollection.isScrollEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photoAlbumTitle.textColor = SettingsManager.shared.titleColor
        loadingLabel.textColor = SettingsManager.shared.titleColor
        var myButtonConfig = addPhotoButton.configuration ?? .filled()
        myButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        addPhotoButton.configuration = myButtonConfig
        
        //load images or refresh
        if images.isEmpty || needsRefresh {
            loadingView.isHidden = false
            needsRefresh = false
            loadImagesFromFirestore()
        }
    }
    
    // Action to open the system photo picker
    @IBAction func addPhotosButtonTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = false
            present(picker, animated: true)
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self.images.append(image)
                    self.photoCollection.reloadData()
                }
                self.uploadImageToCloudinary(image)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            self.images.append(image)
            self.photoCollection.reloadData()
            self.uploadImageToCloudinary(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func uploadImageToCloudinary(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let tripID = tripID else { return }
        
        let params = CLDUploadRequestParams()
        cloudinary.createUploader().upload(data: imageData, uploadPreset: "unsigned_preset", params: params, progress: nil) { result, error in
            if error != nil {
                return
            }
            if let secureUrl = result?.secureUrl {
                guard let userID = Auth.auth().currentUser?.uid else { return }
                
                let db = Firestore.firestore()
                let imageDoc = db
                    .collection("Users")
                    .document(userID)
                    .collection("trips")
                    .document(tripID)
                    .collection("images")
                    .document() // Auto-ID
                
                imageDoc.setData([
                    "url": secureUrl,
                    "timestamp": Timestamp(date: Date()),
                    "likes": 0
                ])
            }
        }
    }
    
    func loadImagesFromFirestore() {
        guard let tripID = tripID,
              let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("Users")
            .document(userID)
            .collection("trips")
            .document(tripID)
            .collection("images")
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("failed to get images: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Reset everything
                self.images = []
                self.imageDocumentIDs = []
                self.imageURLs = []
                self.likes = []
                let dispatchGroup = DispatchGroup()
                
                for doc in documents {
                    if let urlString = doc["url"] as? String,
                       let url = URL(string: urlString) {
                        
                        // Collect document ID and URL
                        self.imageDocumentIDs.append(doc.documentID)
                        self.imageURLs.append(urlString)
                        
                        let likeCount = doc["likes"] as? Int ?? 0
                        self.likes.append(likeCount)
                        
                        dispatchGroup.enter()
                        URLSession.shared.dataTask(with: url) { data, _, _ in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self.images.append(image)
                                }
                            }
                            dispatchGroup.leave()
                        }.resume()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.photoCollection.reloadData()
                    self.loadingView.isHidden = true
                }
            }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath)
        if let imageView = cell.contentView.viewWithTag(1) as? UIImageView {
            imageView.image = images[indexPath.item]
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10
        }
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.2
        cell.layer.shadowOffset = CGSize(width: 0, height: 1)
        cell.layer.shadowRadius = 4
        cell.layer.masksToBounds = false
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 8
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns + 1)
        let width = (collectionView.bounds.width - totalSpacing) / columns
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Julia", bundle: nil)
        if let fullscreenVC = storyboard.instantiateViewController(withIdentifier: "FullscreenPhotoVC") as? FullscreenPhotoViewController {
            fullscreenVC.images = images
            fullscreenVC.currentIndex = indexPath.item
            fullscreenVC.tripID = self.tripID
            fullscreenVC.imageDocumentIDs = self.imageDocumentIDs
            fullscreenVC.imageURLs = self.imageURLs
            fullscreenVC.ownerID = self.ownerID
            fullscreenVC.likes = self.likes
            
            fullscreenVC.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(fullscreenVC, animated: true)
        }
    }
}
