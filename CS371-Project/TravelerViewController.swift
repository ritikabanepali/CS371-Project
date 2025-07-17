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
        print("✅ CHECKPOINT 2: TravelerVC received trip. Travelers count: \(self.trip?.travelers.count ?? -1)")
        invitedTableView.dataSource = self
        invitedTableView.delegate = self
        
        // helper method
        configureView()
        navigationController?.navigationBar.tintColor = .black
    }
    
    private func configureView() {
        guard let trip = trip else {
            print("Error: Trip object was not provided.")
            tripNameLabel.text = "Travelers"
            return
        }
        
        tripNameLabel.text = "\(trip.destination)"
        tripNameLabel.numberOfLines = 2 // Allow the text to wrap
        
        loadTravelerData()
    }
    
    private func loadTravelerData() {
        guard let trip = trip else { return }

        let group = DispatchGroup()
        var fetchedTravelers: [TravelerViewModel] = []

        for (uid, status) in trip.travelers {
            print("✅ CHECKPOINT 3: Loop is running for UID: \(uid)")
            group.enter() // Enter the group for each async call
            UserManager.shared.fetchName(forUserWithUID: uid) { result in
                switch result {
                case .success(let name):
                    let traveler = TravelerViewModel(name: name, status: status, surveyStatus: "N")
                    fetchedTravelers.append(traveler)
                case .failure(let error):
                    print("Could not fetch name for UID \(uid): \(error)")
                    // Add a placeholder if the name fetch fails
                    let traveler = TravelerViewModel(name: "Unknown User", status: status, surveyStatus: "N")
                    fetchedTravelers.append(traveler)
                }
                group.leave() // Leave the group when the call is done
            }
        }
        
        // This closure runs only after ALL fetchName calls have completed
        group.notify(queue: .main) {
            print("✅ CHECKPOINT 4: All names fetched. Final array count: \(fetchedTravelers.count). Reloading table.")

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
        
        guard let tripToUpdate = self.trip else { return }
        
        inviteButton.isEnabled = false // Disable button to prevent double-taps
        
        TripManager.shared.inviteTraveler(withEmail: email, to: tripToUpdate) { [weak self] error in
            guard let self = self else { return }
            
            // Re-enable the button on the main thread
            DispatchQueue.main.async {
                self.inviteButton.isEnabled = true
                self.enterEmailTextField.text = "" // Clear the text field
            }
            
            if let error = error {
                self.showAlert(title: "Invite Error", message: error.localizedDescription)
                return
            }
            
            // Since the invite was successful, we can just show a success message.
            // A full implementation would require re-fetching the trip or using a listener
            // to show the new invitee instantly.
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

