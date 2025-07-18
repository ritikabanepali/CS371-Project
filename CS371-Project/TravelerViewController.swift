//
//  TravelerViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/5/25.
//

import UIKit
import FirebaseAuth

struct TravelerViewModel {
    let name: String
    let status: String // "confirmed" or "pending"
    let surveyStatus: String
}

class TravelerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var enterEmailTextField: UITextField!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var invitedTableView: UITableView!
    @IBOutlet weak var tripNameLabel: UILabel!
    
    var trip: Trip?
    private var travelers: [TravelerViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        invitedTableView.dataSource = self
        invitedTableView.delegate = self
        
        // helper method
        configureView()
        navigationController?.navigationBar.tintColor = .black
    }
    
    func applyShadow(to button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
    }
    
    private func configureView() {
        guard let trip = trip else {
            print("Error: Trip object was not provided.")
            tripNameLabel.text = "Travelers"
            return
        }
        
        tripNameLabel.text = "\(trip.destination)"
        tripNameLabel.numberOfLines = 2 // Allow the text to wrap
        
        applyShadow(to: inviteButton)
        
        loadTravelerData()
    }
    
    private func loadTravelerData() {
        guard let trip = trip else { return }

        let group = DispatchGroup()
        var fetchedTravelers: [TravelerViewModel] = []

        for uid in trip.travelerUIDs { // <-- 1. Get only the uid
            group.enter()
            UserManager.shared.fetchName(forUserWithUID: uid) { result in
                switch result {
                case .success(let name):
                    let traveler = TravelerViewModel(name: name, status: "confirmed", surveyStatus: "N") // <-- 2. Hardcode the status
                    fetchedTravelers.append(traveler)
                case .failure(let error):
                    print("Could not fetch name for UID \(uid): \(error)")
                    // Also update the placeholder to use "confirmed"
                    let traveler = TravelerViewModel(name: "Unknown User", status: "confirmed", surveyStatus: "N")
                    fetchedTravelers.append(traveler)
                }
                group.leave()
            }
        }
        
        // This closure runs only after ALL fetchName calls have completed
        group.notify(queue: .main) {

            // Sort to show confirmed users first
            self.travelers = fetchedTravelers.sorted {
                if $0.status == "confirmed" && $1.status == "pending" { return true }
                return false
            }
            self.invitedTableView.reloadData()
        }
    }
    
    
    @IBAction func inviteButtonTapped(_ sender: Any) {
        guard let email = enterEmailTextField.text, !email.isEmpty else {
             showAlert(title: "Missing Email", message: "Please enter an email to invite a traveler.")
             return
         }
         
         guard let tripToUpdate = self.trip,
               let inviterName = UserManager.shared.currentUserFirstName else { // Get current user's name
             return
         }
         
         inviteButton.isEnabled = false
         
         // Call the new 'sendInvitation' function
         TripManager.shared.sendInvitation(toEmail: email, forTrip: tripToUpdate, fromUser: inviterName) { [weak self] error in
             guard let self = self else { return }
             
             DispatchQueue.main.async {
                 self.inviteButton.isEnabled = true
                 self.enterEmailTextField.text = ""
             }
             
             if let error = error {
                 self.showAlert(title: "Invite Error", message: error.localizedDescription)
                 return
             }
             
             self.showAlert(title: "Success!", message: "\(email) has been invited to the trip.")
         }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return travelers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TravelerCell", for: indexPath) as! TravelerCell
        
        let traveler = travelers[indexPath.row]
        
        cell.nameLabel.text = traveler.name
        
        // This is where you would set the survey status text based on your data model
        cell.surveyStatusLabel.text = "N" // Placeholder
        
        // Visually distinguish between pending and confirmed
        if traveler.status == "pending" {
            cell.nameLabel.textColor = .systemGray
            cell.surveyStatusLabel.textColor = .systemGray
        } else {
            cell.nameLabel.textColor = .label // Adapts to light/dark mode
            cell.surveyStatusLabel.textColor = .label
        }
        
        return cell
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

}

class TravelerCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var surveyStatusLabel: UILabel!
}

