//
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
    }
    
    @IBAction func goToTravelersTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Ritika", bundle: nil)
        if let travelerVC = storyboard.instantiateViewController(withIdentifier: "travelersID") as? TravelerViewController {
            travelerVC.trip = self.trip
            self.navigationController?.pushViewController(travelerVC, animated: true)
        }
    }
    
    
}
