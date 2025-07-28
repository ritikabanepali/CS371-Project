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
    @IBOutlet weak var trailblazerLabel: UILabel!
    
    @IBOutlet weak var mostLikedPhoto: UILabel!
    @IBOutlet weak var leaderLabel: UILabel!
    @IBOutlet weak var chattboxLabel: UILabel!
    @IBOutlet weak var typeTrip: UILabel!
    
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
        trailblazerLabel.textColor = SettingsManager.shared.titleColor
        wrappedLabel.textColor = SettingsManager.shared.titleColor
        
        HealthKitManager.shared.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            if authorized {
                self.fetchTripSteps()
            } else {
                self.totalStepsLabel.text = "Total Steps: N/A (HealthKit Access Denied)"
                self.trailblazerLabel.text = "Trip Trailblazer: N/A"
                self.fetchAllTravelerSteps()
            }
        }
        loadTripImagesAndDisplay()
        displayTripLeaderName()
        updateTypeTrip()
        fetchMostActiveChatter()
        
        let imageViews = [bigImage, image1, image2, image3, image4]
        for imageView in imageViews {
            imageView?.layer.cornerRadius = 15
            imageView?.clipsToBounds = true
        }
    }
    
    func fetchMostActiveChatter() {
        guard let trip = selectedTrip else { return }
        
        let key = "messages_\(trip.id)"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            DispatchQueue.main.async {
                self.chattboxLabel.text = "No chatterers"
            }
            return
        }
        
        do {
            let messages = try JSONDecoder().decode([Message].self, from: data)
            if messages.isEmpty {
                DispatchQueue.main.async {
                    self.chattboxLabel.text = "No chatterers"
                }
                return
            }
            
            var countByUser: [String: Int] = [:]
            var nameByUser: [String: String] = [:]
            
            for msg in messages {
                countByUser[msg.senderID, default: 0] += 1
                nameByUser[msg.senderID] = msg.senderName
            }
            
            if let (topID, _) = countByUser.max(by: { $0.value < $1.value }),
               let topName = nameByUser[topID] {
                DispatchQueue.main.async {
                    self.chattboxLabel.text = "Chatterbox: \(topName)"
                }
            } else {
                DispatchQueue.main.async {
                    self.chattboxLabel.text = "No chatterers"
                }
            }
            
        } catch {
            print("Error decoding messages: \(error)")
            DispatchQueue.main.async {
                self.chattboxLabel.text = "No chatterers"
            }
        }
    }
    
    func updateTypeTrip() {
        typeTrip.textColor = SettingsManager.shared.titleColor
        typeTrip.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        let adjectives = ["relaxing", "adventurous", "memorable", "vibrant", "serene", "fun-filled", "spontaneous", "energizing", "unforgettable", "crazy", "sleep-deprived", "vibe-heavy", "sunburnt", "trail-misguided", "souvenir hoarding", "lost-but-vibing", "inside-joke-filled", "best-best-best", "feral"]
        let adjective = adjectives.randomElement() ?? "amazing"
        
        // check if it starts with a vowel (a, e, i, o, u)
        let firstChar = adjective.lowercased().first
        let article = (firstChar == "a" || firstChar == "e" || firstChar == "i" || firstChar == "o" || firstChar == "u") ? "An" : "A"
        
        typeTrip.text = "\(article) \(adjective) trip"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // highlight "Most Liked Photo" Label
        mostLikedPhoto.text = "   Most Liked Photo   "
        mostLikedPhoto.backgroundColor = .white
        mostLikedPhoto.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        mostLikedPhoto.layer.cornerRadius = mostLikedPhoto.frame.height / 2
        mostLikedPhoto.layer.masksToBounds = true
        mostLikedPhoto.backgroundColor = UIColor.white.withAlphaComponent(0.45)
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
            
            durationLabel.text = "\(totalDays) day\(totalDays == 1 ? "" : "s")"
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
    
    func getLikeCount(for imageKey: String) -> Int {
        guard let tripID = selectedTrip?.id else { return 0 }
        
        // Look through all users’ like data if needed. For now, we’ll just use the current user:
        guard let userID = UserManager.shared.currentUserID else { return 0 }
        
        let key = "likes_\(tripID)_\(userID)"
        let likeCounts = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        
        let imageURLs = UserDefaults.standard.stringArray(forKey: "savedImageURLs_\(tripID)") ?? []
        
        if let index = imageURLs.firstIndex(of: imageKey), index < likeCounts.count {
            return likeCounts[index]
        } else {
            return 0
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
                    self.trailblazerLabel.text = "Trip Trailblazer: Error"
                }
            }
        }
    }
    
    func displayTripLeaderName() {
        guard let trip = selectedTrip else { return } // your trip variable
        
        UserManager.shared.fetchName(forUserWithUID: trip.ownerUID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let name):
                    self?.leaderLabel.text = "Leader: \(name)"
                case .failure(_):
                    self?.leaderLabel.text = "Leader: Unknown"
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
            self.trailblazerLabel.text = "Trailblazer: \(leaderName) with \(maxSteps) steps"
        } else {
            self.trailblazerLabel.text = "No trailblazers :("
        }
        
    }
    
    //MARK: photos added
    
    func loadTripImagesAndDisplay() {
        guard let trip = selectedTrip else { return }
        let key = "savedImageURLs_\(trip.id)"
        let urls = UserDefaults.standard.stringArray(forKey: key) ?? []
        
        if urls.isEmpty {
            useDefaultImages()
            return
        }
        
        var loadedImages: [UIImage] = []
        var likedCounts: [Int] = []
        
        let dispatchGroup = DispatchGroup()
        let syncQueue = DispatchQueue(label: "imageLikeSyncQueue")
        
        for urlString in urls {
            guard let url = URL(string: urlString) else {
                print("invalid URL: \(urlString)")
                continue
            }
            
            dispatchGroup.enter()
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    syncQueue.sync {
                        loadedImages.append(image)
                        let likeCount = self.getLikeCount(for: urlString)
                        likedCounts.append(likeCount)
                    }
                }
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            let sorted = zip(loadedImages, likedCounts).sorted { $0.1 > $1.1 }
            
            // show something in bigImagefirst
            if let mostLiked = sorted.first?.0 {
                self.bigImage.image = mostLiked
            } else {
                self.bigImage.image = UIImage(named: "lavender-airplane")
            }
            
            //4 other small images
            let smallImages = [self.image1, self.image2, self.image3, self.image4]
            let fallbackNames = ["blue-door", "pink-van", "green-plant", "fallen-bike"]
            let secondaryImages = Array(sorted.dropFirst().map { $0.0 })
            
            for (i, imgView) in smallImages.enumerated() {
                if i < secondaryImages.count {
                    imgView?.image = secondaryImages[i]
                } else {
                    imgView?.image = UIImage(named: fallbackNames[i])
                }
            }
            self.view.setNeedsLayout()
        }
        
    }
    
    func useDefaultImages() {
        bigImage.image = UIImage(named: "lavender-airplane")
        image1.image = UIImage(named: "blue-door")
        image2.image = UIImage(named: "pink-van")
        image3.image = UIImage(named: "green-plant")
        image4.image = UIImage(named: "fallen-bike")
    }
}
