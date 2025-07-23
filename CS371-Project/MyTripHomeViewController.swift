
//  MyTripHomeViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit
import HealthKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

class MyTripHomeViewController: UIViewController {
    
    var trip: Trip?
    
    @IBOutlet var travelersButton: UIButton!
    @IBOutlet var photoButton: UIButton!
    @IBOutlet var genButton: UIButton!
    @IBOutlet var surveyButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet var chatButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyShadow(to: travelersButton)
        applyShadow(to: photoButton)
        applyShadow(to: genButton)
        applyShadow(to: surveyButton)
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
           let largeChatImage = UIImage(systemName: "message.circle", withConfiguration: config)
           chatButton.setImage(largeChatImage, for: .normal)

        
        if let destination = trip?.destination {
            titleLabel.text = "\(destination)"
        } else {
            titleLabel.text = "My Trip"
        }
        
        HealthKitManager.shared.requestAuthorization { [weak self] authorized in
            guard self != nil else { return }
            if authorized {
                print("HealthKit: Permission granted for step count.")
            } else {
                print("HealthKit: Permission denied or error")
            }
        }
    }
    
    func applyShadow(to button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleLabel.textColor = SettingsManager.shared.titleColor
        
        var travelerButtonConfig = travelersButton.configuration ?? .filled()
        travelerButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        travelersButton.configuration = travelerButtonConfig
        
        var photoButtonConfig = photoButton.configuration ?? .filled()
        photoButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        photoButton.configuration = photoButtonConfig
        
        var genButtonConfig = genButton.configuration ?? .filled()
        genButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        genButton.configuration = genButtonConfig
        
        var surveyButtonConfig = surveyButton.configuration ?? .filled()
        surveyButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        surveyButton.configuration = surveyButtonConfig
        
        if SettingsManager.shared.notificationsEnabled {
            if let currentTrip = trip {
                scheduleTripNotifications(for: currentTrip)
            }
        } else {
            if let tripID = trip?.id {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trip-start-\(tripID)", "trip-end-\(tripID)"])
            }
        }
    }
    
    func scheduleTripNotifications(for trip: Trip) {
        guard SettingsManager.shared.notificationsEnabled else { return }
        
        let notifications = UNUserNotificationCenter.current()
        
        //clear old notifications so only one is ever set
        notifications.removePendingNotificationRequests(withIdentifiers: ["trip start \(trip.id)", "trip end \(trip.id)"])
        
        //set up calendar integration
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        let tripStart = calendar.startOfDay(for: trip.startDate)
        let tripEnd = calendar.startOfDay(for: trip.endDate)
        
        let startContent = UNMutableNotificationContent()
        startContent.title = "Your trip is starting!"
        startContent.body = "Today is first day of your trip to \(trip.destination)! Enjoy your travels!"
        startContent.sound = UNNotificationSound.default
        
        let endContent = UNMutableNotificationContent()
        endContent.title = "Your trip is ending!"
        endContent.body = "Today is the last day of your trip to \(trip.destination)! Hope you had a great trip!"
        endContent.sound = UNNotificationSound.default
        
        //cases: if trip is created on the same day, if trip is created & ends on the same day, or trip dates are not today
        
        if tripStart == todayStart {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: "trip start \(trip.id)", content: startContent, trigger: trigger)
            notifications.add(request)
        } else if tripStart > todayStart {
            var startDateComponents = calendar.dateComponents([.year, .month, .day], from: trip.startDate)
            startDateComponents.hour = 0
            startDateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: startDateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "trip start \(trip.id)", content: startContent, trigger: trigger)
            notifications.add(request)
        }
        
        if tripEnd == todayStart {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: "trip end \(trip.id)", content: endContent, trigger: trigger)
            notifications.add(request)
        } else if tripEnd > todayStart {
            var endDateComponents = calendar.dateComponents([.year, .month, .day], from: trip.endDate)
            endDateComponents.hour = 0
            endDateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: endDateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "trip end\(trip.id)", content: endContent, trigger: trigger)
            notifications.add(request)
        }
    }
    
    @IBAction func deleteTripTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Trip", message: "Are you sure you want to delete this trip?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performTripDeletion()
        })
        
        present(alert, animated: true)
    }
    
    private func performTripDeletion() {
        guard let id = trip?.id else {
            print("Missing trip ID")
            return
        }
        
        print("Attempting to delete trip with ID: \(id)")
        
        TripManager.shared.deleteTrip(tripID: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("Trip deleted successfully")
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("Deletion failed: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Could not delete trip: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPhotoAlbumVC",
           let destinationVC = segue.destination as? PhotoAlbumViewController {
            destinationVC.tripID = self.trip?.id
        }
        
        else if segue.identifier == "surveyID",
                let surveyVC = segue.destination as? SurveyViewController {
            surveyVC.currentTrip = self.trip
        }
        
        else if segue.identifier == "iteneraryID",
                let itineraryVC = segue.destination as? ItineraryViewController {
            itineraryVC.currentTrip = self.trip
        }
        
        else if segue.identifier == "toChatVC",
                let chatVC = segue.destination as? ChatViewController {
            chatVC.tripID = self.trip?.id
        }
    }
    
    
    @IBAction func goToTravelersTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Ritika", bundle: nil)
        if let travelerVC = storyboard.instantiateViewController(withIdentifier: "travelersID") as? TravelerViewController {
            travelerVC.trip = self.trip
            self.navigationController?.pushViewController(travelerVC, animated: true)
        } else {
            print("Error: Could not instantiate TravelerViewController from Ritika.storyboard.")
        }
    }
    
    @IBAction func generateItineraryTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Ritika", bundle: nil)
        if let itineraryVC = storyboard.instantiateViewController(withIdentifier: "iteneraryID") as? ItineraryViewController {
            itineraryVC.currentTrip = self.trip
            self.navigationController?.pushViewController(itineraryVC, animated: true)
        } else {
            print("Failed to instantiate IteneraryViewController from Ritika storyboard.")
        }
    }
    
    
}
