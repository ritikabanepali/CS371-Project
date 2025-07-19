//
//  IteneraryViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/6/25.
//

import UIKit
import FirebaseFirestore

class IteneraryViewController: UIViewController {
    
    @IBOutlet weak var itineraryTitleLabel: UILabel!
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var moreLocationsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itineraryTitleLabel.textColor = SettingsManager.shared.titleColor
        
        var orderButtonConfig = orderButton.configuration ?? .filled()
        orderButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        orderButton.configuration = orderButtonConfig
        
        var moreLocationsButtonConfig = moreLocationsButton.configuration ?? .filled()
        moreLocationsButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        moreLocationsButton.configuration = moreLocationsButtonConfig
        
    }
    
}
