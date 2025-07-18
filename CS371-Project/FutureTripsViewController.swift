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


    // In FutureTripsViewController.swift

    func fetchTrips() {
        let group = DispatchGroup()
        var ownedTrips: [Trip] = []
        var acceptedTrips: [Trip] = []
        
        // 1. Fetch trips the user owns
        group.enter()
        TripManager.shared.fetchUserTrips { result in
            // We only care about future trips from this result
            if case .success(let (futureTrips, _)) = result {
                ownedTrips = futureTrips
            }
            group.leave()
        }
        
        // 2. Fetch trips the user has accepted invites for
        group.enter()
        TripManager.shared.fetchAcceptedInvitations { result in
            // This will tell you if the query failed or just returned empty
            if case .success(let trips) = result {
                acceptedTrips = trips
            }
            group.leave()
        }
        
        // 3. When both are done, combine the results and update the UI
        group.notify(queue: .main) {
            // Combine the two arrays. A dictionary handles any duplicates automatically.
            var combinedTrips = [String: Trip]()
            (ownedTrips + acceptedTrips).forEach { trip in
                combinedTrips[trip.id] = trip
            }
            
            // Filter out any trips that might have ended, sort by date, and reload the table
            let allFutureTrips = Array(combinedTrips.values).filter { !$0.isPastTrip }
            self.trips = allFutureTrips.sorted { $0.startDate < $1.startDate }
            self.tableView.reloadData()
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
        
        cell.travelersLabel.text = "\(trip.travelerUIDs.count) travelers"

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

            // 1. Use Julia's storyboard
            let storyboard = UIStoryboard(name: "Julia", bundle: nil)
            
            // 2. Instantiate MyTripHomeViewController using its Storyboard ID
            if let myTripVC = storyboard.instantiateViewController(withIdentifier: "MyTripHomeViewController") as? MyTripHomeViewController {
                
                // 3. Pass the ENTIRE selected trip object
                myTripVC.trip = selectedTrip
                
                // 4. Push the correct view controller
                self.navigationController?.pushViewController(myTripVC, animated: true)
            }
        }
        return cell
    }
    
   

}
