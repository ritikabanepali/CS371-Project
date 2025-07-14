//
//  CreateTripViewController.swift
//  CS371-Project
//
//

import UIKit


class CreateTripViewController: UIViewController {
    
    @IBOutlet weak var destinationField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var startDatePicker: UIDatePicker!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set a minimum date for the end date picker
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        // set initial minimum date for the end picker
        endDatePicker.minimumDate = startDatePicker.date
    }
    
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        
        guard let destination = destinationField.text, !destination.isEmpty else {
            showAlert(title: "Missing Destination", message: "Please enter a destination for your trip.")
            return
        }
        
        // get the dates directly from the UIDatePicker objects
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        let invitedFriends = [String]()
        
        // Disable the button to prevent multiple taps while saving
        continueButton.isEnabled = false
        continueButton.setTitle("Creating Trip...", for: .normal)
        
        // call the TripManager to save the data to Firestore
        TripManager.shared.createTrip(destination: destination, startDate: startDate, endDate: endDate, invitedFriends: invitedFriends) { [weak self] result in
            
            // on the main thread before doing UI updates
            DispatchQueue.main.async {
                // Re-enable the button regardless of outcome
                self?.continueButton.isEnabled = true
                self?.continueButton.setTitle("Continue", for: .normal)
                
                switch result {
                case .success(let newTrip):
                    print("Successfully created trip to \(newTrip.destination)!")
                    // On success, goes to my trip vc
                    let storyboard = UIStoryboard(name: "Julia", bundle: nil)
                    if let myTripVC = storyboard.instantiateViewController(withIdentifier: "MyTripHomeViewController") as? MyTripHomeViewController {
                        myTripVC.tripDestination = newTrip.destination
                        self?.navigationController?.pushViewController(myTripVC, animated: true)
                    }

                    
                case .failure(let error):
                    print("Error creating trip: \(error.localizedDescription)")
                    // Show an alert to the user so they know what went wrong
                    self?.showAlert(title: "Error", message: "Could not create trip. Please try again. \n(\(error.localizedDescription))")
                }
            }
        }
    }
    
    @objc func startDateChanged() {
        // whenever the start date changes, update the minimum allowed end date
        endDatePicker.minimumDate = startDatePicker.date
    }
    
    // helper function to display alerts to the user
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


