//
//  TripManager.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/13/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// The Trip object that manages the data of a Trip that a user has
struct Trip {
    let id: String // The document ID from Firestore
    let ownerUID: String
    let destination: String
    let startDate: Date
    let endDate: Date
    var travelers: [String: String] // travelers a part of a trip
    
    var isPastTrip: Bool {
        return Date() > endDate
    }
}

class TripManager {
    static let shared = TripManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // creates a new trip and saves it to the current user's "trips" subcollection in Firestore.
    func createTrip(destination: String, startDate: Date, endDate: Date, completion: @escaping (Result<Trip, Error>) -> Void) {
        
        // Get the current user's UID from UserManager.
        guard let ownerUID = UserManager.shared.currentUserID else {
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            completion(.failure(error))
            return
        }
        
        // define the path to the user's "trips" subcollection.
        let userTripsCollection = db.collection("Users").document(ownerUID).collection("trips")
        
        // the owner is automatically a "confirmed" member of the trip.
        let initialTravelers = [ownerUID: "confirmed"]
        
        // prepare the data to be saved to Firestore.
        let tripData: [String: Any] = [
            "ownerUID": ownerUID,
            "destination": destination,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "travelers": initialTravelers
        ]
        
        // add a new document to the "trips" collection.
        var ref: DocumentReference? = nil
        ref = userTripsCollection.addDocument(data: tripData) { error in
            if let error = error {
                print("Error creating trip: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let documentID = ref?.documentID {
                print("Trip successfully created with ID: \(documentID)")
                // create a Trip object to return on success
                let newTrip = Trip(
                    id: documentID,
                    ownerUID: ownerUID,
                    destination: destination,
                    startDate: startDate,
                    endDate: endDate,
                    travelers: initialTravelers
                )
                completion(.success(newTrip))
            }
        }
    }
    
    // invites another traveler to an existing trip
    func inviteTraveler(withEmail email: String, to trip: Trip, completion: @escaping (Error?) -> Void) {
        // find the user's UID from their email
        UserManager.shared.findUser(byEmail: email) { result in
            switch result {
            case .success(let newTravelerUID):
                // get a reference to the trip document
                let tripRef = self.db.collection("Users").document(trip.ownerUID).collection("trips").document(trip.id)
                
                //  update the travelers map by adding the new user with "pending" status
                tripRef.updateData([
                    "travelers.\(newTravelerUID)": "pending"
                ]) { error in
                    completion(error)
                }
                
            case .failure(let error):
                // The user wasn't found or another error occurred
                completion(error)
            }
        }
    }
    
    // fetches all trips for the currently logged-in user.
    // A closure that returns an array of future trips, an array of past trips, or an error.
    func fetchUserTrips(completion: @escaping (Result<([Trip], [Trip]), Error>) -> Void) {
        guard let userUID = UserManager.shared.currentUserID else {
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            completion(.failure(error))
            return
        }
        
        let userTripsCollection = db.collection("Users").document(userUID).collection("trips")
        
        // order by date to get them chronologically
        userTripsCollection.order(by: "startDate", descending: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                // if there are no documents, return empty arrays
                completion(.success(([], [])))
                return
            }
            
            var futureTrips: [Trip] = []
            var pastTrips: [Trip] = []
            
            // loop through the documents and convert them to Trip objects
            for doc in documents {
                let data = doc.data()
                let id = doc.documentID
                
                let ownerUID = data["ownerUID"] as? String ?? ""
                let destination = data["destination"] as? String ?? "Unknown Destination"
                
                let travelers = data["travelers"] as? [String: String] ?? [:]
                
                // convert Firestore Timestamps back to Swift Dates
                let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
                let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
                
                let trip = Trip(id: id, ownerUID: ownerUID, destination: destination, startDate: startDate, endDate: endDate, travelers: travelers)
                
                // sort the trip into the correct array
                if trip.isPastTrip {
                    pastTrips.append(trip)
                } else {
                    futureTrips.append(trip)
                }
            }
            completion(.success((futureTrips, pastTrips)))
        }
    }
    
}
