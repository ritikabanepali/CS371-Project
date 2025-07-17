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
    
    var colorSchemeIsRed: Bool = false
    var notificationsEnabled: Bool = false
    
    private init() {}
    
    private func getUserSettingsDocRef() -> DocumentReference? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("SettingsManager: Error - User not authenticated")
            return nil
        }
        return db.collection("Users").document(userId).collection("settings").document("app_settings")
    }
    
    func loadSettings(completion: @escaping () -> Void) {
        guard let settingsDocRef = getUserSettingsDocRef() else {
            return
        }
        
        settingsDocRef.getDocument { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            
            defer { completion() }
            if let error = error {
                print("SettingsManager: Error fetching user settings: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("SettingsManager: User settings document does not exist, set defaults")
                self.colorSchemeIsRed = false
                self.notificationsEnabled = false
                return
            }
            
            if let data = document.data() {
                self.colorSchemeIsRed = data["colorSchemeIsRed"] as? Bool ?? false
                self.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? false
                print("SettingsManager: User settings loaded from Firestore: Color Scheme is Red: \(self.colorSchemeIsRed), Notifications: \(self.notificationsEnabled)")
            }
        }
    }
    
    func saveUserSettings() {
        guard let settingsDocRef = getUserSettingsDocRef() else { return}
        
        let settingsData: [String: Any] = [
            "colorSchemeIsRed": colorSchemeIsRed,
            "notificationsEnabled": notificationsEnabled
        ]
        
        settingsDocRef.setData(settingsData) { error in
            if let error = error {
                print("SettingsManager: Error saving user settings: \(error.localizedDescription)")
            } else {
                print("SettingsManager: User settings saved to Firestore successfully.")
            }
        }
    }
    
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
