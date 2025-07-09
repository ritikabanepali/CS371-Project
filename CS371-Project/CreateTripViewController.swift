//
//  CreateTripViewController.swift
//  CS371-Project
//
//

import UIKit


class CreateTripViewController: UIViewController {

    @IBOutlet weak var destinationField: UITextField!
    @IBOutlet weak var startDateField: UITextField!
    @IBOutlet weak var endDateField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var continueButton: UIButton!

    let startPicker = UIDatePicker()
    let endPicker = UIDatePicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDatePicker(textField: startDateField, datePicker: startPicker)
        setupDatePicker(textField: endDateField, datePicker: endPicker)
    }

    func setupDatePicker(textField: UITextField, datePicker: UIDatePicker) {
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        textField.inputView = datePicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.setItems([
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        ], animated: true)
        textField.inputAccessoryView = toolbar
    }

    @objc func doneTapped() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"

        if startDateField.isFirstResponder {
            startDateField.text = formatter.string(from: startPicker.date)
            startDateField.resignFirstResponder()
        } else if endDateField.isFirstResponder {
            endDateField.text = formatter.string(from: endPicker.date)
            endDateField.resignFirstResponder()
        }
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        print("Destination: \(destinationField.text ?? "")")
        print("Start Date: \(startDateField.text ?? "")")
        print("End Date: \(endDateField.text ?? "")")
    }

    @IBAction func addFriendTapped(_ sender: UIButton) {
        print("Friend to add: \(usernameField.text ?? "")")
        // Later: Add logic to show dynamic tag
    }
}

