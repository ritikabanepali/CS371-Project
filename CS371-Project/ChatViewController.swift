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
       
        return cell
    }
}




