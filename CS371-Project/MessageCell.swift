//
//  MessageCell.swift
//  CS371-Project
//
//  Created by Julia  on 7/19/25.
//

import UIKit

class MessageCell: UITableViewCell {
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
            super.awakeFromNib()
            messageLabel.numberOfLines = 0
            messageLabel.lineBreakMode = .byWordWrapping
            selectionStyle = .none
        }
}
