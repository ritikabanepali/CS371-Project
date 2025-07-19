
//  MyTripHomeViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

class MyTripHomeViewController: UIViewController {
    
    var trip: Trip?
    
    @IBOutlet var travelersButton: UIButton!
    @IBOutlet var photoButton: UIButton!
    @IBOutlet var genButton: UIButton!
    @IBOutlet var surveyButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let destination = trip?.destination {
            titleLabel.text = "\(destination)"
        } else {
            titleLabel.text = "My Trip"
        }
        
        HealthKitManager.shared.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            if authorized {
                print("HealthKit: Permission granted for step count.")
            } else {
                print("HealthKit: Permission denied or error")
            }
        }
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
                let itineraryVC = segue.destination as? IteneraryViewController {
            itineraryVC.currentTrip = self.trip
        }
        
        else if segue.identifier == "toChatVC",
                let chatVC = segue.destination as? ChatViewController {
            chatVC.tripID = self.trip?.id
        }
    }

    
    @IBAction func goToTravelersTapped(_ sender: UIButton) {
        // 1. Get a reference to the other storyboard.
        let storyboard = UIStoryboard(name: "Ritika", bundle: nil)
        
        // 2. Instantiate the specific view controller using its Storyboard ID.
        //    Make sure the ID matches what you set in the storyboard.
        if let travelerVC = storyboard.instantiateViewController(withIdentifier: "travelersID") as? TravelerViewController {
            
            // 3. Pass the trip data to the new view controller.
            travelerVC.trip = self.trip
            
            // 4. Present the new view controller.
            //    This assumes you are using a UINavigationController.
            self.navigationController?.pushViewController(travelerVC, animated: true)
            
        } else {
            // This will help you debug if the Storyboard ID is wrong or the class isn't set correctly.
            print("Error: Could not instantiate TravelerViewController from Ritika.storyboard.")
        }
    }
    
    

    
}
