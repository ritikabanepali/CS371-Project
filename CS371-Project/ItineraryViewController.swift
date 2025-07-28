// ItineraryViewController.swift

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
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        applyColorScheme()
        
        itineraryTitleLabel.text = "Your Itinerary To \(trip.destination)"
        itineraryDatesLabel.text = "\(formatter.string(from: trip.startDate)) – \(formatter.string(from: trip.endDate))"
        
        let isOwner = isCurrentUserTripOwner()
        // Only shows itinerary controls (save/clear/regenerate) to the trip owner
        saveItineraryButton.isHidden = !isOwner
        clearItineraryButton.isHidden = !isOwner
        regenerateItineraryButton.isHidden = !isOwner
        
        if isOwner {
            // Enable buttons only if all invited travelers have submitted their surveys
            allSurveysSubmitted { allDone in
                DispatchQueue.main.async {
                    let enable = allDone
                    self.saveItineraryButton.isEnabled = enable
                    self.clearItineraryButton.isEnabled = enable
                    self.regenerateItineraryButton.isEnabled = enable
                    if !enable {
                        // Alert owner that itinerary actions are locked until all surveys are done
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
        let isOwner = isCurrentUserTripOwner()
        
        docRef.addSnapshotListener { snapshot, _ in
            if let data = snapshot?.data(),
               let base64 = data["itineraryBase64"] as? String,
               let decodedData = Data(base64Encoded: base64),
               let attributed = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: decodedData) {
                DispatchQueue.main.async {
                    self.itineraryTextView.attributedText = attributed
                }
            } else {
                DispatchQueue.main.async {
                    if !isOwner {
                        self.showAlert(
                            title: "Itinerary Not Ready",
                            message: "The itinerary hasn’t been created yet. Please wait for the trip owner to generate it."
                        )
                    }
                    self.itineraryTextView.text = "No itinerary available, click 'Generate' to generate itinerary."
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
    
    // added permissions so only trip owner can generate/save/clear itinerary
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
            if error != nil {
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
            if error != nil {
                self.showAlert(title: "Error", message: "Failed to clear itinerary.")
            } else {
                self.itineraryTextView.text = "No itinerary available, click 'Generate' to generate itinerary."
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
                        
                        // can only interact with itinerary only after all invited travelers have submitted surveys and uses firestore with live syncing
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
        
        // prompt sent to ChatGPT
        return """
        You are a smart travel planner.
        
        Create a detailed itinerary for a group trip to \(location) from \(tripRange).
        
        Group preferences:
        • Top experiences: \(topExp.joined(separator: ", "))
        • Favorite cuisines: \(topCuisines.joined(separator: ", "))
        • Food interests: \(topFood.joined(separator: ", "))
        
        Daily schedule:
        - For each day, plan the following:
          • Breakfast (suggest a local café or unique breakfast spot)
          • Morning Activity (9am–12pm): light sightseeing or scenic activity  
          • Lunch (recommend a real restaurant that matches group cuisine preferences)
          • Afternoon Activity (12pm–5pm): cultural or outdoor attraction  
          • Dinner (select a popular or hidden gem restaurant with atmosphere)
          • Evening Activity (optional, e.g., walk, show, market visit)
        - Meals should reflect the group’s top cuisine and food interests
        - Use the group's preferred start time (~\(preferredStartTime)) and end time (~\(preferredEndTime)) as a general window for scheduling
        - On travel days (first/last day), schedule lighter activities and meals near the hotel or transit hub.
        
        Avoid blocked times:
        \(blocked.isEmpty ? "None" : blocked)
        
        Include real restaurants and activities with names and addresses.
        For each activity, write 1 engaging sentence that describes what the travelers will experience. Mention interesting facts, what makes the place special, and why it was chosen based on group preferences.
        Write in a friendly, enthusiastic, and informative tone — as if you're a tour guide showing close friends around.
        Label each day like: **Day 1**. Use bullet points (`-`) for each event, and begin each one with the scheduled time (e.g., "9:00 AM – Visit Gyeongbokgung Palace").

        Include real names of locations and restaurants with addresses.  
        On a new line after each place name, write only the full address — no names. Start the line with: • Address:
        Example:
        - Visit Gyeongbokgung Palace  
        • Address: 161 Sajik-ro, Jongno-gu, Seoul, South Korea 
        Avoid using markdown like `#`, tables, or links.
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
                let address = trimmed.replacingOccurrences(of: "• Address:", with: "").trimmingCharacters(in: .whitespaces)
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
        // Check if this is the correct segue using the identifier you just set
        if segue.identifier == "toLocationSearch" {
            
            // Get a reference to the destination view controller
            if let destinationVC = segue.destination as? LocationViewController {
                
                // Pass the trip object to the destination
                destinationVC.trip = self.currentTrip
            }
        }
    }
    
}
