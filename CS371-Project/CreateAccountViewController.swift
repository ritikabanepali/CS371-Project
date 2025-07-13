//
//  CreateAccountViewController.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/8/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func joinButton(_ sender: Any) {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("One or more fields are empty.")
            return
        }

        // Step 1: Create user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Failed to create user: \(error.localizedDescription)")
                return
            }

            // Step 2: Store additional user info in Firestore
            if let user = authResult?.user {
                let db = Firestore.firestore()
                db.collection("Users").document(user.uid).setData([
                    "FirstName": firstName,
                    "LastName": lastName,
                    "Email": email,
                    "UserID": user.uid
                ]) { err in
                    if let err = err {
                        print("Error writing user data to Firestore: \(err)")
                    } else {
                        print("Successfully saved user info to Firestore.")
                        // Optional: Navigate to another screen
                        // self.performSegue(withIdentifier: "YourNextSegueID", sender: self)
                    }
                }
            }
        }
    }
}
