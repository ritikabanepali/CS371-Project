//
//  InvitationsViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/15/25.
//

import UIKit
import FirebaseAuth

class InvitationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var invitationsTable: UITableView!
    var pendingInvitations: [Trip] = []
    var inviterNames: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        invitationsTable.delegate = self
        invitationsTable.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPendingInvitations()
    }
    
    func fetchPendingInvitations() {
        TripManager.shared.fetchPendingInvitations { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let trips):
                self.pendingInvitations = trips
                self.fetchInviterNames(for: trips) // Fetch names after getting trips
            case .failure(let error):
                print("Error fetching pending invitations: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.pendingInvitations = []
                    self.invitationsTable.reloadData()
                }
            }
        }
    }
    
    func fetchInviterNames(for trips: [Trip]) {
        let group = DispatchGroup()
        for trip in trips {
            group.enter()
            UserManager.shared.fetchName(forUserWithUID: trip.ownerUID) { result in
                switch result {
                case .success(let name):
                    // Store the fetched name using the owner's UID as the key
                    self.inviterNames[trip.ownerUID] = name
                case .failure:
                    self.inviterNames[trip.ownerUID] = "Unknown Inviter"
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Once all names are fetched, reload the table
            self.invitationsTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pendingInvitations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvitationCell", for: indexPath) as! InvitationCell
        let trip = pendingInvitations[indexPath.row]
        
        // Configure cell labels
        cell.destinationLabel.text = trip.destination
        cell.inviterLabel.text = "Invited by: \(inviterNames[trip.ownerUID] ?? "...")"
        
        // Handle "Accept" button tap
        cell.onAccept = { [weak self] in
            guard let self = self, let currentUserUID = Auth.auth().currentUser?.uid else { return }
            
            TripManager.shared.updateTraveler(forTrip: trip, travelerUID: currentUserUID, newStatus: "confirmed") { error in
                if let error = error {
                    print("Error accepting invite: \(error.localizedDescription)")
                    // Optionally show an alert to the user
                } else {
                    print("Invite accepted successfully!")
                    // Remove the accepted invitation and refresh the table
                    DispatchQueue.main.async {
                        self.pendingInvitations.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
        
        // Handle "Decline" button tap
        cell.onDecline = { [weak self] in
            // To decline, you can either remove the user from the travelers map
            // or update their status to "declined". For now, we'll just remove it locally.
            print("Declined invite for trip to \(trip.destination)")
            DispatchQueue.main.async {
                self?.pendingInvitations.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        return cell
    }
    
    
}

class InvitationCell: UITableViewCell {
    // Outlets for your labels and buttons in the prototype cell
    
    @IBOutlet weak var inviterLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    
    
    // Closures to handle button taps in the view controller
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    
    
    
    
    @IBAction func acceptTapped(_ sender: UIButton) {
        onAccept?()
    }
    
    @IBAction func declineTapped(_ sender: UIButton) {
        onDecline?()
    }
}

