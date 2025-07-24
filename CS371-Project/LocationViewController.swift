//
//  LocationViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/6/25.
//

import UIKit
import MapKit
import CoreLocation

class LocationCell: UITableViewCell {
    // These outlets will be connected to the labels in your storyboard cell
    @IBOutlet var locationNameLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var linkLabel: UILabel!
}

class LocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var searchTextField: UITextField!
    
    @IBOutlet var searchButtonTapped: UIButton!
    
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    let cellID = "LocationCell"
    
    var trip: Trip?
    
    private let locationManager = CLLocationManager()
    private var searchResults: [MKMapItem] = []
    private var tripLocation: CLLocation? // To store the destination's location
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setupLocationServices()
        fetchPlaces(query: "attractions")

    }
    
    
    private func fetchPlaces(query: String) {
          guard let trip = trip else {
              print("Error: Trip data is missing.")
              return
          }

          self.locationTitleLabel.text = "Finding places in \(trip.destination)..."
          
          let geocoder = CLGeocoder()
          
          // Use CoreLocation's CLGeocoder to turn the city name into coordinates
          geocoder.geocodeAddressString(trip.destination) { [weak self] (placemarks, error) in
              guard let self = self else { return }
              
              if let error = error {
                  print("Geocoding error: \(error.localizedDescription)")
                  self.locationTitleLabel.text = "Could not find destination."
                  return
              }
              
              if let placemarkLocation = placemarks?.first?.location {
                  self.tripLocation = placemarkLocation // Save the location
                  self.performSearch(near: placemarkLocation, query: query)
              }
          }
      }
    
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        // Check the current permission status
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization() // Request permission
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation() // Get location if already authorized
        case .denied, .restricted:
            locationTitleLabel.text = "Please enable location services in Settings."
        @unknown default:
            break
        }
    }
    
    private func performSearch(near location: CLLocation, query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 20000, longitudinalMeters: 20000) // Search in a 20km radius

        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.locationTitleLabel.text = "Search failed."
                    print("Local search error: \(error.localizedDescription)")
                    return
                }
                
                self.searchResults = response?.mapItems ?? []
                self.tableView.reloadData()
                self.locationTitleLabel.text = "Showing results for '\(query)' in \(self.trip?.destination ?? "")"
            }
        }
    }
    

    @IBAction func searchButtonTapped(_ sender: Any) {
        // Get query from text field, ensuring it's not empty
        guard let query = searchTextField.text, !query.isEmpty else { return }
        
        // Hide the keyboard
        searchTextField.resignFirstResponder()
        
        // Perform the search using the existing function
        fetchPlaces(query: query)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue the cell and cast it to your custom LocationCell class
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! LocationCell
        let mapItem = searchResults[indexPath.row]
        
        // Style cell
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.backgroundColor = .white
        cell.contentView.backgroundColor = .clear
        
        // Shadow
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOpacity = 0.1
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.contentView.layer.shadowRadius = 4
        
        // Access the outlets directly on the cell
        cell.locationNameLabel.text = mapItem.name
        cell.linkLabel.text = mapItem.url?.host ?? "No website available"
        
        // Calculate and format the distance
        if let userLocation = locationManager.location, let placeLocation = mapItem.placemark.location {
            let distanceInMeters = userLocation.distance(from: placeLocation)
            let distanceInMiles = distanceInMeters * 0.000621371 // Conversion to miles
            cell.distanceLabel.text = String(format: "%.1f miles away", distanceInMiles)
        } else {
            cell.distanceLabel.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return a fixed height that fits all your labels.
        // You can adjust this value to match your design.
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let mapItem = searchResults[indexPath.row]
        
        // Open the location in Apple Maps when the cell is tapped
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // This is called when the user responds to the permission pop-up
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        // We only need the location once, so stop updating to save battery
        tableView.reloadData()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        locationTitleLabel.text = "Could not get your location."
    }
    
}
