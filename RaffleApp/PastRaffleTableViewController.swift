//
//  PastRaffleTableViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 21/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class PastRaffleTableViewController: UITableViewController {
    var allRaffles = [Raffle]()
    var pastRaffles = [Raffle]()
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    
    @IBOutlet var pastRaffleTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
//        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
//        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
//        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
    }
    
    @objc func refresh(_ sender: AnyObject) {
       // Code to refresh table view
        print("refresh")
        pastRaffleTableView.reloadData()
        self.refreshControl!.endRefreshing()
    }

    override func viewWillAppear(_ animated: Bool) {
        allRaffles = database.selectAllRaffles()
        pastRaffles.removeAll()
        for raffle in allRaffles {
            if raffle.status == "completed" {
                pastRaffles.append(raffle)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "You have \(pastRaffles.count) past raffles"
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return pastRaffles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pastRaffleTableViewCell", for: indexPath)

        // Configure the cell...
        let raffle = pastRaffles[indexPath.row]
        if let raffleCell = cell as? PastRaffleTableViewCell
        {
            raffleCell.raffleName.text = raffle.name
            raffleCell.raffleDescription.text = raffle.description
            
            let imageName = raffle.image
            if (imageName != "") {
                // Get the path to the Documents directory and append to this a slash (path separator)
                // and then the savedFilename – so you have the path to the local copy of the image
                // you made earlier (on the previous slide)
                let filepath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + imageName
                
                // we’ll assume your onscreen outlet for the UIImageView is named "theImageView"
                // set the aspect ratio for the displayed image
                raffleCell.raffleImage.contentMode = .scaleAspectFit
            
                // display the previously-saved image in that view
                raffleCell.raffleImage.image = UIImage(contentsOfFile: filepath)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let raffle = pastRaffles[indexPath.row]
        print(raffle.winner)
        var popUpWindow: PopUpWindow!
        if let customer = database.selectCustomerByName(name: raffle.winner) {
            popUpWindow = PopUpWindow(title: "Winner Details", raffleName: raffle.name, ticketNumber: "secret", customerName: customer.name, customerEmail: customer.email, customerPhone: String(customer.phone), buttontext: "OK")
        } else {
            popUpWindow = PopUpWindow(title: "Winner Details", raffleName: raffle.name, ticketNumber: "", customerName: "no winner", customerEmail: "no winner", customerPhone: "no winner", buttontext: "OK")
        }
        
        
        self.present(popUpWindow, animated: true, completion: nil)
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
