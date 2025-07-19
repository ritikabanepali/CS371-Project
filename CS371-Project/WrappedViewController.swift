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
    var tripDestination: String?
    
    @IBOutlet weak var wrappedTitle: UILabel!
    @IBOutlet weak var totalStepsLabel: UILabel!
    @IBOutlet weak var tripLeaderLabel: UILabel!
    
    private var allTravelerSteps: [String: Int] = [:]
    private var travelerNames: [String: String] = [:]
    private var currentUserID: String? { return Auth.auth().currentUser?.uid }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTitle()
        totalStepsLabel.textColor = SettingsManager.shared.titleColor
        tripLeaderLabel.textColor = SettingsManager.shared.titleColor
        
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
    }
    
    func setTitle(){
        if let destination = tripDestination {
            wrappedTitle.text = "\(destination)"
        }
        wrappedTitle.adjustsFontSizeToFitWidth = true
        wrappedTitle.minimumScaleFactor = 0.5
        wrappedTitle.textColor = SettingsManager.shared.titleColor
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
                    self.tripLeaderLabel.text = "Trip Leader: Error"
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
            self.tripLeaderLabel.text = "Trip Leader: \(leaderName) with \(maxSteps) steps"
        } else {
            self.tripLeaderLabel.text = "Trip Leader: N/A"
        }
        
    }
    
}
