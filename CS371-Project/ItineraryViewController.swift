// ItineraryViewController.swift
// Adds permissions: only trip owner can generate/save/clear itinerary,
// and only after all invited travelers have submitted surveys. Now uses Firestore with live syncing.

import UIKit
import FirebaseFirestore

class ItineraryViewController: UIViewController {
    var currentTrip: Trip!

    @IBOutlet weak var itineraryTextView: UITextView!
    @IBOutlet weak var itineraryTitleLabel: UILabel!
    @IBOutlet weak var moreLocationsButton: UIButton!
    @IBOutlet weak var itineraryDatesLabel: UILabel!
    @IBOutlet weak var saveItineraryButton: UIButton!
    @IBOutlet weak var clearItineraryButton: UIButton!
    @IBOutlet weak var regenerateItineraryButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let trip = currentTrip else {
            print("No trip passed to itinerary generator")
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        applyColorScheme()
        
        itineraryTitleLabel.text = "Your Itinerary To \(trip.destination)"
        itineraryDatesLabel.text = "\(formatter.string(from: trip.startDate)) – \(formatter.string(from: trip.endDate))"

        let isOwner = isCurrentUserTripOwner()
        saveItineraryButton.isHidden = !isOwner
        clearItineraryButton.isHidden = !isOwner
        regenerateItineraryButton.isHidden = !isOwner

        if isOwner {
            allSurveysSubmitted { allDone in
                DispatchQueue.main.async {
                    let enable = allDone
                    self.saveItineraryButton.isEnabled = enable
                    self.clearItineraryButton.isEnabled = enable
                    self.regenerateItineraryButton.isEnabled = enable
                    if !enable {
                        self.showAlert(title: "Wait", message: "All travelers must complete the survey before generating an itinerary.")
                    }
                }
            }
        }

        observeItineraryUpdates()

        itineraryTextView.isEditable = false
        itineraryTextView.isSelectable = true
        itineraryTextView.dataDetectorTypes = [.link]
    }
    
