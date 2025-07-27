//
//  SettingsViewController.swift
//  CS371-Project
//
//

import UIKit
import FirebaseAuth
import UserNotifications

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var colorSchemeController: UISegmentedControl!
    @IBOutlet weak var saveSettingsButton: UIButton!
    @IBOutlet weak var settingsLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    //loads user settings from SettingsManager, updates color scheme and UI details
    override func viewDidLoad() {
        super.viewDidLoad()
        SettingsManager.shared.loadSettings { [weak self] in
            guard let self = self else { return }
            
            self.updateFromSettingsManager()
            self.applyColorScheme()
            
            applyShadow(to: saveSettingsButton)
            applyShadow(to: logoutButton)
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    self.notificationsSwitch.isOn = false
                    self.notificationsSwitch.isEnabled = false
                    
                } else {
                    self.notificationsSwitch.isEnabled = true
                }
            }
        }
    }
    
    func applyShadow(to button: UIButton) {
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFromSettingsManager()
        applyColorScheme()
    }
    
    func updateFromSettingsManager(){
        notificationsSwitch.isOn = SettingsManager.shared.notificationsEnabled
        colorSchemeController.selectedSegmentIndex = SettingsManager.shared.colorSchemeIsRed ? 1 : 0
    }
    
    func applyColorScheme(){
        settingsLabel.textColor = SettingsManager.shared.titleColor
        
        var saveButtonConfiguration = saveSettingsButton.configuration ?? .filled()
        saveButtonConfiguration.background.backgroundColor = SettingsManager.shared.buttonColor
        saveSettingsButton.configuration = saveButtonConfiguration
        
        var logoutButtonConfiguration = logoutButton.configuration ?? .filled()
        logoutButtonConfiguration.background.backgroundColor = SettingsManager.shared.buttonColor
        logoutButton.configuration = logoutButtonConfiguration
        colorSchemeController.tintColor = SettingsManager.shared.buttonColor
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    //request authorization from user, if given,
    @IBAction func notificationsToggled(_ sender: UISwitch) {
        if sender.isOn {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (granted,error) in
                if granted {
                    print("authorization for notifications granted")
                } else if let error = error {
                    print(error.localizedDescription)
                    self.notificationsSwitch.isOn = false
                } else {
                    self.notificationsSwitch.isOn = false
                }
            }
            print("notifications turned ON")
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("notifications turned OFF")
        }
    }
    
    //log out user, return to homepage
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UserManager.shared.logoutUserData()
            let storyboard = UIStoryboard(name: "Suhani", bundle: nil)
            let signInVC = storyboard.instantiateViewController(withIdentifier: "HomePageViewController")
            signInVC.modalPresentationStyle = .fullScreen
            present(signInVC, animated: true, completion: nil)
        } catch {
            print("Error signing out")
        }
    }
    
    //saves settings that user has selected, update the viewcontroller, save to firestore
    @IBAction func saveSettingsButtonTapped(_ sender: Any) {
        let newNotificationsEnabled = notificationsSwitch.isOn
        let newColorSchemeIsRed = (colorSchemeController.selectedSegmentIndex == 1)
        SettingsManager.shared.notificationsEnabled = newNotificationsEnabled
        SettingsManager.shared.colorSchemeIsRed = newColorSchemeIsRed
        SettingsManager.shared.saveUserSettings()
        applyColorScheme()
    }
}


