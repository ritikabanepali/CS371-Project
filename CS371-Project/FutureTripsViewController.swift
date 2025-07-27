//
//  FutureTripsViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit
import FirebaseFirestore

class FutureTripsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var upcomingTripsTitleLabel: UILabel!
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
        upcomingTripsTitleLabel.textColor = SettingsManager.shared.titleColor
    }
    
    func fetchTrips() {
        let group = DispatchGroup()
        var ownedTrips: [Trip] = []
        var acceptedTrips: [Trip] = []
        
        // Fetch trips the user owns
        group.enter()
        TripManager.shared.fetchUserTrips { result in
            if case .success(let (futureTrips, _)) = result {
                ownedTrips = futureTrips
            }
            group.leave()
        }
        
        // Fetch trips the user has accepted invites for
        group.enter()
        TripManager.shared.fetchAcceptedInvitations { result in
            if case .success(let trips) = result {
                acceptedTrips = trips
            }
            group.leave()
        }
        
        // Combine the results of the two fetch methods and update the UI
        group.notify(queue: .main) {
            // Combine the two arrays
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
        
        //cell ui details
        cell.containerView.layer.cornerRadius = 12
        cell.containerView.backgroundColor = .white
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        
        cell.containerView.layer.shadowColor = UIColor.black.cgColor
        cell.containerView.layer.shadowOpacity = 0.1
        cell.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.containerView.layer.shadowRadius = 4
        
        cell.updateButtonColor()
        
        //move to selected trip
        cell.onOpenTripTapped = { [weak self] in
            guard let self = self else { return }
            let selectedTrip = self.trips[indexPath.row]
            
            let storyboard = UIStoryboard(name: "Julia", bundle: nil)
            if let myTripVC = storyboard.instantiateViewController(withIdentifier: "MyTripHomeViewController") as? MyTripHomeViewController {
                myTripVC.trip = selectedTrip
                self.navigationController?.pushViewController(myTripVC, animated: true)
            }
        }
        return cell
    }
    
    
    
}