    func applyColorScheme(){
        itineraryTitleLabel.textColor = SettingsManager.shared.titleColor
        
        var moreLocationsButtonConfig = moreLocationsButton.configuration ?? .filled()
        moreLocationsButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        moreLocationsButton.configuration = moreLocationsButtonConfig
        
        var saveItineraryButtonConfig = saveItineraryButton.configuration ?? .filled()
        saveItineraryButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        saveItineraryButton.configuration = saveItineraryButtonConfig
        
        var clearItineraryButtonConfig = clearItineraryButton.configuration ?? .filled()
        clearItineraryButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        clearItineraryButton.configuration = clearItineraryButtonConfig
        
        var regenerateItineraryButtonConfig = regenerateItineraryButton.configuration ?? .filled()
        regenerateItineraryButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        regenerateItineraryButton.configuration = regenerateItineraryButtonConfig
    }

    
    func observeItineraryUpdates() {
        let docRef = Firestore.firestore().collection("itineraries").document(currentTrip.id)

        docRef.addSnapshotListener { snapshot, error in
            if let data = snapshot?.data(),
               let base64 = data["itineraryBase64"] as? String,
               let decodedData = Data(base64Encoded: base64),
               let attributed = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: decodedData) {
                DispatchQueue.main.async {
                    self.itineraryTextView.attributedText = attributed
                }
            } else {
                DispatchQueue.main.async {
                    self.itineraryTextView.text = "No itinerary available."
                }
            }
        }
    }

    func isCurrentUserTripOwner() -> Bool {
        return UserManager.shared.currentUserID == currentTrip.ownerUID
    }

    func allSurveysSubmitted(completion: @escaping (Bool) -> Void) {
        TripManager.shared.fetchSurveyResponses(for: currentTrip) { responses in
            completion(responses.count == self.currentTrip.travelerUIDs.count)
        }
    }

    @IBAction func saveItinerary(_ sender: UIButton) {
        guard isCurrentUserTripOwner() else {
            showAlert(title: "Unauthorized", message: "Only the trip owner can save the itinerary.")
            return
        }
        guard let text = itineraryTextView.attributedText else { return }

        let archived = try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false)
        let base64 = archived?.base64EncodedString() ?? ""

        Firestore.firestore().collection("itineraries").document(currentTrip.id).setData([
            "tripID": currentTrip.id,
            "ownerUID": currentTrip.ownerUID,
            "itineraryBase64": base64,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error saving: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to save itinerary.")
            } else {
                self.showAlert(title: "Saved", message: "Itinerary successfully saved.")
            }
        }
    }

    @IBAction func clearItinerary(_ sender: UIButton) {
        guard isCurrentUserTripOwner() else {
            showAlert(title: "Unauthorized", message: "Only the trip owner can clear the itinerary.")
            return
        }

        Firestore.firestore().collection("itineraries").document(currentTrip.id).delete { error in
            if let error = error {
                print("Error clearing: \(error.localizedDescription)")
                self.showAlert(title: "Error", message: "Failed to clear itinerary.")
            } else {
                self.itineraryTextView.text = "No itinerary available."
                self.showAlert(title: "Cleared", message: "Itinerary has been cleared.")
            }
        }
    }

    @IBAction func regenerateItinerary(_ sender: UIButton) {
        guard isCurrentUserTripOwner() else {
            showAlert(title: "Unauthorized", message: "Only the trip owner can regenerate the itinerary.")
            return
        }
        generateItinerary()
    }

    func generateItinerary() {
        TripManager.shared.fetchSurveyResponses(for: currentTrip) { responses in
            var experienceCount: [String: Int] = [:]
            var cuisineCount: [String: Int] = [:]
            var foodExpCount: [String: Int] = [:]
            var preferredStart: Date?
            var preferredEnd: Date?
            var blockedTimes: [[String: Timestamp]] = []

            for response in responses {
                if let experiences = response["experiences"] as? [String] {
                    for item in experiences { experienceCount[item, default: 0] += 1 }
                }
                if let cuisines = response["cuisines"] as? [String] {
                    for item in cuisines { cuisineCount[item, default: 0] += 1 }
                }
                if let foodExps = response["foodExperiences"] as? [String] {
                    for item in foodExps { foodExpCount[item, default: 0] += 1 }
                }
                if preferredStart == nil, let start = response["preferredStart"] as? Timestamp {
                    preferredStart = start.dateValue()
                }
                if preferredEnd == nil, let end = response["preferredEnd"] as? Timestamp {
                    preferredEnd = end.dateValue()
                }
                if let blocks = response["blockedTimes"] as? [[String: Timestamp]] {
                    blockedTimes.append(contentsOf: blocks)
                }
            }

            guard let startDate = preferredStart, let endDate = preferredEnd else {
                print("Missing start or end dates.")
                return
            }

            let prompt = self.buildPrompt(
                exp: experienceCount,
                cuisines: cuisineCount,
                food: foodExpCount,
                startDate: startDate,
                endDate: endDate,
                preferredStart: startDate,
                preferredEnd: endDate,
                blockedTimes: blockedTimes,
                location: self.currentTrip.destination
            )

            ChatGPTManager.shared.generateItinerary(prompt: prompt) { itineraryText in
                DispatchQueue.main.async {
                    if let itineraryText = itineraryText {
                        let formatted = self.formatItineraryText(itineraryText)
                        self.itineraryTextView.attributedText = formatted

                        // Save immediately after generation
                        let archived = try? NSKeyedArchiver.archivedData(withRootObject: formatted, requiringSecureCoding: false)
                        let base64 = archived?.base64EncodedString() ?? ""

                        Firestore.firestore().collection("itineraries").document(self.currentTrip.id).setData([
                            "tripID": self.currentTrip.id,
                            "ownerUID": self.currentTrip.ownerUID,
                            "itineraryBase64": base64,
                            "updatedAt": Timestamp(date: Date())
                        ])
                    } else {
                        self.itineraryTextView.text = "Failed to generate itinerary."
                    }
                }
            }
        }
    }

    func buildPrompt(
        exp: [String: Int],
        cuisines: [String: Int],
        food: [String: Int],
        startDate: Date,
        endDate: Date,
        preferredStart: Date,
        preferredEnd: Date,
        blockedTimes: [[String: Timestamp]],
        location: String
    ) -> String {
        let topExp = exp.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        let topCuisines = cuisines.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        let topFood = food.sorted { $0.value > $1.value }.prefix(2).map { $0.key }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let tripRange = "\(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate))"
        let preferredStartTime = timeFormatter.string(from: preferredStart)
        let preferredEndTime = timeFormatter.string(from: preferredEnd)

        var blocked = ""
        for time in blockedTimes {
            if let start = time["start"]?.dateValue(), let end = time["end"]?.dateValue() {
                blocked += "- \(timeFormatter.string(from: start)) to \(timeFormatter.string(from: end))\n"
            }
        }

        return """
        You are a smart travel planner.

        Create a detailed itinerary for a group trip to \(location) from \(tripRange).

        Group preferences:
        • Top experiences: \(topExp.joined(separator: ", "))
        • Favorite cuisines: \(topCuisines.joined(separator: ", "))
        • Food interests: \(topFood.joined(separator: ", "))

        Daily schedule:
        - Start around \(preferredStartTime)
        - End around \(preferredEndTime)

        Avoid blocked times:
        \(blocked.isEmpty ? "None" : blocked)

        Include real restaurants and activities with names and addresses.
        """
    }

    func formatItineraryText(_ text: String) -> NSAttributedString {
        let fullText = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("**Day") && trimmed.hasSuffix("**") {
                let title = trimmed.replacingOccurrences(of: "**", with: "")
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 18), .paragraphStyle: paragraphStyle]
                fullText.append(NSAttributedString(string: "\(title)\n", attributes: attrs))
            } else if trimmed.lowercased().hasPrefix("• address:") {
                let address = trimmed.replacingOccurrences(of: "• Address: ", with: "")
                let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let mapURL = "http://maps.apple.com/?q=\(encoded)"
                let attrs: [NSAttributedString.Key: Any] = [
                    .link: URL(string: mapURL)!,
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .paragraphStyle: paragraphStyle
                ]
                fullText.append(NSAttributedString(string: "\(address)\n", attributes: attrs))
            } else {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 14),
                    .paragraphStyle: paragraphStyle
                ]
                fullText.append(NSAttributedString(string: "\(trimmed)\n\n", attributes: attrs))
            }
        }

        return fullText
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 1. Check if this is the correct segue using the identifier you just set
        if segue.identifier == "toLocationSearch" {
            
            // 2. Get a reference to the destination view controller
            if let destinationVC = segue.destination as? LocationViewController {
                
                // 3. Pass the trip object to the destination
                // (Make sure 'self.trip' holds the correct trip data before the segue)
                destinationVC.trip = self.currentTrip
            }
        }
    }
    
}
