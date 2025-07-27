//
//  TripCell.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

//storing information for a trip to show in table views
class TripCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var travelersLabel: UILabel!
    @IBOutlet weak var myButton: UIButton!
    
    var onOpenTripTapped: (() -> Void)?
    
    //ui theme details
    func updateButtonColor (){
        var myButtonConfig = myButton.configuration ?? .filled()
        myButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        myButton.configuration = myButtonConfig
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        myButton.addTarget(self, action: #selector(openTripPressed), for: .touchUpInside)
    }
    
    @objc func openTripPressed() {
        onOpenTripTapped?()
    }
}
