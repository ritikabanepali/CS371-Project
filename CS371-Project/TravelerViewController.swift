//
//  TravelerViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/5/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

struct TravelerViewModel {
    let uid: String
    let name: String
    let status: String // "confirmed" or "pending"
    let surveyStatus: String
}

class TravelerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var travelersTitleLabel: UILabel!
    @IBOutlet weak var enterEmailTextField: UITextField!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var invitedTableView: UITableView!
    @IBOutlet weak var tripNameLabel: UILabel!
    
    var trip: Trip?
    private var travelers: [TravelerViewModel] = []
    private var tripListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        invitedTableView.dataSource = self
        invitedTableView.delegate = self
        travelersTitleLabel.textColor = SettingsManager.shared.titleColor
        
        var inviteButtonConfig = inviteButton.configuration ?? .filled()
        inviteButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        inviteButton.configuration = inviteButtonConfig
        
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

        setupTripListener()
    }
    
    deinit {
        // Removes the listener when the view controller is deallocated
        tripListener?.remove()
        print("TravelerViewController deinit, listener removed.")
    }
    
    private func setupTripListener() {
        guard let trip = trip else { return }
        
        let db = Firestore.firestore()
        let tripRef = db.collection("Users").document(trip.ownerUID).collection("trips").document(trip.id)
        
        tripListener = tripRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            guard let document = documentSnapshot, document.exists else {
                print("Trip document not found or error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            // Get the updated list of traveler UIDs from the document
            if let updatedTravelerUIDs = document.data()?["travelerUIDs"] as? [String] {
                // Update the local trip object and reload the data
                self.trip?.travelerUIDs = updatedTravelerUIDs
                self.loadTravelerData()
            }
        }
    }
    
    
    private func loadTravelerData() {
        guard let trip = trip else { return }

        // Get a reference to the trip document in Firestore
        let db = Firestore.firestore()
        let tripRef = db.collection("Users").document(trip.ownerUID).collection("trips").document(trip.id)
        
        let group = DispatchGroup()
        var fetchedTravelers: [TravelerViewModel] = []

        for uid in trip.travelerUIDs {
            group.enter() // Enter the group for each traveler

            // Step 1: Check if a survey response exists for this traveler's UID
            tripRef.collection("surveyResponses").document(uid).getDocument { (document, error) in
                
                // Determine survey status: "Y" if document exists, otherwise "N"
                let surveyCompleted = document?.exists ?? false
                let surveyStatus = surveyCompleted ? "Y" : "N"
                
                // Step 2: Now that we have the status, fetch the traveler's name
                UserManager.shared.fetchName(forUserWithUID: uid) { result in
                    var travelerName = "Unknown User"
                    if case .success(let name) = result {
                        travelerName = name
                    }
                    
                    // Step 3: Create the final view model with all the dynamic data
                    let traveler = TravelerViewModel(
                        uid: uid,
                        name: travelerName,
                        status: "confirmed", // As per your original logic
                        surveyStatus: surveyStatus // Use the fetched status
                    )
                    
                    fetchedTravelers.append(traveler)
                    group.leave() // Leave the group, signaling this traveler is done
                }
            }
        }

        // This block runs only after ALL travelers have been processed
        group.notify(queue: .main) {
            self.travelers = fetchedTravelers.sorted {
                // Your existing sorting logic
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
    
    
    // This function determines which rows can be swiped.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let currentUserUID = Auth.auth().currentUser?.uid, let trip = self.trip else {
            return false
        }
        
        let travelerToRemove = travelers[indexPath.row]
        
        // Allow editing if:
        // 1. The current user is the trip owner and isn't trying to remove themselves.
        if currentUserUID == trip.ownerUID && currentUserUID != travelerToRemove.uid {
            return true
        }
        
        // 2. The current user is trying to remove themselves (and they aren't the owner).
        if currentUserUID == travelerToRemove.uid && currentUserUID != trip.ownerUID {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // This immediately deselects the row after it's been tapped.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // This function handles the actual deletion.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let trip = self.trip else { return }
            
            let travelerToRemove = travelers[indexPath.row]
            let isLeaving = travelerToRemove.uid == Auth.auth().currentUser?.uid
            let alertTitle = isLeaving ? "Leave Trip?" : "Remove Traveler?"
            let alertMessage = isLeaving ? "Are you sure you want to leave this trip?" : "Are you sure you want to remove \(travelerToRemove.name)?"
            
            // Show a confirmation alert
            let confirmationAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirmationAlert.addAction(UIAlertAction(title: isLeaving ? "Leave" : "Remove", style: .destructive, handler: { _ in
                
                // Call the manager to remove the user from Firestore
                TripManager.shared.removeTraveler(from: trip, userToRemoveUID: travelerToRemove.uid) { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    // If successful, remove the user from the local array and table view
                    DispatchQueue.main.async {
                        self.travelers.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }))
            self.present(confirmationAlert, animated: true)
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
        cell.surveyStatusLabel.text = traveler.surveyStatus
        
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

