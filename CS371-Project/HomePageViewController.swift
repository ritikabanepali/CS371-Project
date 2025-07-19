//
//  HomePageViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/8/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomePageViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?
    
    @IBOutlet var signinButton: UIButton!
    @IBOutlet var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Check if user is already signed in
    override func viewWillAppear(_ animated: Bool) {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if let user = user {
                UserManager.shared.fetchUserProfile(forUserID: user.uid) {error in
                    if error == nil {
                        // User is already signed in
                        SettingsManager.shared.loadSettings {
                            DispatchQueue.main.async{
                                let storyboard = UIStoryboard(name: "Abha", bundle: nil)
                                if let abhaNavVC = storyboard.instantiateViewController(withIdentifier: "AbhaNavController") as? UINavigationController {
                                    abhaNavVC.modalPresentationStyle = .fullScreen
                                    self?.present(abhaNavVC, animated: true, completion: nil)
                                }
                            }
                            
                        }
                    } else {
                        do {
                            try Auth.auth().signOut()
                        } catch {
                            print("Error signing out")
                        }
                        UserManager.shared.logoutUserData()
                    }
                }
                
            }
        }
    }
    
}
