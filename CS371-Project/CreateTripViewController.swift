//
//  CreateTripViewController.swift
//  CS371-Project
//
//

import UIKit
import FirebaseFirestore

class CreateTripViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var destinationField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var createNewTripTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set a minimum date for the end date picker
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
        // set initial minimum date for the end picker
        endDatePicker.minimumDate = startDatePicker.date
        
        //ui details
        backgroundView.layer.cornerRadius = 17
        backgroundView.backgroundColor = .white
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.2
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowRadius = 5
        
        // Keyboard dismissal setup
        destinationField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        
    }
    
    //ui details
    override func viewWillAppear(_ animated: Bool) {
        createNewTripTitleLabel.textColor = SettingsManager.shared.titleColor
        
        var continueButtonConfig = continueButton.configuration ?? .filled()
        continueButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        continueButton.configuration = continueButtonConfig
        
    }
    
    //sets up new trip
    @IBAction func continueButtonTapped(_ sender: Any) {
        guard let destination = destinationField.text, !destination.isEmpty else {
            showAlert(title: "Missing Destination", message: "Please enter a destination for your trip.")
            return
        }
        
        // get the dates directly from the UIDatePicker objects
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        
        // Disable the button to prevent multiple taps while saving
        continueButton.isEnabled = false
        continueButton.setTitle("Creating Trip...", for: .normal)
        
        TripManager.shared.createTrip(destination: destination, startDate: startDate, endDate: endDate) { [weak self] result in
            
            // on the main thread before doing UI updates
            DispatchQueue.main.async {
                // re-enable the button regardless of outcome
                self?.continueButton.isEnabled = true
                self?.continueButton.setTitle("Continue", for: .normal)
                
                switch result {
                case .success(let newTrip):
                    print("Successfully created trip to \(newTrip.destination)!")
                    let storyboard = UIStoryboard(name: "Abha", bundle: nil)
                    if let myTripVC = storyboard.instantiateViewController(withIdentifier: "NewTripHomeViewController") as? NewTripHomeViewController {
                        self?.navigationController?.pushViewController(myTripVC, animated: true)
                    }
                    
                case .failure(let error):
                    print("Error creating trip: \(error.localizedDescription)")
                    // Show an alert to the user so they know what went wrong
                    self?.showAlert(title: "Error", message: "Could not create trip. Please try again.)")
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
    
    // Keyboard Handling
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
