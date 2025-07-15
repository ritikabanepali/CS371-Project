import UIKit
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

class PhotoAlbumViewController: UIViewController, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var photoCollection: UICollectionView!

    var images: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        photoCollection.dataSource = self
        photoCollection.delegate = self
        photoCollection.isScrollEnabled = true

    }

    // MARK: - Add Photo Button

    @IBAction func addPhotosButtonTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - PHPicker Delegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self.images.append(image)
                    self.photoCollection.reloadData()
                }
            }
        }
    }

    // MARK: - UICollectionView Data Source

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

    // MARK: - UICollectionView Layout: 2-column square grid with spacing

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 8
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns + 1)
        let width = (collectionView.bounds.width - totalSpacing) / columns
        return CGSize(width: width, height: width) // square cell
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
            fullscreenVC.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(fullscreenVC, animated: true)
        }
    }

}
