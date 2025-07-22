import UIKit
import FirebaseFirestore

class IteneraryViewController: UIViewController {
    var currentTrip: Trip!

    @IBOutlet weak var itineraryTextView: UITextView!
    @IBOutlet weak var itineraryTitleLabel: UILabel!
    @IBOutlet weak var moreLocationsButton: UIButton!
    @IBOutlet weak var itineraryDatesLabel: UILabel!

    
    @IBAction func saveItinerary(_ sender: UIButton) {
        guard let text = itineraryTextView.attributedText else { return }
        let archived = try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false)
        UserDefaults.standard.set(archived, forKey: "SavedItinerary")
        showAlert(title: "Saved", message: "Your itinerary has been saved.")
    }

    @IBAction func clearItinerary(_ sender: UIButton) {
        itineraryTextView.text = ""
        showAlert(title: "Cleared", message: "Your itinerary has been cleared.")
    }

    @IBAction func regenerateItinerary(_ sender: UIButton) {
        viewDidLoad() // rerun the logic
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        guard let trip = currentTrip else {
            print("No trip passed to itinerary generator")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let start = formatter.string(from: trip.startDate)
        let end = formatter.string(from: trip.endDate)

        itineraryTitleLabel.text = "Your itinerary to \(trip.destination):"
        itineraryDatesLabel.text = "\(start) – \(end)"


        TripManager.shared.fetchSurveyResponses(for: trip) { responses in
            var experienceCount: [String: Int] = [:]
            var cuisineCount: [String: Int] = [:]
            var foodExpCount: [String: Int] = [:]
            var preferredStart: Date?
            var preferredEnd: Date?
            var blockedTimes: [[String: Timestamp]] = []

            for response in responses {
                if let experiences = response["experiences"] as? [String] {
                    for item in experiences {
                        experienceCount[item, default: 0] += 1
                    }
                }

                if let cuisines = response["cuisines"] as? [String] {
                    for item in cuisines {
                        cuisineCount[item, default: 0] += 1
                    }
                }

                if let foodExps = response["foodExperiences"] as? [String] {
                    for item in foodExps {
                        foodExpCount[item, default: 0] += 1
                    }
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
                print("Missing trip start or end dates.")
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
                location: trip.destination
            )

            ChatGPTManager.shared.generateItinerary(prompt: prompt) { itineraryText in
                DispatchQueue.main.async {
                    if let itineraryText = itineraryText {
                        self.itineraryTextView.attributedText = self.formatItineraryText(itineraryText)
                    } else {
                        self.itineraryTextView.text = "Failed to generate itinerary."
                    }
                }
            }
        }
        
        itineraryTextView.isEditable = false
        itineraryTextView.isSelectable = true
        itineraryTextView.dataDetectorTypes = [.link]
        
        if let savedData = UserDefaults.standard.data(forKey: "SavedItinerary"),
           let savedAttrString = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedData) as? NSAttributedString {
            itineraryTextView.attributedText = savedAttrString
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
        dateFormatter.timeStyle = .none
        
        let calendar = Calendar.current
        let maxDays = 7
        let numDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 2
        let totalDays = min(max(numDays + 1, 1), maxDays)


        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
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

        Create a detailed \(totalDays)-day itinerary for a group trip to \(location) from \(tripRange).

        Group preferences:
        • Top experiences: \(topExp.joined(separator: ", "))
        • Favorite cuisines: \(topCuisines.joined(separator: ", "))
        • Food interests: \(topFood.joined(separator: ", "))

        Daily schedule should follow this pattern:
        - Start day around \(preferredStartTime)
        - End day around \(preferredEndTime)

        Please avoid scheduling activities during these blocked times:
        \(blocked.isEmpty ? "None" : blocked)

        For each day, include:
        - Breakfast, lunch, and dinner at real restaurants in \(location) (include names, addresses, and what they’re known for)
        - Activities at real places (include names and addresses)
        - Time blocks for each activity

        Ensure variety, reflect preferences, and make it fun!
        """
    }

    func formatItineraryText(_ text: String) -> NSAttributedString {
        let fullText = NSMutableAttributedString(string: "")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("**Day") && trimmed.hasSuffix("**") {
                let dayTitle = trimmed.replacingOccurrences(of: "**", with: "")
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .paragraphStyle: paragraphStyle
                ]
                fullText.append(NSAttributedString(string: "\(dayTitle)\n", attributes: attributes))
            } else if trimmed.lowercased().hasPrefix("• address:") {
                let address = trimmed.replacingOccurrences(of: "• Address: ", with: "")
                let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let mapURL = "http://maps.apple.com/?q=\(encoded)"
                let linkAttributes: [NSAttributedString.Key: Any] = [
                    .link: URL(string: mapURL)!,
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.systemBlue,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .paragraphStyle: paragraphStyle
                ]
                fullText.append(NSAttributedString(string: "\(address)\n", attributes: linkAttributes))
            } else {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 14),
                    .paragraphStyle: paragraphStyle
                ]
                fullText.append(NSAttributedString(string: "\(trimmed)\n\n", attributes: attributes))
            }
        }

        return fullText
    }
}
