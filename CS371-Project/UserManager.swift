//
//  UserManager.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/13/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserManager {
    static let shared = UserManager()
    private let db = Firestore.firestore()
    
    // Always reflects currently logged-in user
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var currentUserFirstName: String?
    var currentUserLastName: String?
    var currentUserEmail: String?
    
    private init() {}
    
    func setUserData(uid: String, firstName: String, lastName: String, email: String) {
        self.currentUserFirstName = firstName
        self.currentUserLastName = lastName
        self.currentUserEmail = email
    }
    
    func logoutUserData() {
        self.currentUserFirstName = nil
        self.currentUserLastName = nil
        self.currentUserEmail = nil
    }
    
    
    func fetchUserProfile(forUserID uid: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        db.collection("Users").document(uid).getDocument { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user profile from Firestore: \(error.localizedDescription)")
                self.logoutUserData()
                completion(error)
                return
            }
            
            if let document = documentSnapshot, document.exists {
                let data = document.data()
                self.setUserData(
                    uid: uid,
                    firstName: data?["FirstName"] as? String ?? "",
                    lastName: data?["LastName"] as? String ?? "",
                    email: data?["Email"] as? String ?? ""
                )
                print("UserManager: User profile successfully fetched and set.")
                completion(nil)
            } else {
                print("UserManager: User document does not exist for UID: \(uid)")
                self.logoutUserData()
                completion(NSError(domain: "UserManagerError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found."]))
            }
        }
    }
    
    // find a user's id by searching their email
    func findUser(byEmail email: String, completion: @escaping (Result<String, Error>) -> Void) {
        // query the firestore data base in lowercasew
        db.collection("Users").whereField("Email", isEqualTo: email.lowercased()).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                let notFoundError = NSError(domain: "UserManagerError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User with that email not found."])
                completion(.failure(notFoundError))
                return
            }
            
            // return the UID of the found user
            completion(.success(document.documentID))
        }
    }
    
    func fetchName(forUserWithUID uid: String, completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("Users").document(uid).getDocument { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data(),
                  let firstName = data["FirstName"] as? String,
                  let lastName = data["Lastname"] as? String else {
                let notFoundError = NSError(domain: "UserManagerError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User name not found for UID \(uid)."])
                completion(.failure(notFoundError))
                return
                
            }
            let fullName = "\(firstName) \(lastName)"
            completion(.success(fullName))
        }
        
    }
