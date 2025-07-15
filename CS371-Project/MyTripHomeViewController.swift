//
//  MyTripHomeViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

class MyTripHomeViewController: UIViewController {
    
    var tripDestination: String?
    var tripID: String?
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let destination = tripDestination {
            titleLabel.text = "My Trip to \(destination)"
        } else {
            titleLabel.text = "My Trip"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let destination = tripDestination {
            titleLabel.text = "My Trip to \(destination)"
        } else {
            titleLabel.text = "My Trip"
        }
    }
    
    @IBAction func deleteTripTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Trip", message: "Are you sure you want to delete this trip?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performTripDeletion()
        })
        
        present(alert, animated: true)
    }
    
    private func performTripDeletion() {
        guard let id = tripID else {
            print("Missing trip ID")
            return
        }

        print("Attempting to delete trip with ID: \(id)")

        TripManager.shared.deleteTrip(tripID: id) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    print("Trip deleted successfully")
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    print("Deletion failed: \(error.localizedDescription)")
                    self?.showAlert(title: "Error", message: "Could not delete trip: \(error.localizedDescription)")
                }
            }
        }
    }

    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    
}
