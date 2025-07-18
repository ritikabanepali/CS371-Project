//
//  PastTripsViewController.swift
//  CS371-Project
//

import UIKit

class PastTripsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

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
    }


    func fetchTrips() {
        let group = DispatchGroup()
        var ownedPastTrips: [Trip] = []
        var acceptedTrips: [Trip] = []

        // 1. Fetch trips the user owns
        group.enter()
        TripManager.shared.fetchUserTrips { result in
            // The change is here: We use the 'pastTrips' array from the result
            if case .success(let (_, pastTrips)) = result {
                ownedPastTrips = pastTrips
            }
            group.leave()
        }

        // 2. Fetch trips the user has accepted invites for
        group.enter()
        TripManager.shared.fetchAcceptedInvitations { result in
            if case .success(let trips) = result {
                acceptedTrips = trips
            }
            group.leave()
        }

        // 3. When both are done, combine, filter, and update the UI
        group.notify(queue: .main) {
            // Combine the two arrays using a dictionary to prevent duplicates
            var combinedTrips = [String: Trip]()
            (ownedPastTrips + acceptedTrips).forEach { trip in
                combinedTrips[trip.id] = trip
            }

            // Filter the combined list to ensure we only have past trips
            let allPastTrips = Array(combinedTrips.values).filter { $0.isPastTrip }

            // Sort by end date to show the most recently-ended trip first
            self.trips = allPastTrips.sorted { $0.endDate > $1.endDate }
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
