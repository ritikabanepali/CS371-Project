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
    @IBOutlet var uiView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Style for the view's background and corners
        uiView.backgroundColor = .white
        uiView.layer.cornerRadius = 12
        
        // Style for the shadow
        uiView.layer.shadowColor = UIColor.black.cgColor
        uiView.layer.shadowOpacity = 0.1
        uiView.layer.shadowOffset = CGSize(width: 0, height: 2)
        uiView.layer.shadowRadius = 4
    }
    
    @IBAction func joinButton(_ sender: Any) {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            return
        }
        
        // making sure the password set is long enough
        if password.count < 7 {
            let alert = UIAlertController(title: "Password Too Short", message: "Password must be at least 7 characters.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        // Create user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            guard error == nil else { return }
            
            // Store additional user info in Firestore
            if let user = authResult?.user {
                let db = Firestore.firestore()
                db.collection("Users").document(user.uid).setData([
                    "FirstName": firstName,
                    "LastName": lastName,
                    "Email": email,
                    "UserID": user.uid
                ]) { err in
                    if err == nil {
                        UserManager.shared.setUserData(uid: user.uid, firstName: firstName, lastName: lastName, email: email)
                    }
                }
            }
        }
    }
}
