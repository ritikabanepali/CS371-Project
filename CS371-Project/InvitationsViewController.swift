//
//  InvitationsViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/15/25.
//

import UIKit

class InvitationsViewController: UIViewController {

    @IBOutlet weak var invitationsTable: UITableView!
    var pendingInvitations: [Trip] = []
    var inviterNames: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //invitationsTable.delegate = self
        //invitationsTable.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pendingInvitations.count
    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let trip = pendingInvitations[indexPath.row]
//    }
    

}
