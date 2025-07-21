 //
//  IteneraryViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/6/25.
//

import UIKit
import FirebaseFirestore


class IteneraryViewController: UIViewController {
    var currentTrip: Trip!
    
    @IBOutlet weak var itineraryTextView: UITextView!
    @IBOutlet weak var itineraryTitleLabel: UILabel!

    @IBOutlet weak var moreLocationsButton: UIButton!
    @IBOutlet weak var orderButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let trip = currentTrip else {
            print("No trip passed to itinerary generator")
            return
        }

        TripManager.shared.fetchSurveyResponses(for: trip) { responses in
            // Tally preferences from all users
            var experienceCount: [String: Int] = [:]
            var cuisineCount: [String: Int] = [:]
            var foodExpCount: [String: Int] = [:]

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
            }

            print("Experiences:", experienceCount)
            print("Cuisines:", cuisineCount)
            print("Food Experiences:", foodExpCount)

            // Next: Send a summary to ChatGPT API here
            // self.generateItinerary(experienceCount: experienceCount, cuisineCount: ..., etc.)
            let prompt = self.buildPrompt(exp: experienceCount, cuisines: cuisineCount, food: foodExpCount)

            ChatGPTManager.shared.generateItinerary(prompt: prompt) { itineraryText in
                DispatchQueue.main.async {
                    self.itineraryTextView.text = itineraryText ?? "Failed to generate itinerary."
                }
            }

        }
    }
    
    func buildPrompt(exp: [String: Int], cuisines: [String: Int], food: [String: Int]) -> String {
        let topExp = exp.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        let topCuisines = cuisines.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        let topFood = food.sorted { $0.value > $1.value }.prefix(2).map { $0.key }

        return """
        Create a 3-day travel itinerary for a group with these shared preferences:

        - Favorite experiences: \(topExp.joined(separator: ", "))
        - Preferred cuisines: \(topCuisines.joined(separator: ", "))
        - Food interests: \(topFood.joined(separator: ", "))

        Suggest specific daily activities and meals for each day.
        """
    }


    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
