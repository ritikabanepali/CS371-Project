//
//  LocationViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/6/25.
//

import UIKit

class LocationViewController: UIViewController {
    
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet weak var shareLocationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationTitleLabel.textColor = SettingsManager.shared.titleColor
        
        var locationButtonConfig = shareLocationButton.configuration ?? .filled()
        locationButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        shareLocationButton.configuration = locationButtonConfig
    }
    
}
