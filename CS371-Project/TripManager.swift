//
//  TripManager.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/13/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// handles invitations that a user receives from the owner of the trip
struct Invitation {
    let id: String
    let tripID: String
    let tripName: String
    let ownerName: String
    let ownerUID: String
    let inviteeUID: String
}

// the Trip object that manages the data of a Trip that a user has
struct Trip {
    let id: String
    let ownerUID: String
    let destination: String
    let startDate: Date
    let endDate: Date
    var travelerUIDs: [String] // people a part of the same trip
    
    var isPastTrip: Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tripEnd = calendar.startOfDay(for: endDate)
        return todayStart > tripEnd
    }
}

class TripManager {
    static let shared = TripManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // creates a new trip and saves it to the current user's 'trips' subcollection in Firestore
    func createTrip(destination: String, startDate: Date, endDate: Date, completion: @escaping (Result<Trip, Error>) -> Void) {
        
        // get the current user's UID from the UserManager
        guard let ownerUID = UserManager.shared.currentUserID else {
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            completion(.failure(error))
            return
        }
        
        // define the path to the user's 'trips' subcollection
        let userTripsCollection = db.collection("Users").document(ownerUID).collection("trips")
        let initialTravelers = [ownerUID] // the owner is automatically a confirmed member of the trip.
        
        // prepare the data to be saved to Firestore.
        let tripData: [String: Any] = [
            "ownerUID": ownerUID,
            "destination": destination,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "travelerUIDs": initialTravelers
        ]
        
        // add a new document to the "trips" collection.
        var ref: DocumentReference? = nil
        ref = userTripsCollection.addDocument(data: tripData) { error in
            if let error = error {
                print("Error creating trip: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let documentID = ref?.documentID {
                print("Trip successfully created with ID: \(documentID)")
                // successful trip creation
                let newTrip = Trip(
                    id: documentID,
                    ownerUID: ownerUID,
                    destination: destination,
                    startDate: startDate,
                    endDate: endDate,
                    travelerUIDs: initialTravelers
                )
                completion(.success(newTrip))
            }
        }
    }
    
    // invites another traveler to an existing trip
    func sendInvitation(toEmail email: String, forTrip trip: Trip, fromUser inviter: String, completion: @escaping (Error?) -> Void) {
        
        // find the traveler the user is inviting
        UserManager.shared.findUser(byEmail: email) { result in
            switch result {
            case .success(let inviteeUID):
                // prepare the data about the trip about to be sent
                let invitationData: [String: Any] = [
                    "tripID": trip.id,
                    "tripName": trip.destination,
                    "ownerUID": trip.ownerUID,
                    "ownerName": inviter,
                    "inviteeUID": inviteeUID,
                    "status": "pending"
                ]
                
                // add the 'invitations' sub collection in firestore
                self.db.collection("invitations").addDocument(data: invitationData) { error in
                    completion(error)
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    // fetches all trips for the currently logged-in user.
    // a closure that returns an array of future trips, an array of past trips, or an error
    func fetchUserTrips(completion: @escaping (Result<([Trip], [Trip]), Error>) -> Void) {
        
        // ensures a user is logged into their account
        guard let userUID = UserManager.shared.currentUserID else {
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            completion(.failure(error))
            return
        }
        
        // path to acess all of the user's trips in Firestore
        let userTripsCollection = db.collection("Users").document(userUID).collection("trips")
        
        // order by date to get them chronologically
        userTripsCollection.order(by: "startDate", descending: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(.success(([], [])))                 // if there are no documents, return empty arrays
                return
            }
            
            var futureTrips: [Trip] = []
            var pastTrips: [Trip] = []
            
            // loop through the documents in Firestore and convert them to Trip objects
            for doc in documents {
                let data = doc.data()
                let id = doc.documentID
                
                let ownerUID = data["ownerUID"] as? String ?? ""
                let destination = data["destination"] as? String ?? "Unknown Destination"
                
                let travelers = data["travelerUIDs"] as? [String] ?? []
                
                // convert Firestore Timestamps back to Swift Dates
                let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
                let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
                
                let trip = Trip(id: id, ownerUID: ownerUID, destination: destination, startDate: startDate, endDate: endDate, travelerUIDs: travelers)
                
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
    
    // deletes a specific trip for the current user
    func deleteTrip(tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        // ensures a user is logged into their account
        guard let userUID = UserManager.shared.currentUserID else {
            print("User not logged in - cannot delete")
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            completion(.failure(error))
            return
        }
        
        // get the trip to be deleted and remove it from Firestore for that user
        let tripRef = db.collection("Users").document(userUID).collection("trips").document(tripID)
        tripRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // removes a user from a specific trip. they will no longer to see this trip on their account
    func removeTraveler(from trip: Trip, userToRemoveUID: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let tripRef = db.collection("Users").document(trip.ownerUID).collection("trips").document(trip.id)
        
        tripRef.updateData([
            "travelerUIDs": FieldValue.arrayRemove([userToRemoveUID])
        ]) { error in
            if let error = error {
                print("Error removing traveler: \(error)")
                completion(error)
            } else {
                print("Traveler removed successfully.")
                completion(nil)
            }
        }
    }
    
    // allows the user to view which trips they have been invited to
    func fetchPendingInvitations(completion: @escaping (Result<[Invitation], Error>) -> Void) {
        
        // get the current user's UID to check theur pending invitations list
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        db.collection("invitations")
            .whereField("inviteeUID", isEqualTo: currentUserID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // get the data from Firestore and get the information ready to display the invitation
                let invitations = querySnapshot?.documents.compactMap { doc -> Invitation? in
                    let data = doc.data()
                    return Invitation(
                        id: doc.documentID,
                        tripID: data["tripID"] as? String ?? "",
                        tripName: data["tripName"] as? String ?? "",
                        ownerName: data["ownerName"] as? String ?? "Someone",
                        ownerUID: data["ownerUID"] as? String ?? "",
                        inviteeUID: data["inviteeUID"] as? String ?? ""
                    )
                } ?? []
                
                completion(.success(invitations))
            }
    }
    
    // the user accepts an invitation, so they are no a part of the trip and can see the trip details
    func acceptInvitation(_ invitation: Invitation, completion: @escaping (Error?) -> Void) {
        let tripRef = db.collection("Users").document(invitation.ownerUID).collection("trips").document(invitation.tripID)
        let invitationRef = db.collection("invitations").document(invitation.id)
        
        // use arrayUnion to add the new traveler's UID to the array
        tripRef.updateData([
            "travelerUIDs": FieldValue.arrayUnion([invitation.inviteeUID])
        ]) { error in
            if let error = error {
                completion(error)
                return
            }
            // delete the invitation since the user has accepted it
            invitationRef.delete(completion: completion)
        }
    }
    
    // delete the invitation since the user does not want to be part of the trip
    func declineInvitation(_ invitation: Invitation, completion: @escaping (Error?) -> Void) {
        db.collection("invitations").document(invitation.id).delete { error in
            completion(error)
        }
    }
    
    // looks for trips where the travelerUIDs array contains the current user's ID, but the ownerUID is not the current user's ID
    // to find trips that the user has been invited and accepted
    func fetchAcceptedInvitations(completion: @escaping (Result<[Trip], Error>) -> Void) {
        
        // ensures a user is logged into their account
        guard let currentUserID = UserManager.shared.currentUserID else {
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            completion(.failure(error))
            return
        }
        
        // finds all trips where the current user is a confirmed traveler but not the owner
        db.collectionGroup("trips")
            .whereField("travelerUIDs", arrayContains: currentUserID)
            .whereField("ownerUID", isNotEqualTo: currentUserID) // Exclude trips you own
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // display the information for the user to see
                let trips = querySnapshot?.documents.compactMap { doc -> Trip? in
                    let data = doc.data()
                    return Trip(
                        id: doc.documentID,
                        ownerUID: data["ownerUID"] as? String ?? "",
                        destination: data["destination"] as? String ?? "Unknown Destination",
                        startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                        endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                        travelerUIDs: data["travelerUIDs"] as? [String] ?? []
                    )
                } ?? []
                
                completion(.success(trips))
            }
    }
    
    // search through the SurveyResponses subcollection in Firestore and returns them as an array of dictionaries
    func fetchSurveyResponses(for trip: Trip, completion: @escaping ([[String: Any]]) -> Void) {
        let db = Firestore.firestore()
        
        // fetch the surveys from Firestore
        let responsesRef = db.collection("Users")
            .document(trip.ownerUID)
            .collection("trips")
            .document(trip.id)
            .collection("surveyResponses")
        
        responsesRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching survey responses: \(error)")
                completion([])
                return
            }
            
            let responses = snapshot?.documents.map { $0.data() } ?? []
            completion(responses)
        }
    }
    
    // retrieves the step count data for every traveler on the trip
    func fetchTravelerSteps(forTrip trip: Trip, completion: @escaping (Result<([String: Int], [String: String]), Error>) -> Void) {
        let travelerStepsCollection = db.collection("Users").document(trip.ownerUID)
            .collection("trips").document(trip.id)
            .collection("travelerSteps")
        
        // get the data from Firestore
        travelerStepsCollection.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("TripManager: Error fetching traveler steps for trip \(trip.id): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("TripManager: No traveler step documents found for trip \(trip.id).")
                completion(.success(([:], [:])))
                return
            }
            
            // get the user's name and step count to display their information from the Trip
            var stepsByUID: [String: Int] = [:]
            var namesByUID: [String: String] = [:]
            
            for document in documents {
                let travelerUID = document.documentID
                let steps = document.data()["totalSteps"] as? Int ?? 0
                let name = document.data()["travelerName"] as? String ?? "Unknown User"
                
                stepsByUID[travelerUID] = steps
                namesByUID[travelerUID] = name
            }
            completion(.success((stepsByUID, namesByUID)))
        }
    }
}
