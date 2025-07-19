//
//  NewTripHomeViewController.swift
//  CS371-Project
//
//  Created by Abha on 7/8/25.
//

import UIKit
import FirebaseFirestore

class NewTripHomeViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    
    @IBOutlet var createButton: UIButton!
    @IBOutlet var upcomingButton: UIButton!
    @IBOutlet var pastButton: UIButton!
    @IBOutlet var pendingButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyShadow(to: createButton)
        applyShadow(to: upcomingButton)
        applyShadow(to: pastButton)
        applyShadow(to: pendingButton)
        applyShadow(to: settingsButton)
        
        // set the welcome text, later username will be sign in username
        if let firstName = UserManager.shared.currentUserFirstName {
            welcomeLabel.text = "Hello, \(firstName)!"
        } else {
            welcomeLabel.text = "Hello!"
            print("User first name not found in UserManager.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyColorScheme()
    }
    
    func applyShadow(to button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
    }
    
    func applyColorScheme(){
        welcomeLabel.textColor = SettingsManager.shared.titleColor
        
        var createButtonConfig = createButton.configuration ?? .filled()
        createButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        createButton.configuration = createButtonConfig
        
        var upcomingButtonConfig = upcomingButton.configuration ?? .filled()
        upcomingButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        upcomingButton.configuration = upcomingButtonConfig
        
        var pastButtonConfig = pastButton.configuration ?? .filled()
        pastButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        pastButton.configuration = pastButtonConfig
        
        var pendingButtonConfig = pendingButton.configuration ?? .filled()
        pendingButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        pendingButton.configuration = pendingButtonConfig
        
        var settingsButtonConfig = settingsButton.configuration ?? .filled()
        settingsButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        settingsButton.configuration = settingsButtonConfig
        
    }
    
    @IBAction func pastTripsTapped(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PastTripsViewController") as! PastTripsViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func settingsTapped(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func futureTripsTapped(_ sender: UIButton) {
        print("Future trips tapped") // No navigation yet
    }
    
    @IBAction func pendingRequestsTapped(_ sender: UIButton) {
        print("Pending requests tapped")
    }
}

