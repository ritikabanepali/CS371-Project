//
//  SignInViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/8/25.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    var handle: AuthStateDidChangeListenerHandle?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Add Firebase listener to react to successful login
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if user != nil {
                // Present the home screen if login succeeds
                let storyboard = UIStoryboard(name: "Abha", bundle: nil)
                if let abhaNavVC = storyboard.instantiateViewController(withIdentifier: "AbhaNavController") as? UINavigationController {
                    abhaNavVC.modalPresentationStyle = .fullScreen
                    self?.present(abhaNavVC, animated: true, completion: nil)
                }
            }
        }
    }


    @IBAction func signinButton(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error as NSError? {
                let errorMessage: String

                switch AuthErrorCode(rawValue: error.code) {
                case .invalidEmail:
                    errorMessage = "Invalid email address."
                case .userNotFound:
                    errorMessage = "No account found with this email."
                case .wrongPassword:
                    errorMessage = "Incorrect password."
                default:
                    errorMessage = error.localizedDescription
                }

                self?.showAlert(message: "Sign in failed: \(errorMessage)")
                return
            }

            // Do nothing here — listener will detect successful login and handle transition
        }
    }

    @IBAction func needAccountButton(_ sender: Any) {
        performSegue(withIdentifier: "CreateAccountPageSegue", sender: self)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Sign In Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
