//
//  ChatViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/19/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController, UITextFieldDelegate{
    var tripID: String?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var send: UIButton!
    
    // message model
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        loadMessages()
        
        messageField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
}

struct Message: Codable {
    let senderID: String
    let senderName: String
    let text: String
    let timestamp: Date
    
    init(senderID: String, senderName: String, text: String, timestamp: Date) {
        self.senderID = senderID
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
    }
    
    init?(from dict: [String: Any]) {
        guard let senderID = dict["senderID"] as? String,
              let senderName = dict["senderName"] as? String,
              let text = dict["text"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.senderID = senderID
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp.dateValue()
    }
    
    func toDict() -> [String: Any] {
        return [
            "senderID": senderID,
            "senderName": senderName,
            "text": text,
            "timestamp": timestamp
        ]
    }
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
        
        guard let senderID = UserManager.shared.currentUserID else { return }
        let firstName = UserManager.shared.currentUserFirstName ?? "Unknown"
        let lastName = UserManager.shared.currentUserLastName ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        let newMessage = Message(
            senderID: senderID,
            senderName: fullName,
            text: text,
            timestamp: Date()
        )
        
        messageField.text = ""
        saveMessageToFirestore(newMessage)
    }
    
    
    func scrollToBottom() {
        let lastRow = messages.count - 1
        if lastRow >= 0 {
            let indexPath = IndexPath(row: lastRow, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // save and load messages
    func saveMessageToFirestore(_ message: Message) {
        guard let tripID = tripID else { return }
        
        let db = Firestore.firestore()
        let tripRef = db.collection("Users")
            .document(message.senderID)
            .collection("trips")
            .document(tripID)
        
        let messagesRef = tripRef.collection("messages")
        messagesRef.addDocument(data: message.toDict())
    }
    
    
    func loadMessages() {
        guard let tripID = tripID,
              let currentUserID = UserManager.shared.currentUserID else { return }
        
        let db = Firestore.firestore()
        let messagesRef = db.collection("Users")
            .document(currentUserID)
            .collection("trips")
            .document(tripID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
        
        messagesRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            self.messages = documents.compactMap { Message(from: $0.data()) }
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
