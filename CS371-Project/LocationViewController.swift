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
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var linkLabel: UILabel!
}

class LocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    let cellID = "LocationCell"
    
    var trip: Trip?
    
    private let locationManager = CLLocationManager()
    private var searchResults: [MKMapItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setupLocationServices()

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
        self.locationTitleLabel.text = "Finding places near you..."

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000) // Search in a 10km (approx. 6 mile) radius

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
                self.locationTitleLabel.text = "Showing results for '\(query)'"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue the cell and cast it to your custom LocationCell class
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! LocationCell
        let mapItem = searchResults[indexPath.row]
        
        // Access the outlets directly on the cell
        cell.locationNameLabel.text = mapItem.name
        cell.activityLabel.text = mapItem.pointOfInterestCategory?.rawValue ?? "Place of Interest"
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
        guard let currentLocation = locations.first else { return }
        
        // We only need the location once, so stop updating to save battery
        manager.stopUpdatingLocation()
        
        // Once we have the location, perform the search
        performSearch(near: currentLocation, query: "attractions")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        locationTitleLabel.text = "Could not get your location."
    }
    
}
