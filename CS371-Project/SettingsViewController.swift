//
//  SettingsViewController.swift
//  CS371-Project
//
//

import UIKit

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
}

