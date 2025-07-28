//
//  LocationViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/6/25.
//

import UIKit
import MapKit
import CoreLocation

// cells displayed containing the name and distance of a location
class LocationCell: UITableViewCell {
    @IBOutlet var locationNameLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var linkLabel: UILabel!
}

// manages the data for querying different locations a user may want to go to on their trip
class LocationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate,  UITextFieldDelegate {
    
    @IBOutlet weak var locationTitle: UILabel!
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var searchButtonTapped: UIButton!
    @IBOutlet weak var locationTitleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    let cellID = "LocationCell"
    
    var trip: Trip?
    
    private let locationManager = CLLocationManager()
    private var searchResults: [MKMapItem] = []
    private var tripLocation: CLLocation? // stores the trip's destination location
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        setupLocationServices()
        fetchPlaces(query: "attractions") // initailly, query for 'attractions'
        locationTitle.textColor = SettingsManager.shared.titleColor
        
        searchTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    // depending on the user's query, search for locations near the trip destination
    private func fetchPlaces(query: String) {
        guard let trip = trip else {
            print("Error: Trip data is missing.")
            return
        }
        
        self.locationTitleLabel.text = "Finding places in \(trip.destination)..."
        
        let geocoder = CLGeocoder()
        
        // use CoreLocation's CLGeocoder to turn the city name into coordinates
        geocoder.geocodeAddressString(trip.destination) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                self.locationTitleLabel.text = "Could not find destination."
                return
            }
            
            if let placemarkLocation = placemarks?.first?.location {
                self.tripLocation = placemarkLocation // save the location
                self.performSearch(near: placemarkLocation, query: query)
            }
        }
    }
    
    // ensure required permissions are granted for location services
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        // check the current permission status
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization() // request permission
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation() // get location if already authorized
        case .denied, .restricted:
            locationTitleLabel.text = "Please enable location services in Settings."
        @unknown default:
            break
        }
    }
    
    // perform a query for locations dependent upon the  user's search
    private func performSearch(near location: CLLocation, query: String) {
        
        // locations in a 20km radius are valid
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 20000, longitudinalMeters: 20000)
        
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
    
    // get query from text field, ensuring it's not empty
    @IBAction func searchButtonTapped(_ sender: Any) {
        guard let query = searchTextField.text, !query.isEmpty else { return }
        searchTextField.resignFirstResponder()
        fetchPlaces(query: query) // perform the search using the existing function
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // dequeue the cell and cast it to  custom LocationCell class
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! LocationCell
        let mapItem = searchResults[indexPath.row]
        
        // style cell
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.backgroundColor = .white
        cell.contentView.backgroundColor = .clear
        
        // shadow
        cell.contentView.layer.shadowColor = UIColor.black.cgColor
        cell.contentView.layer.shadowOpacity = 0.1
        cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.contentView.layer.shadowRadius = 4
        
        // Access the outlets directly on the cell
        cell.locationNameLabel.text = mapItem.name
        cell.linkLabel.text = mapItem.url?.host ?? "No website available"
        
        // calculate and format the distance
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
        return 100
    }
    
    // open the location in Apple Maps when the cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let mapItem = searchResults[indexPath.row]
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    // called when the user responds to the permission pop-up
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    // only need the location once, so stop updating to save battery
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        tableView.reloadData()
    }
    
    // retrieve the location of the user
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        locationTitleLabel.text = "Could not get your location."
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
