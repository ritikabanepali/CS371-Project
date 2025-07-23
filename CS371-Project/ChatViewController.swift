//
//  ChatViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/19/25.
//

import UIKit

class ChatViewController: UIViewController{
    var tripID: String?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var send: UIButton!
    
    var messages: [Message] = [] // Your message model
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension

    }
    
    // MARK: - Data Source
    
}

struct Message {
    let senderID: String
    let senderName: String
    let text: String
    let timestamp: Date
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.senderLabel.text = message.senderName
        cell.messageLabel.text = message.text
        return cell
    }
    
    @IBAction func sendTapped(_ sender: UIButton) {
        guard let text = messageField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        // Get user ID and name from UserManager
        guard let senderID = UserManager.shared.currentUserID else { return }
        let firstName = UserManager.shared.currentUserFirstName ?? "Unknown"
        let lastName = UserManager.shared.currentUserLastName ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)

        // Create new message
        let newMessage = Message(
            senderID: senderID,
            senderName: fullName,
            text: text,
            timestamp: Date()
        )

        // Add and update table
        messages.append(newMessage)
        tableView.reloadData()
        scrollToBottom()

        // Clear input field
        messageField.text = ""
    }
    
    func scrollToBottom() {
        let lastRow = messages.count - 1
        if lastRow >= 0 {
            let indexPath = IndexPath(row: lastRow, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }



}




