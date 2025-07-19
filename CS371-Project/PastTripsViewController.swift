//
//  PastTripsViewController.swift
//  CS371-Project
//

import UIKit
import FirebaseFirestore

class PastTripsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var pastTripsTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var trips: [Trip] = []
    var selectedTripHere: Trip?
    
    @IBAction func buttonTapped(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        let index = button.tag
        selectedTripHere = trips[index]
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchTrips()
        pastTripsTitle.textColor = SettingsManager.shared.titleColor
    }
    
    
    func fetchTrips() {
        let group = DispatchGroup()
        var ownedPastTrips: [Trip] = []
        var acceptedPastTrips: [Trip] = [] // Renamed for clarity
        
        // 1. Fetch owned trips (this part is unchanged)
        group.enter()
        TripManager.shared.fetchUserTrips { result in
            if case .success(let (_, pastTrips)) = result {
                ownedPastTrips = pastTrips
            }
            group.leave()
        }
        
        // 2. Fetch accepted trips (this part is now simpler)
        group.enter()
        TripManager.shared.fetchAcceptedInvitations { result in
            // Now you can directly get the past trips from the result
            if case .success(let (_, pastTrips)) = result {
                acceptedPastTrips = pastTrips
            }
            group.leave()
        }
        
        // 3. Combine and update the UI (this part is now more efficient)
        group.notify(queue: .main) {
            // Combine the two arrays of ALREADY-FILTERED past trips
            var combinedTrips = [String: Trip]()
            (ownedPastTrips + acceptedPastTrips).forEach { trip in
                combinedTrips[trip.id] = trip
            }
            
            // No need to filter again, just sort and reload
            self.trips = Array(combinedTrips.values).sorted { $0.endDate > $1.endDate }
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
        
        
        cell.containerView.layer.cornerRadius = 17
        cell.containerView.backgroundColor = .white
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        
        cell.containerView.layer.shadowColor = UIColor.black.cgColor
        cell.containerView.layer.shadowOpacity = 0.2
        cell.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.containerView.layer.shadowRadius = 5
        cell.myButton.tag = indexPath.row
        
        var myButtonConfig = cell.myButton.configuration ?? .filled()
        myButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        cell.myButton.configuration = myButtonConfig
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toWrappedVC",
           let destinationVC = segue.destination as? WrappedViewController,
           let trip = selectedTripHere {
            destinationVC.tripDestination = trip.destination
            destinationVC.selectedTrip = selectedTripHere
        }
    }
    
}
