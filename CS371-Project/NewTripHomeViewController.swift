//
//  NewTripHomeViewController.swift
//  CS371-Project
//
//  Created by Abha on 7/8/25.
//

import UIKit

class NewTripHomeViewController: UIViewController {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var futureTripsButton: UIButton!
    @IBOutlet weak var pastTripsButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var pendingRequestsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the welcome text, later username will be sign in username
        if let firstName = UserManager.shared.currentUserFirstName {
            welcomeLabel.text = "Hello, \(firstName)!"
        } else {
            welcomeLabel.text = "Hello!"
            print("User first name not found in UserManager.")
        }
    }
    
    //    @IBAction func createNewTripTapped(_ sender: UIButton) {
    //        let vc = storyboard?.instantiateViewController(withIdentifier: "CreateTripViewController") as! CreateTripViewController
    //        navigationController?.pushViewController(vc, animated: true)
    //    }
    
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

