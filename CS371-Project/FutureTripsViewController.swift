//
//  FutureTripsViewController.swift
//  CS371-Project
//
//  Created by Julia  on 7/9/25.
//

import UIKit


class FutureTripsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
    }
    
    //test to add 3 elements
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 5
        }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCellID", for: indexPath) as! TripCell

        // styling container
        cell.containerView.layer.cornerRadius = 12
        cell.containerView.backgroundColor = .white

        // double check details
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        
        //shadow
        cell.containerView.layer.shadowColor = UIColor.black.cgColor
        cell.containerView.layer.shadowOpacity = 0.1
        cell.containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.containerView.layer.shadowRadius = 4

        return cell
    }

}
