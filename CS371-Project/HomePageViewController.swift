//
//  HomePageViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/8/25.
//

import UIKit
import FirebaseAuth


class HomePageViewController: UIViewController {
    var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    // Do any additional setup after loading the view.
    // Check if user is already signed in
    override func viewWillAppear(_ animated: Bool) {
        
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if user != nil {
                // User is already signed in — present the next screen
                let storyboard = UIStoryboard(name: "Abha", bundle: nil)
                if let abhaNavVC = storyboard.instantiateViewController(withIdentifier: "AbhaNavController") as? UINavigationController {
                    abhaNavVC.modalPresentationStyle = .fullScreen
                    self?.present(abhaNavVC, animated: true, completion: nil)
                }
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
