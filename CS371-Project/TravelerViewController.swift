//
//  TravelerViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/5/25.
//

import UIKit
import FirebaseAuth

class TravelerViewController: UIViewController {

    @IBOutlet weak var enterEmailTextField: UITextField!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var invitedTableView: UITableView!
    @IBOutlet weak var tripNameLabel: UILabel!
    
    var tripID: String?
    var invitedFriends: [String] = []
    var invitedFriendsNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.tintColor = .black
    }

}
