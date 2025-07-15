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
        TripManager.shared.fetchUserTrips { result in
            switch result {
            case .success(let (_, pastTrips)): 
                self.trips = pastTrips
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching trips:", error.localizedDescription)
            }
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
        cell.travelersLabel.text = "\(trip.travelers.count) travelers"


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
