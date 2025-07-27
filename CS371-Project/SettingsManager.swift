//
//  SettingsManager.swift
//  CS371-Project
//
//  Created by Suhani Goswami on 7/17/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

class SettingsManager {
    static let shared = SettingsManager()
    private let db = Firestore.firestore()
    
    //properties managed in settings
    var colorSchemeIsRed: Bool = false
    var notificationsEnabled: Bool = false
    
    private init() {}
    
    //creates a reference to firestore
    private func getUserSettingsDocRef() -> DocumentReference? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("Users").document(userId).collection("settings").document("app_settings")
    }
    
    //load stored settings from firestore
    func loadSettings(completion: @escaping () -> Void) {
        guard let settingsDocRef = getUserSettingsDocRef() else {
            return
        }
        
        settingsDocRef.getDocument { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            //error
            defer { completion() }
            if error != nil {
                print("error getting user settings")
                return
            }
            
            //no settings saved yet
            guard let document = documentSnapshot, document.exists else {
                print("document does not exist yet, set default settings")
                self.colorSchemeIsRed = false
                self.notificationsEnabled = false
                return
            }
            
            //restore saved settings
            if let data = document.data() {
                self.colorSchemeIsRed = data["colorSchemeIsRed"] as? Bool ?? false
                self.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? false
            }
        }
    }
    
    //save user settings to firestore
    func saveUserSettings() {
        guard let settingsDocRef = getUserSettingsDocRef() else { return}
        
        let settingsData: [String: Any] = [
            "colorSchemeIsRed": colorSchemeIsRed,
            "notificationsEnabled": notificationsEnabled
        ]
        
        settingsDocRef.setData(settingsData) { error in
            if error != nil {
                print("did not save to firestore")
            } else {
                print("saved to firestore")
            }
        }
    }
    
    //titleColor and buttonColor are saved colors to be used in all app screens
    
    var titleColor: UIColor {
        if colorSchemeIsRed {
            return UIColor(red: 187/255.0, green: 75/255.0, blue: 75/255.0, alpha: 1.0)
        } else {
            return UIColor(red: 66/255.0, green: 107/255.0, blue: 31/255.0, alpha: 1.0)
        }
    }
    
    var buttonColor: UIColor {
        if colorSchemeIsRed {
            return UIColor(red: 241/255.0, green: 138/255.0, blue: 20/255.0, alpha: 1.0)
        } else {
            return UIColor(red: 181/255.0, green: 216/255.0, blue: 237/255.0, alpha: 1.0)
        }
    }
}
