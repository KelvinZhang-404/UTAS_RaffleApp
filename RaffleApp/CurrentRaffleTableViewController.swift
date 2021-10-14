//
//  CurrentRaffleTableViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 19/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class CurrentRaffleTableViewController: UITableViewController {
    var allRaffles = [Raffle]()
    var raffles = [Raffle]()
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    @IBOutlet var subEditRaffleView: UIView!
    @IBOutlet var raffleNameField: UITextField!
    @IBOutlet var descriptionField: UITextField!
    @IBOutlet var drawnMethodField: UITextField!
    @IBOutlet var startDateField: UITextField!
    @IBOutlet var endDateField: UITextField!
    @IBOutlet var ticketAmountField: UITextField!
    @IBOutlet var ticketPriceField: UITextField!
    @IBOutlet var raffleIDField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("loading... current raffle table view")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.addSubview(subEditRaffleView)
        subEditRaffleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subEditRaffleView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            subEditRaffleView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            subEditRaffleView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            subEditRaffleView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        subEditRaffleView.alpha = 0
        subEditRaffleView.isHidden = true
        allRaffles = database.selectAllRaffles()
        raffles.removeAll()
        for raffle in allRaffles {
            if raffle.status != "completed" {
                raffles.append(raffle)
            }
        }
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    @objc func action() {
          view.endEditing(true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "You have \(raffles.count) activated raffles"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return raffles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RaffleTableViewCell", for: indexPath)

        // Configure the cell...
        let raffle = raffles[indexPath.row]
        if let raffleCell = cell as? CurrentRaffleTableViewCell
        {
            raffleCell.raffleName.text = raffle.name
            
            // Set Raffle Status
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            let today = Date()
            
            var status:String
            let startDate = dateFormatter.date(from: raffle.startDate)
            let endDate = dateFormatter.date(from: raffle.endDate)
            let tickets = database.selectTicketsByRaffle(id: raffle.raffleID)
            if today > endDate! || tickets.count >= raffle.ticketAmount {
                status = "Due"
                raffleCell.raffleStatus.textColor = UIColor.systemRed
            } else if today > startDate! {
                status = "In progress"
                raffleCell.raffleStatus.textColor = UIColor.systemGreen
            } else {
                status = "Holding"
                raffleCell.raffleStatus.textColor = UIColor.systemBlue
            }
            
            raffleCell.raffleStatus.text = status
            let imageName = raffle.image
            if (imageName != "") {
                // Get the path to the Documents directory and append to this a slash (path separator)
                let filepath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + imageName
                // set the aspect ratio for the displayed image
                raffleCell.raffleImage.contentMode = .scaleAspectFit
                // display the previously-saved image in that view
                raffleCell.raffleImage.image = UIImage(contentsOfFile: filepath)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            let raffle = self.raffles[indexPath.row]
            let tickets = self.database.selectTicketsByRaffle(id: raffle.raffleID)
            if tickets.count > 0 {
                self.presentAlert(with: "Cannot delete this Raffle because there are sold tickets")
            } else {
                let alert = UIAlertController(title: "Alert", message: "Are you sure to DELETE this raffle?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes DELETE", style: .destructive, handler: { action in
                    // Delete the row from the data source
                    self.raffles.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self.database.deleteRaffleBy(id: raffle.raffleID)
                    print("yes deleteted")
                }))
                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
                      print("Cancel Delete")
                }))
                self.present(alert, animated: true, completion: nil)
                
            }
        }
        let edit = UIContextualAction(style: .normal, title: "Edit") {  (contextualAction, view, boolValue) in
            //Code I want to do here
            let raffle = self.raffles[indexPath.row]
            let tickets = self.database.selectTicketsByRaffle(id: raffle.raffleID)
            if tickets.count > 0 {
                self.ticketAmountField.isEnabled = false
                self.ticketPriceField.isEnabled = false
            } else {
                self.ticketAmountField.isEnabled = true
                self.ticketPriceField.isEnabled = true
            }
            self.raffleIDField.text = String(raffle.raffleID)
            self.raffleNameField.text = raffle.name
            self.descriptionField.text = raffle.description
            self.drawnMethodField.text = raffle.drawnMethod
            self.startDateField.text = raffle.startDate
            self.endDateField.text = raffle.endDate
            self.ticketAmountField.text = String(raffle.ticketAmount)
            self.ticketPriceField.text = String(raffle.ticketPrice)
            
            self.subEditRaffleView.isHidden = false
            UIView.animate(withDuration: 1, animations: {
                self.subEditRaffleView.alpha = 1.0
            })
            print("edit clicked")
        }
        edit.backgroundColor = UIColor.systemGreen;
        let swipeActions = UISwipeActionsConfiguration(actions: [delete, edit])

        return swipeActions
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        print("begin updating ...")
        let raffleName = raffleNameField.text
        let description = descriptionField.text
        let ticketAmount = Int32(ticketAmountField.text ?? "") ?? 0
        let ticketPrice = Double(ticketPriceField.text ?? "") ?? 0
        
        if raffleName == "" {
            presentAlert(with: "Please set a name for your raffle")
        } else if Int(ticketAmount) < 1 {
            presentAlert(with: "Ticket amount should be at least 1")
        } else if ticketPrice <= 0 {
            presentAlert(with: "Please set a valid ticket price")
        } else {
            let raffleID = Int32(raffleIDField.text!)
            var raffle = database.selectRaffleByID(id: raffleID!)
            raffle?.name = raffleName!
            raffle?.description = description!
            raffle?.ticketAmount = ticketAmount
            raffle?.ticketPrice = ticketPrice
            database.updateRaffle(raffle: raffle!)
            self.viewWillAppear(true)
            
            self.view.endEditing(true)
            subEditRaffleView.alpha = 0
            subEditRaffleView.isHidden = true
            print("finish updating ...")
            presentAlert(with: "Raffle settings updated")
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.view.endEditing(true)
        subEditRaffleView.alpha = 0
        subEditRaffleView.isHidden = true
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func presentAlert(with message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
              print("default")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "viewRaffleDetailSegue"
        {
            guard let raffleDetailViewController = segue.destination as? VeiwRaffleDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            guard let selectedRaffleCell = sender as? CurrentRaffleTableViewCell else {
                fatalError("Unexpected sender: \( String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedRaffleCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let selectedRaffle = raffles[indexPath.row]
            raffleDetailViewController.raffle = selectedRaffle
        }
    }
    
    @IBAction func undoSegue(segue: UIStoryboard) {
        
    }
}
