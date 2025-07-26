//
//  SurveyViewController.swift
//  CS371-Project
//
//  Created by ritika banepali on 7/6/25.
//

import UIKit
import FirebaseFirestore


class SurveyViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var tripInputTitleLabel: UILabel!
    // MARK: - Outlets for date pickers
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    // MARK: - TableView for blocked times
    @IBOutlet weak var blockedTimesTableView: UITableView!
    
    // MARK: - All checkboxes (connect these in storyboard)
    @IBOutlet weak var artsCultureButton: UIButton!
    @IBOutlet weak var landmarksButton: UIButton!
    @IBOutlet weak var adventureButton: UIButton!
    @IBOutlet weak var shoppingButton: UIButton!
    @IBOutlet weak var festivalsButton: UIButton!
    @IBOutlet weak var relaxationButton: UIButton!
    @IBOutlet weak var natureButton: UIButton!
    @IBOutlet weak var childFriendlyButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var romanceButton: UIButton!
    
    
    @IBOutlet weak var eastAsianButton: UIButton!
    @IBOutlet weak var africanCaribbeanButton: UIButton!
    @IBOutlet weak var southAsianButton: UIButton!
    @IBOutlet weak var vegetarianButton: UIButton!
    @IBOutlet weak var veganButton: UIButton!
    @IBOutlet weak var mediterraneanButton: UIButton!
    @IBOutlet weak var latinAmericanButton: UIButton!
    @IBOutlet weak var seaFoodButton: UIButton!
    @IBOutlet weak var middleEasternButton: UIButton!
    @IBOutlet weak var americanButton: UIButton!
    
    
    @IBOutlet weak var localSpecialtiesButton: UIButton!
    @IBOutlet weak var streetFoodButton: UIButton!
    @IBOutlet weak var fineDiningButton: UIButton!
    @IBOutlet weak var foodToursButton: UIButton!
    @IBOutlet weak var wineButton: UIButton!
    @IBOutlet weak var dessertButton: UIButton!
    
    // MARK: - Data for blocked times
    var blockedTimeRanges: [(Date, Date)] = []
    var currentTrip: Trip? //
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blockedTimesTableView.dataSource = self
        blockedTimesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "BlockedTimeCell")
        tripInputTitleLabel.textColor = SettingsManager.shared.titleColor
        
        var submitButtonConfig = submitButton.configuration ?? .filled()
        submitButtonConfig.background.backgroundColor = SettingsManager.shared.buttonColor
        submitButtonConfig.baseForegroundColor = .white
        submitButton.configuration = submitButtonConfig

        
        if let trip = currentTrip {
            startDatePicker.minimumDate = trip.startDate
            endDatePicker.maximumDate = trip.endDate
            endDatePicker.minimumDate = startDatePicker.date
            
        }
    }
    
    func getSelectedTitles(from buttons: [UIButton]) -> [String] {
        return buttons.filter { $0.isSelected }.compactMap { $0.titleLabel?.text }
    }
    
    // MARK: - Checkbox Toggle
    @IBAction func checkboxTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        let imageName = sender.isSelected ? "checkmark.square" : "square"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    // MARK: - Add Blocked Time Range
    @IBAction func addBlockedTime(_ sender: UIButton) {
        let start = startDatePicker.date
        let end = endDatePicker.date
        
        guard start < end else {
            print("Start must be before end")
            return
        }
        
        blockedTimeRanges.append((start, end))
        blockedTimesTableView.reloadData()
    }
    
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedTimeRanges.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedTimeCell", for: indexPath)
        let (start, end) = blockedTimeRanges[indexPath.row]
        cell.textLabel?.text = "\(formatter.string(from: start)) → \(formatter.string(from: end))"
        return cell
    }
    
    @IBAction func submitSurvey(_ sender: UIButton) {
        guard let userId = UserManager.shared.currentUserID else {
            print("No authenticated user")
            return
        }
        
        guard let tripID = currentTrip?.id else {
            print("No current trip selected")
            return
        }
        
        
        let experiences = getSelectedTitles(from: [
            artsCultureButton, landmarksButton, adventureButton, shoppingButton,
            festivalsButton, relaxationButton, natureButton, childFriendlyButton,
            musicButton, romanceButton
        ])
        
        let cuisines = getSelectedTitles(from: [
            eastAsianButton, africanCaribbeanButton, southAsianButton, vegetarianButton,
            veganButton, mediterraneanButton, latinAmericanButton, seaFoodButton,
            middleEasternButton, americanButton
        ])
        
        let foodExperiences = getSelectedTitles(from: [
            localSpecialtiesButton, streetFoodButton, fineDiningButton,
            foodToursButton, wineButton, dessertButton
        ])
        
        let preferredStart = startDatePicker.date
        let preferredEnd = endDatePicker.date
        
        let blockedTimes = blockedTimeRanges.map { ["start": Timestamp(date: $0.0), "end": Timestamp(date: $0.1)] }
        
        let surveyData: [String: Any] = [
            "tripID": tripID,
            "experiences": experiences,
            "cuisines": cuisines,
            "foodExperiences": foodExperiences,
            "preferredStart": Timestamp(date: preferredStart),
            "preferredEnd": Timestamp(date: preferredEnd),
            "blockedTimes": blockedTimes
        ]
        
        let db = Firestore.firestore()
        
        guard let tripOwnerId = currentTrip?.ownerUID else {
            print("Missing trip owner ID")
            return
        }
        
        let tripRef = db
            .collection("Users")
            .document(tripOwnerId) // the trip's owner's UID
            .collection("trips")
            .document(tripID)
            .collection("surveyResponses")
            .document(userId) // overwrite or create the user’s survey response
        
        tripRef.setData(surveyData) { error in
            if let error = error {
                print("Error saving survey: \(error)")
            } else {
                print("Survey response saved under the trip!")
            }
        }
        
    }
    
}

