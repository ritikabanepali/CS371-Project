//
//  TravelerViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/5/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// shared information for a travelers among a trip
struct TravelerViewModel {
    let uid: String
    let name: String
    let status: String // "confirmed" or "pending"
    let surveyStatus: String // 'y' or 'n' if survey completed
}

class TravelerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var travelersTitleLabel: UILabel!
    @IBOutlet weak var enterEmailTextField: UITextField!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var invitedTableView: UITableView!
    @IBOutlet weak var tripNameLabel: UILabel!
    
    var trip: Trip? // the trip object passed to this view controller
    private var travelers: [TravelerViewModel] = []
    private var tripListener: ListenerRegistration? // detects real time changes of the TravelerViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        invitedTableView.dataSource = self
        invitedTableView.delegate = self
        travelersTitleLabel.textColor = SettingsManager.shared.titleColor
        
        // custom colors
        var inviteButtonConfig = inviteButton.configuration ?? .filled()
        inviteButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        inviteButton.configuration = inviteButtonConfig
        
        // set up the view and start listening for data changes.
        configureView()
        navigationController?.navigationBar.tintColor = .black
    }
    
    // removes the listener when the view controller is deallocated
    deinit {
        tripListener?.remove()
    }
    
    // button customizations
    func applyShadow(to button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
    }
    
    // initial set up of the view when looking at travelers that are part of a trip
    private func configureView() {
        guard let trip = trip else {
            print("Error: Trip object was not provided.")
            tripNameLabel.text = "Travelers"
            return
        }
        
        tripNameLabel.text = "\(trip.destination)"
        tripNameLabel.numberOfLines = 2
        
        applyShadow(to: inviteButton)
        
        setupTripListener()
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
    
    // fetches detailed information for each traveler in the trip
    private func loadTravelerData() {
        guard let trip = trip else { return }
        
        // get a reference to the trip document in Firestore
        let db = Firestore.firestore()
        let tripRef = db.collection("Users").document(trip.ownerUID).collection("trips").document(trip.id)
        
        let group = DispatchGroup() // ensuring the UI is updated only after all data has been retrieved.
        var fetchedTravelers: [TravelerViewModel] = []
        
        for uid in trip.travelerUIDs {
            group.enter() // enter the group for each traveler
            
            // check if a survey response exists for this traveler's UID
            tripRef.collection("surveyResponses").document(uid).getDocument { (document, error) in
                
                // determine survey status: "Y" if document exists, otherwise "N"
                let surveyCompleted = document?.exists ?? false
                let surveyStatus = surveyCompleted ? "Y" : "N"
                
                // fetch the traveler's name
                UserManager.shared.fetchName(forUserWithUID: uid) { result in
                    var travelerName = "Unknown User"
                    if case .success(let name) = result {
                        travelerName = name
                    }
                    
                    // create the final view model with all the dynamic data
                    let traveler = TravelerViewModel(
                        uid: uid,
                        name: travelerName,
                        status: "confirmed",
                        surveyStatus: surveyStatus
                    )
                    
                    fetchedTravelers.append(traveler)
                    group.leave() // this traveler is done
                }
            }
        }
        
        // block runs only after ALL travelers have been processed
        group.notify(queue: .main) {
            self.travelers = fetchedTravelers.sorted {
                if $0.status == "confirmed" && $1.status == "pending" { return true }
                return false
            }
            self.invitedTableView.reloadData()
        }
    }
    
    // a user is invited another traveler into the trip
    @IBAction func inviteButtonTapped(_ sender: Any) {
        guard let email = enterEmailTextField.text, !email.isEmpty else {
            showAlert(title: "Missing Email", message: "Please enter an email to invite a traveler.")
            return
        }
        
        guard let tripToUpdate = self.trip,
              let inviterName = UserManager.shared.currentUserFirstName else { // get current user's name
            return
        }
        
        inviteButton.isEnabled = false
        
        // call the new 'sendInvitation' function from TripManager
        TripManager.shared.sendInvitation(toEmail: email, forTrip: tripToUpdate, fromUser: inviterName) { [weak self] error in
            guard let self = self else { return }
            
            // update UI elements to the main thread
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
    
    
    // which rows can be swiped. used for deleting travelers from a trip.
    // owner cannot remove themselves from their trip. they must delete the trip entirely
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // fetch the current user's uid
        guard let currentUserUID = Auth.auth().currentUser?.uid, let trip = self.trip else {
            return false
        }
        
        let travelerToRemove = travelers[indexPath.row]
        
        // the current user is the trip owner and isn't trying to remove themselves.
        if currentUserUID == trip.ownerUID && currentUserUID != travelerToRemove.uid {
            return true
        }
        
        // the current user is trying to remove themselves (and they aren't the owner)
        if currentUserUID == travelerToRemove.uid && currentUserUID != trip.ownerUID {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // handles the actual deletion of a person leaving a trip
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let trip = self.trip else { return }
            
            let travelerToRemove = travelers[indexPath.row]
            let isLeaving = travelerToRemove.uid == Auth.auth().currentUser?.uid
            let alertTitle = isLeaving ? "Leave Trip?" : "Remove Traveler?"
            let alertMessage = isLeaving ? "Are you sure you want to leave this trip?" : "Are you sure you want to remove \(travelerToRemove.name)?"
            
            // show a confirmation alert
            let confirmationAlert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirmationAlert.addAction(UIAlertAction(title: isLeaving ? "Leave" : "Remove", style: .destructive, handler: { _ in
                
                // call the manager to remove the user from Firestore
                TripManager.shared.removeTraveler(from: trip, userToRemoveUID: travelerToRemove.uid) { [weak self] error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    // if successful, remove the user from the local array and table view
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
    
    // display all the travelers a part of the trup
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TravelerCell", for: indexPath) as! TravelerCell
        
        // display traveler data
        let traveler = travelers[indexPath.row]
        cell.nameLabel.text = traveler.name
        cell.surveyStatusLabel.text = traveler.surveyStatus

        cell.nameLabel.textColor = .label
        cell.surveyStatusLabel.textColor = .label
        
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

