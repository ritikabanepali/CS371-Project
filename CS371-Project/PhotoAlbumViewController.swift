import UIKit
import PhotosUI
import Cloudinary

let config = CLDConfiguration(cloudName: "dzemwygcg", secure: true)
let cloudinary = CLDCloudinary(configuration: config)

class PhotoAlbumViewController: UIViewController, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var photoAlbumTitle: UILabel!
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var photoCollection: UICollectionView!
    var tripID: String?
    var images: [UIImage] = []
    var needsRefresh = false
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        openCamera()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollection.dataSource = self
        photoCollection.delegate = self
        photoCollection.isScrollEnabled = true
        
        if let tripID = tripID {
            print("Trip ID:", tripID)
        } else {
            print("Error: tripID is nil")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photoAlbumTitle.textColor = SettingsManager.shared.titleColor
        var myButtonConfig = addPhotoButton.configuration ?? .filled()
        myButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        addPhotoButton.configuration = myButtonConfig
        
        if images.isEmpty || needsRefresh {
            loadingView.isHidden = false
            needsRefresh = false
            
            DispatchQueue.global(qos: .userInitiated).async {
                guard let tripID = self.tripID else { return }
                let key = "savedImageURLs_\(tripID)"
                let urls = UserDefaults.standard.stringArray(forKey: key) ?? []
                
                var loadedImages: [UIImage] = []
                
                for urlString in urls {
                    if let url = URL(string: urlString),
                       let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        loadedImages.append(image)
                    }
                }
                
                DispatchQueue.main.async {
                    self.images = loadedImages
                    self.photoCollection.reloadData()
                    self.loadingView.isHidden = true
                }
            }
        }
    }
    
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
        } else {
            print("Camera not available")
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
            if let error = error {
                print("Upload error:", error.localizedDescription)
                return
            }
            if let secureUrl = result?.secureUrl {
                print("Uploaded image URL:", secureUrl)
                let key = "savedImageURLs_\(tripID)"
                var savedURLs = UserDefaults.standard.stringArray(forKey: key) ?? []
                savedURLs.append(secureUrl)
                UserDefaults.standard.set(savedURLs, forKey: key)
            }
        }
    }
    
    func loadSavedImageURLs() {
        guard let tripID = tripID else { return }
        
        let key = "savedImageURLs_\(tripID)"
        let urls = UserDefaults.standard.stringArray(forKey: key) ?? []
        
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            // Asynchronous image download
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.images.append(image)
                        self.photoCollection.reloadData()
                    }
                }
            }.resume()
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
            fullscreenVC.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(fullscreenVC, animated: true)
        }
    }
}
