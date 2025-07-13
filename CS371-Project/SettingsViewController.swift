//
//  SettingsViewController.swift
//  CS371-Project
//
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {

    @IBOutlet weak var notificationsSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Optional: Load saved switch state here
    }

    @IBAction func notificationsToggled(_ sender: UISwitch) {
        if sender.isOn {
            print("Notifications turned ON")
        } else {
            print("Notifications turned OFF")
        }
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            
            // Navigate to SignInViewController from Suhani storyboard
            
            let storyboard = UIStoryboard(name: "Suhani", bundle: nil)
            let signInVC = storyboard.instantiateViewController(withIdentifier: "HomePageViewController")
            signInVC.modalPresentationStyle = .fullScreen
            present(signInVC, animated: true, completion: nil)
            
            
            
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


