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
    var pendingInvitations: [Invitation] = []
    
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
            
            DispatchQueue.main.async {
                switch result {
                case .success(let invitations):
                    print("Successfully fetched \(invitations.count) pending invitations.")
                    self.pendingInvitations = invitations
                    self.invitationsTable.reloadData()
                case .failure(let error):
                    print("Error fetching pending invitations: \(error.localizedDescription)")
                    self.pendingInvitations = []
                    self.invitationsTable.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pendingInvitations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvitationCell", for: indexPath) as! InvitationCell
        
        // 3. Configure the cell with the 'Invitation' object.
        let invitation = pendingInvitations[indexPath.row]
        
        cell.destinationLabel.text = "     \(invitation.tripName)"
        cell.inviterLabel.text = "     \(invitation.ownerName)"
        
        // Style cell
        cell.containerView.layer.cornerRadius = 12
        cell.containerView.backgroundColor = .white
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none

        // Shadow
        cell.containerView.layer.shadowColor = UIColor.black.cgColor
        cell.containerView.layer.shadowOpacity = 0.1
        cell.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.containerView.layer.shadowRadius = 4
        
        // 4. Update the button actions to call the new manager functions.
        cell.onAccept = { [weak self] in
            TripManager.shared.acceptInvitation(invitation) { error in
                if let error = error {
                    print("Error accepting invite: \(error.localizedDescription)")
                } else {
                    print("Invite accepted successfully!")
                    // Optimistically remove the cell from the UI.
                    self?.removeInvitation(at: indexPath)
                }
            }
        }
        
        cell.onDecline = { [weak self] in
            TripManager.shared.declineInvitation(invitation) { error in
                if let error = error {
                    print("Error ignoring invite: \(error.localizedDescription)")
                } else {
                    print("Invite ignored successfully!")
                    self?.removeInvitation(at: indexPath)
                }
            }
        }
        
        return cell
    }
    
    // Helper function to remove a row from the table safely.
    private func removeInvitation(at indexPath: IndexPath) {
        DispatchQueue.main.async {
            if self.pendingInvitations.indices.contains(indexPath.row) {
                self.pendingInvitations.remove(at: indexPath.row)
                self.invitationsTable.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

class InvitationCell: UITableViewCell {
    // Outlets for your labels and buttons in the prototype cell
    
    @IBOutlet weak var inviterLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    
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

