//
//  MyTripHomeViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

class MyTripHomeViewController: UIViewController {
    
    var tripDestination: String?
    
    @IBOutlet weak var titleLabel: UILabel! // connect this to your "My Trip" UILabel in storyboard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let destination = tripDestination {
            titleLabel.text = "My Trip to \(destination)"
        } else {
            titleLabel.text = "My Trip"
        }
    }
}
