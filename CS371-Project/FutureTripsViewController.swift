//
//  FutureTripsViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit

class FutureTripsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var trips: [Trip] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTrips()
    }


    func fetchTrips() {
        TripManager.shared.fetchUserTrips { result in
            switch result {
            case .success(let (futureTrips, _)):
                self.trips = futureTrips
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching trips:", error.localizedDescription)
            }
        }
    }

    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let trip = trips[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCellID", for: indexPath) as! TripCell

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        cell.destinationLabel.text = trip.destination
        cell.dateLabel.text = "\(formatter.string(from: trip.startDate)) → \(formatter.string(from: trip.endDate))"
        
        cell.travelersLabel.text = "\(trip.travelers.count) travelers"

        // Style cell
        cell.containerView.layer.cornerRadius = 12
        cell.containerView.backgroundColor = .white
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none

        // Shadow
        cell.containerView.layer.shadowColor = UIColor.black.cgColor
        cell.containerView.layer.shadowOpacity = 0.1
        cell.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.containerView.layer.shadowRadius = 4

        cell.onOpenTripTapped = { [weak self] in
            guard let self = self else { return }
            let selectedTrip = self.trips[indexPath.row]

            let storyboard = UIStoryboard(name: "Julia", bundle: nil)
            if let myTripVC = storyboard.instantiateViewController(withIdentifier: "MyTripHomeViewController") as? MyTripHomeViewController {
                myTripVC.tripDestination = selectedTrip.destination
                myTripVC.tripID = selectedTrip.id
                self.navigationController?.pushViewController(myTripVC, animated: true)
            }
        }
        return cell
    }

    // MARK: - TableView Delegate



    // MARK: - Prepare for Segue

}
