//
//  TripCell.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

class TripCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var travelersLabel: UILabel!

    @IBOutlet weak var myButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
