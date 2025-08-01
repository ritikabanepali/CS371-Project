//
//  SignInViewController.swift
//  CS371-Project
//
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet var uiView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uiView.backgroundColor = .white
        uiView.layer.cornerRadius = 12
        uiView.layer.shadowColor = UIColor.black.cgColor
        uiView.layer.shadowOpacity = 0.1
        uiView.layer.shadowOffset = CGSize(width: 0, height: 2)
        uiView.layer.shadowRadius = 4
        
        // Dismiss keyboard when tapping outside
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            view.addGestureRecognizer(tapGesture)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func signinButton(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter both email and password.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            //  check for a sign-in error from Firebase
            if let error = error {
                self?.showAlert(title: "Sign In Error", message: error.localizedDescription)
                return
            }
            
            guard let user = authResult?.user else {
                self?.showAlert(title: "Sign In Error", message: "Could not find user data after sign in.")
                return
            }
            
            //  sign-in is confirmed, fetch the user's profile from Firestore
            UserManager.shared.fetchUserProfile(forUserID: user.uid) { error in
                
                if error != nil {
                    // if we can't get their profile, show an error and sign them out
                    self?.showAlert(title: "Error", message: "Signed in, but could not fetch your profile. Please try again.")
                    try? Auth.auth().signOut() // Sign out to be safe
                    return
                }
                
                // both sign-in and profile fetch worked. Go to the main app.
                // do UI changes on the main thread.
                DispatchQueue.main.async {
                    self?.goToMainApp()
                }
            }
        }
    }
    
    func goToMainApp() {
        let storyboard = UIStoryboard(name: "Abha", bundle: nil)
        if let abhaNavVC = storyboard.instantiateViewController(withIdentifier: "AbhaNavController") as? UINavigationController {
            abhaNavVC.modalPresentationStyle = .fullScreen
            self.present(abhaNavVC, animated: true, completion: nil)
        }
    }
    
    func showAlert(title: String, message: String) {
        // make sure we are on the main thread before presenting an alert
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
