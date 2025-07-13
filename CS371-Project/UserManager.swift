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

    // global data to use
    var currentUserID: String?
    var currentUserFirstName: String?
    var currentUserLastName: String?
    var currentUserEmail: String?
    
    private init(){}
    
    // setting user data from firestore to be used in homepage/create
    func setUserData(uid: String, firstName: String, lastName: String, email: String) {
        self.currentUserID = uid
        self.currentUserFirstName = firstName
        self.currentUserLastName = lastName
        self.currentUserEmail = email
    }
    
    // remove set user data when logout is pressed
    func logoutUserData(){
        self.currentUserID = nil
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
}

