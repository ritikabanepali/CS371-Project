//
//  PastTripsViewController.swift
//  CS371-Project
//
//

import UIKit

class PastTripsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func viewFranceWrappedTapped(_ sender: UIButton) {
        print("France trip wrapped tapped")
        // Future: navigate to trip summary screen
    }

    @IBAction func viewThailandWrappedTapped(_ sender: UIButton) {
        print("Thailand trip wrapped tapped")
        // Future: navigate to trip summary screen
    }
}

