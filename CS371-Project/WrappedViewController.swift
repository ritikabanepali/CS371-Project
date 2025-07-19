//
//  WrappedViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/14/25.
//

import UIKit
import FirebaseFirestore

class WrappedViewController: UIViewController {
    var selectedTrip: Trip?
    var tripDestination: String?
    
    @IBOutlet weak var wrappedTitle: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTitle()
    }
    
    func setTitle(){
        if let destination = tripDestination {
            wrappedTitle.text = "\(destination)"
        }
        wrappedTitle.adjustsFontSizeToFitWidth = true
        wrappedTitle.minimumScaleFactor = 0.5
        wrappedTitle.textColor = SettingsManager.shared.titleColor
    }
}
