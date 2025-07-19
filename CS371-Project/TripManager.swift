//
//  TripManager.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/13/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// handles invitations that a user receives
struct Invitation {
    let id: String
    let tripID: String
    let tripName: String
    let ownerName: String
    let ownerUID: String
    let inviteeUID: String
}

// The Trip object that manages the data of a Trip that a user has
// Change this struct
struct Trip {
    let id: String
    let ownerUID: String
    let destination: String
    let startDate: Date
    let endDate: Date
    var travelerUIDs: [String]

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
        let initialTravelers = [ownerUID]
        
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
                // create a Trip object to return on success
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
        // 1. Find the user being invited
        UserManager.shared.findUser(byEmail: email) { result in
            switch result {
            case .success(let inviteeUID):
                // 2. Prepare the invitation data
                let invitationData: [String: Any] = [
                    "tripID": trip.id,
                    "tripName": trip.destination,
                    "ownerUID": trip.ownerUID,
                    "ownerName": inviter,
                    "inviteeUID": inviteeUID,
                    "status": "pending"
                ]
                
                // 3. Add a new document to the "invitations" collection
                self.db.collection("invitations").addDocument(data: invitationData) { error in
                    completion(error)
                }
            case .failure(let error):
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
    
    // Deletes a specific trip for the current user
    func deleteTrip(tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userUID = UserManager.shared.currentUserID else {
            print("User not logged in - cannot delete")
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not logged in."])
            completion(.failure(error))
            return
        }
        print("Deleting from path: Users/\(userUID)/trips/\(tripID)")
        
        
        let tripRef = db.collection("Users").document(userUID).collection("trips").document(tripID)
        tripRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
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

    
    func fetchPendingInvitations(completion: @escaping (Result<[Invitation], Error>) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else { return }
        
        db.collection("invitations")
          .whereField("inviteeUID", isEqualTo: currentUserID)
          .whereField("status", isEqualTo: "pending")
          .getDocuments { (querySnapshot, error) in
              if let error = error {
                  completion(.failure(error))
                  return
              }
              
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
    
    func acceptInvitation(_ invitation: Invitation, completion: @escaping (Error?) -> Void) {
        let tripRef = db.collection("Users").document(invitation.ownerUID).collection("trips").document(invitation.tripID)
        let invitationRef = db.collection("invitations").document(invitation.id)

        // Use arrayUnion to add the new traveler's UID to the array
        tripRef.updateData([
            "travelerUIDs": FieldValue.arrayUnion([invitation.inviteeUID])
        ]) { error in
            if let error = error {
                completion(error)
                return
            }
            // Step 2: Delete the invitation document
            invitationRef.delete(completion: completion)
        }
    }
    

    func declineInvitation(_ invitation: Invitation, completion: @escaping (Error?) -> Void) {
        // Just delete the invitation document
        db.collection("invitations").document(invitation.id).delete { error in
            completion(error)
        }
    }


    func fetchAcceptedInvitations(completion: @escaping (Result<[Trip], Error>) -> Void) {
        guard let currentUserID = UserManager.shared.currentUserID else {
            let error = NSError(domain: "TripManagerError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in."])
            completion(.failure(error))
            return
        }
        
        // This query is inefficient for a large user base, but will work for your project.
        // It finds all trips where the current user is a confirmed traveler but not the owner.
        db.collectionGroup("trips")
            .whereField("travelerUIDs", arrayContains: currentUserID)
          .whereField("ownerUID", isNotEqualTo: currentUserID) // Exclude trips you own
          .getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

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
    
    func fetchSurveyResponses(for trip: Trip, completion: @escaping ([[String: Any]]) -> Void) {
        let db = Firestore.firestore()
        
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
    
    func fetchTravelerSteps(forTrip trip: Trip, completion: @escaping (Result<([String: Int], [String: String]), Error>) -> Void) {
        let travelerStepsCollection = db.collection("Users").document(trip.ownerUID)
                                          .collection("trips").document(trip.id)
                                          .collection("travelerSteps")

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
