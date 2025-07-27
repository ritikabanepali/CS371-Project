//
//  WrappedViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/14/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import HealthKit

class WrappedViewController: UIViewController {
    var selectedTrip: Trip?
    @IBOutlet weak var tripTitle: UILabel!
    @IBOutlet weak var datesLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var wrappedLabel: UILabel!
    var tripDestination: String?
    
    @IBOutlet weak var wrappedTitle: UILabel!
    @IBOutlet weak var totalStepsLabel: UILabel!
    @IBOutlet weak var tripLeaderLabel: UILabel!
    
    @IBOutlet weak var bigImage: UIImageView!
    
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    
    private var allTravelerSteps: [String: Int] = [:]
    private var travelerNames: [String: String] = [:]
    private var currentUserID: String? { return Auth.auth().currentUser?.uid }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCardTitle()
        setTitle()
        totalStepsLabel.textColor = SettingsManager.shared.titleColor
        tripLeaderLabel.textColor = SettingsManager.shared.titleColor
        wrappedLabel.textColor = SettingsManager.shared.titleColor

        HealthKitManager.shared.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            if authorized {
                self.fetchTripSteps()
            } else {
                self.totalStepsLabel.text = "Total Steps: N/A (HealthKit Access Denied)"
                self.tripLeaderLabel.text = "Trip Leader: N/A"
                self.fetchAllTravelerSteps()
            }
        }
        loadTripImagesAndDisplay()
        
        let imageViews = [bigImage, image1, image2, image3, image4]
        for imageView in imageViews {
            imageView?.layer.cornerRadius = 15
            imageView?.clipsToBounds = true
        }


    }
    
    func setTitle(){
        if let destination = tripDestination {
            wrappedTitle.text = "\(destination)"
        }
        wrappedTitle.adjustsFontSizeToFitWidth = true
        wrappedTitle.minimumScaleFactor = 0.5
        wrappedTitle.textColor = SettingsManager.shared.titleColor
    }
    
    func setCardTitle(){
        if let destination = tripDestination {
               tripTitle.text = "\(destination)"
           }
        if let destination = tripDestination,
           let start = selectedTrip?.startDate,
           let end = selectedTrip?.endDate {

            let formatter = DateFormatter()
            formatter.dateStyle = .medium

            let startStr = formatter.string(from: start)
            let endStr = formatter.string(from: end)

            datesLabel.text = " (\(startStr) - \(endStr))"
            
            let calendar = Calendar.current
                   let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
                   let totalDays = days + 1
                   
                   durationLabel.text = "\(totalDays) day\(totalDays == 1 ? "Day" : "Days")"
        }
        tripTitle.textColor = SettingsManager.shared.titleColor
        tripTitle.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        tripTitle.textAlignment = .center
    }
    
    func fetchTripSteps() {
        let startDate = selectedTrip?.startDate ?? Date()
        let endDate = selectedTrip?.endDate ?? Date()
        
        HealthKitManager.shared.getStepCount(forDateRange: startDate, endDate: endDate) { [weak self] stepsInt in
            guard let self = self else { return }
            
            self.saveMyTravelerSteps(trip: selectedTrip!, steps: stepsInt) { [weak self] (saveError: Error?) in
                guard let self = self else { return }
                if let saveError = saveError {
                    print("WrappedViewController: Error saving my steps to Firestore: \(saveError.localizedDescription)")
                } else {
                    print("WrappedViewController: My steps saved to Firestore.")
                }
                self.fetchAllTravelerSteps()
            }
        }
    }
    
    func saveMyTravelerSteps(trip: Trip, steps: Int, completion: @escaping (Error?) -> Void){
        guard let currentUserID = currentUserID else {
            completion(NSError(domain: "WrappedVC", code: 401, userInfo: [NSLocalizedDescriptionKey: "Current user not authenticated."]))
            return
        }
        UserManager.shared.fetchName(forUserWithUID: currentUserID) { (result: Result<String, Error>) in
            let userName: String
            switch result {
            case .success(let name):
                userName = name
            case .failure(let error):
                print("WrappedViewController: Error fetching current user's name: \(error.localizedDescription)")
                userName = currentUserID
            }
            let db = Firestore.firestore()
            let travelerStepDocRef = db.collection("Users").document(trip.ownerUID).collection("trips").document(trip.id).collection("travelerSteps").document(currentUserID)
            let data: [String: Any] = [
                "totalSteps": steps,
                "lastUpdated": Timestamp(date: Date()),
                "travelerName": userName
            ]
            travelerStepDocRef.setData(data) { error in
                completion(error)
            }
        }
    }
    
    func fetchAllTravelerSteps(){
        let trip = selectedTrip!
        TripManager.shared.fetchTravelerSteps(forTrip: trip) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let (stepsByUID, namesByUID)):
                    self.allTravelerSteps = stepsByUID
                    self.travelerNames = namesByUID
                    self.updateStepLabels()
                case .failure(let error):
                    print("WrappedViewController: Error fetching all traveler steps: \(error.localizedDescription)")
                    self.totalStepsLabel.text = "Total Steps: Error"
                    self.tripLeaderLabel.text = "Trip Trailblazer: Error"
                }
            }
        }
    }
    
    func updateStepLabels (){
        var totalSteps = 0
        for steps in allTravelerSteps.values {
            totalSteps += steps
        }
        self.totalStepsLabel.text = "\(totalSteps) Total Steps"
        
        var stepLeaderUID: String?
        var maxSteps: Int = 0
        
        for (uid, steps) in allTravelerSteps {
            if steps > maxSteps {
                maxSteps = steps
                stepLeaderUID = uid
            }
        }
        
        if let leaderUID = stepLeaderUID, let leaderName = travelerNames[leaderUID] {
            self.tripLeaderLabel.text = "Trailblazer: \(leaderName) with \(maxSteps) steps"
        } else {
            self.tripLeaderLabel.text = "No trailblazers :("
        }
        
    }
    
    //MARK: photos added
    
    func loadTripImagesAndDisplay() {
        guard let trip = selectedTrip else { return }
        let key = "savedImageURLs_\(trip.id)"
        let urls = UserDefaults.standard.stringArray(forKey: key) ?? []

        var loadedImages: [UIImage] = []
        var likedCounts: [Int] = []

        if urls.isEmpty { //defaults
            bigImage.image = UIImage(named: "lavender-airplane")
            image1.image = UIImage(named: "blue-door")
            image2.image = UIImage(named: "pink-van")
            image3.image = UIImage(named: "green-plant")
            image4.image = UIImage(named: "fallen-bike")

            return
        }

        // Load images and likes
        for urlString in urls {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: urlString)),
               let image = UIImage(data: data) {
                loadedImages.append(image)

                // Look up like count
                let likeCount = getLikeCount(for: urlString)
                likedCounts.append(likeCount)
            }
        }
        
        if let image = UIImage(named: "lavender-airplane") {
            bigImage.image = image
        } else {
            print("⚠️ Image not found")
        }


        if loadedImages.isEmpty {
            bigImage.image = UIImage(named: "lavender-airplane")
            image1.image = UIImage(named: "blue-door")
            image2.image = UIImage(named: "pink-van")
            image3.image = UIImage(named: "green-plant")
            image4.image = UIImage(named: "fallen-bike")
            return
        }

        // Find most liked image
        let sorted = zip(loadedImages, likedCounts).sorted { $0.1 > $1.1 }
        bigImage.image = sorted.first?.0

        let otherImages = Array(sorted.dropFirst().prefix(4).map { $0.0 })
        let smallImages = [image1, image2, image3, image4]

        for (i, imgView) in smallImages.enumerated() {
            imgView?.image = i < otherImages.count ? otherImages[i] : UIImage(named: "default\(i+2)")
        }
    }
    
    func getLikeCount(for key: String) -> Int {
        guard let tripID = selectedTrip?.id,
              let userID = currentUserID else { return 0 }
        
        let likesKey = "likes_\(tripID)_\(userID)"
        let likedArray = UserDefaults.standard.array(forKey: likesKey) as? [Int] ?? []
        
        // Get index of photo in savedImageURLs
        let photoURLs = UserDefaults.standard.stringArray(forKey: "savedImageURLs_\(tripID)") ?? []
        if let index = photoURLs.firstIndex(of: key), index < likedArray.count {
            return likedArray[index]
        }
        return 0
    }



}
