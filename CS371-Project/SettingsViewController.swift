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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SettingsManager.shared.loadSettings { [weak self] in
            guard let self = self else { return }
            
            self.updateFromSettingsManager()
            self.applyColorScheme()
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .denied {
                self.notificationsSwitch.isOn = false
                self.notificationsSwitch.isEnabled = false
                
            } else {
                self.notificationsSwitch.isEnabled = true
            }
        }
        
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
    
    @IBAction func notificationsToggled(_ sender: UISwitch) {
        if sender.isOn {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (granted,error) in
                if granted {
                    print("All set!")
                } else if let error = error {
                    print(error.localizedDescription)
                    self.notificationsSwitch.isOn = false
                } else {
                    self.notificationsSwitch.isOn = false
                }
            }
            print("Notifications turned ON")
        } else {
            print("Notifications turned OFF")
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            UserManager.shared.logoutUserData()
            // Navigate to SignInViewController from Suhani storyboard
            
            let storyboard = UIStoryboard(name: "Suhani", bundle: nil)
            let signInVC = storyboard.instantiateViewController(withIdentifier: "HomePageViewController")
            signInVC.modalPresentationStyle = .fullScreen
            present(signInVC, animated: true, completion: nil)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    @IBAction func saveSettingsButtonTapped(_ sender: Any) {
        let newNotificationsEnabled = notificationsSwitch.isOn
        let newColorSchemeIsRed = (colorSchemeController.selectedSegmentIndex == 1)
        SettingsManager.shared.notificationsEnabled = newNotificationsEnabled
        SettingsManager.shared.colorSchemeIsRed = newColorSchemeIsRed
        SettingsManager.shared.saveUserSettings()
        print("Setttings saved!")
        applyColorScheme()
    }
    
}


