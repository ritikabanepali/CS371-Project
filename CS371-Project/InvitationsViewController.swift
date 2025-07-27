//
//  InvitationsViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/15/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

// view controller that handles the display and data of a user receiving an invitation from someone else
class InvitationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var invitationsTitleLabel: UILabel!
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
        invitationsTitleLabel.textColor = SettingsManager.shared.titleColor
    }
    
    // fetch the invitations data this user has received
    func fetchPendingInvitations() {
        TripManager.shared.fetchPendingInvitations { [weak self] result in
            guard let self = self else { return }
            
            // get the data and then display it on the ui on the main thread
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
    
    // displays ui all invitations
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InvitationCell", for: indexPath) as! InvitationCell
        
        let invitation = pendingInvitations[indexPath.row]
        
        cell.destinationLabel.text = "     \(invitation.tripName)"
        cell.inviterLabel.text = "     \(invitation.ownerName)"
        
        // style cell
        cell.containerView.layer.cornerRadius = 12
        cell.containerView.backgroundColor = .white
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        
        // shadow
        cell.containerView.layer.shadowColor = UIColor.black.cgColor
        cell.containerView.layer.shadowOpacity = 0.1
        cell.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.containerView.layer.shadowRadius = 4
        
        cell.applyColorScheme()
        
        //  update the button actions if a user accepts an invitation
        cell.onAccept = { [weak self] in
            TripManager.shared.acceptInvitation(invitation) { error in
                if let error = error {
                    print("Error accepting invite: \(error.localizedDescription)")
                } else {
                    print("Invite accepted successfully!")
                    self?.removeInvitation(at: indexPath)
                }
            }
        }
        cell.onDecline = { [weak self] in // user declines an invitation
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
    
    // helper function to remove a row from the table safely.
    private func removeInvitation(at indexPath: IndexPath) {
        DispatchQueue.main.async {
            if self.pendingInvitations.indices.contains(indexPath.row) {
                self.pendingInvitations.remove(at: indexPath.row)
                self.invitationsTable.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

// the cells displayed on the InvitationsViewController that shows the information of a trip a user has been invited to
class InvitationCell: UITableViewCell {
    
    @IBOutlet weak var inviterLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    
    // ui configurations
    func applyColorScheme() {
        var acceptButtonConfig = acceptButton.configuration ?? .filled()
        acceptButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        acceptButton.configuration = acceptButtonConfig
        
        var declineButtonConfig = declineButton.configuration ?? .filled()
        declineButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        declineButton.configuration = declineButtonConfig
    }
    
    @IBAction func acceptTapped(_ sender: UIButton) {
        onAccept?()
    }
    
    @IBAction func declineTapped(_ sender: UIButton) {
        onDecline?()
    }
    
}

