//
//  MyTripHomeViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

class MyTripHomeViewController: UIViewController {
    
    var trip: Trip?
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let destination = trip?.destination {
            titleLabel.text = "My Trip to \(destination)"
        } else {
            titleLabel.text = "My Trip"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        guard let id = trip?.id else {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toPhotoAlbumVC",
               let destinationVC = segue.destination as? PhotoAlbumViewController {
                destinationVC.tripID = self.trip?.id
            }
        }
    
    @IBAction func goToTravelersTapped(_ sender: UIButton) {
        // 1. Get a reference to the other storyboard.
        let storyboard = UIStoryboard(name: "Ritika", bundle: nil)
        
        // 2. Instantiate the specific view controller using its Storyboard ID.
        //    Make sure the ID matches what you set in the storyboard.
        if let travelerVC = storyboard.instantiateViewController(withIdentifier: "travelersID") as? TravelerViewController {
            print("✅ CHECKPOINT 1: Passing trip to TravelerVC. Travelers count: \(self.trip?.travelers.count ?? -1)")

            // 3. Pass the trip data to the new view controller.
            travelerVC.trip = self.trip
            
            // 4. Present the new view controller.
            //    This assumes you are using a UINavigationController.
            self.navigationController?.pushViewController(travelerVC, animated: true)
            
        } else {
            // This will help you debug if the Storyboard ID is wrong or the class isn't set correctly.
            print("Error: Could not instantiate TravelerViewController from Ritika.storyboard.")
        }
    }
    
    
}
