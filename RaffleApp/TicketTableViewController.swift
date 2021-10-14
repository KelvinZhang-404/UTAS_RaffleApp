//
//  TicketTableViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 20/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class TicketTableViewController: UITableViewController {
    
    var raffle: Raffle?
    var tickets: [Ticket]?
    var dictionary = [Int32: [Ticket]]()
    
    var customerTicketsArray: [(Int32, [Ticket])]?
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    @IBOutlet var subEditCustomerView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var phoneField: UITextField!
    @IBOutlet var saveButton: UIButton!
    @IBOutlet var ticketTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.addSubview(subEditCustomerView)
        subEditCustomerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subEditCustomerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            subEditCustomerView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor),
            subEditCustomerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            subEditCustomerView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        subEditCustomerView.alpha = 0
        
        self.title = raffle?.name.uppercased()
        tickets = database.selectTicketsByRaffle(id: raffle!.raffleID)
    }
    
    

    @objc func dismissView() {
          self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Ticket List"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tickets!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTableViewCell", for: indexPath)
        let ticket = tickets![indexPath.row]
        let customer = database.selectCustomerByID(id: ticket.customerID)
        if let ticketCell = cell as? TicketTableViewCell {
            ticketCell.customerName.text = customer?.name
            ticketCell.ticketNumber.text = String(ticket.ticketNo)
            ticketCell.purchaseDate.text = ticket.purchaseDate
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: "Share") {  (contextualAction, view, boolValue) in
            let ticket = self.tickets![indexPath.row]
            let customer = self.database.selectCustomerByID(id: ticket.customerID)
            let imageName = self.raffle!.image
            let filepath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + imageName
            let image = UIImage(contentsOfFile: filepath)
            let shareViewController = UIActivityViewController(
                activityItems: ["\(customer!.name), Ticket \(ticket.ticketNo), $\(self.raffle!.ticketPrice), Purchased \(ticket.purchaseDate)", image as Any],
                applicationActivities: [])
            
            self.present(shareViewController, animated: true, completion: nil)
        }
        share.backgroundColor = UIColor.systemBlue
        
        let edit = UIContextualAction(style: .destructive, title: "Edit") {  (contextualAction, view, boolValue) in
            
            let ticket = self.tickets![indexPath.row]
            let customer = self.database.selectCustomerByID(id: ticket.customerID)
            
            self.nameLabel.text = customer?.name
            self.emailField.text = customer?.email
            self.phoneField.text = "\(customer!.phone)"
            
            UIView.animate(withDuration: 1, animations: {
                self.subEditCustomerView.alpha = 1.0
            })
            
            print("edit clicked")
        }
        edit.backgroundColor = UIColor.systemGreen
        let swipeActions = UISwipeActionsConfiguration(actions: [share, edit])

        return swipeActions
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ticket = self.tickets![indexPath.row]
        let customer = database.selectCustomerByID(id: ticket.customerID)
        
        var popUpWindow: PopUpWindow!
        popUpWindow = PopUpWindow(title: "Ticket Detail", raffleName: raffle!.name, ticketNumber: String(ticket.ticketNo), customerName: customer!.name, customerEmail: customer!.email, customerPhone: String(customer!.phone), buttontext: "OK")
        self.present(popUpWindow, animated: true, completion: nil)
    }

    @IBAction func saveEditing(_ sender: Any) {
        print("begin updating ...")
        
        var customer = database.selectCustomerByName(name: nameLabel.text!)
        customer?.email = emailField.text ?? ""
        customer?.phone = Int32(String(phoneField.text!)) ?? 0
        database.updateCustomer(customer: customer!)
        
        self.view.endEditing(true)
        subEditCustomerView.alpha = 0
        print("finish updating ...")
        presentAlert(with: "Customer detail updated")
        
    }
    
    @IBAction func cancelEditing(_ sender: Any) {
        self.view.endEditing(true)
        subEditCustomerView.alpha = 0
    }
    
    func presentAlert(with message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

class PopUpWindow: UIViewController {
    
    private let popUpWindowView = TicketDetailPopup()

    init(title: String, raffleName: String, ticketNumber: String, customerName: String, customerEmail: String, customerPhone: String, buttontext: String) {
        super.init(nibName: nil, bundle: nil)
        
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
        
        popUpWindowView.popupTitle.text = title
        popUpWindowView.popupRaffleName.text = "Raffle name - " + raffleName
        popUpWindowView.popupTicketNumber.text = "Ticket number - " + ticketNumber
        popUpWindowView.popupCustomerName.text = "Customer name - " + customerName
        popUpWindowView.popupCustomerEmail.text = "Customer email - " + customerEmail
        popUpWindowView.popupCustomerPhone.text = "Customer phone - " + customerPhone
        popUpWindowView.popupButton.setTitle(buttontext, for: .normal)
        
        
        popUpWindowView.popupButton.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        
        view = popUpWindowView
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    @objc func dismissView(){
        self.dismiss(animated: true, completion: nil)
    }
}

private class TicketDetailPopup: UIView {
    let popupView = UIView(frame: CGRect.zero)
    let popupTitle = UILabel(frame: CGRect.zero)
    let popupRaffleName = UILabel(frame: CGRect.zero)
    let popupTicketNumber = UILabel(frame: CGRect.zero)
    let popupCustomerName = UILabel(frame: CGRect.zero)
    let popupCustomerEmail = UILabel(frame: CGRect.zero)
    let popupCustomerPhone = UILabel(frame: CGRect.zero)
    let popupButton = UIButton(frame: CGRect.zero)

    let BorderWidth: CGFloat = 2.0

    init() {
        super.init(frame: CGRect.zero)
        // Semi-transparent background
        backgroundColor = UIColor.black.withAlphaComponent(0.3)

        // Popup Background
        popupView.backgroundColor = UIColor.systemYellow
//        popupView.layer.borderWidth = BorderWidth
        popupView.layer.masksToBounds = true
//        popupView.layer.borderColor = UIColor.white.cgColor

        // Popup Title
        popupTitle.textColor = UIColor.black
//        popupTitle.backgroundColor = UIColor.yellow
        popupTitle.layer.masksToBounds = true
        popupTitle.adjustsFontSizeToFitWidth = true
        popupTitle.clipsToBounds = true
        popupTitle.font = UIFont.systemFont(ofSize: 21.0, weight: .bold)
        popupTitle.numberOfLines = 1
        popupTitle.textAlignment = .center

        // Popup Text
        popupRaffleName.textColor = UIColor.black
        popupRaffleName.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        popupRaffleName.numberOfLines = 0
        popupRaffleName.textAlignment = .left
        
        popupTicketNumber.textColor = UIColor.black
        popupTicketNumber.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        popupTicketNumber.numberOfLines = 0
        popupTicketNumber.textAlignment = .left
        
        popupCustomerName.textColor = UIColor.black
        popupCustomerName.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        popupCustomerName.numberOfLines = 0
        popupCustomerName.textAlignment = .left
        
        popupCustomerEmail.textColor = UIColor.black
        popupCustomerEmail.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        popupCustomerEmail.numberOfLines = 0
        popupCustomerEmail.textAlignment = .left
        
        popupCustomerPhone.textColor = UIColor.black
        popupCustomerPhone.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        popupCustomerPhone.numberOfLines = 0
        popupCustomerPhone.textAlignment = .left

        // Popup Button
        popupButton.setTitleColor(UIColor.white, for: .normal)
        popupButton.titleLabel?.font = UIFont.systemFont(ofSize: 21.0, weight: .bold)
        popupButton.backgroundColor = UIColor.black

        popupView.addSubview(popupTitle)
        popupView.addSubview(popupRaffleName)
        popupView.addSubview(popupTicketNumber)
        popupView.addSubview(popupCustomerName)
        popupView.addSubview(popupCustomerEmail)
        popupView.addSubview(popupCustomerPhone)
        popupView.addSubview(popupButton)

        // Add the popupView(box) in the PopUpWindowView (semi-transparent background)
        addSubview(popupView)


        // PopupView constraints
        popupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupView.widthAnchor.constraint(equalToConstant: 293),
            popupView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            popupView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ])

        // PopupTitle constraints
        popupTitle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupTitle.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: BorderWidth),
            popupTitle.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -BorderWidth),
            popupTitle.topAnchor.constraint(equalTo: popupView.topAnchor, constant: BorderWidth),
            popupTitle.heightAnchor.constraint(equalToConstant: 44)
            ])


        // PopupText constraints
        popupRaffleName.translatesAutoresizingMaskIntoConstraints = false
        popupTicketNumber.translatesAutoresizingMaskIntoConstraints = false
        popupCustomerName.translatesAutoresizingMaskIntoConstraints = false
        popupCustomerEmail.translatesAutoresizingMaskIntoConstraints = false
        popupCustomerPhone.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
//            popupRaffleName.heightAnchor.constraint(greaterThanOrEqualToConstant: 67),
            popupRaffleName.topAnchor.constraint(equalTo: popupTitle.bottomAnchor, constant: 8),
            popupRaffleName.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            popupRaffleName.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            popupRaffleName.bottomAnchor.constraint(equalTo: popupTicketNumber.topAnchor, constant: -8),
            
            popupTicketNumber.topAnchor.constraint(equalTo: popupRaffleName.bottomAnchor, constant: 8),
            popupTicketNumber.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            popupTicketNumber.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            popupTicketNumber.bottomAnchor.constraint(equalTo: popupCustomerName.topAnchor, constant: -8),
            
            popupCustomerName.topAnchor.constraint(equalTo: popupTicketNumber.bottomAnchor, constant: 8),
            popupCustomerName.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            popupCustomerName.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            popupCustomerName.bottomAnchor.constraint(equalTo: popupCustomerEmail.topAnchor, constant: -8),
            
            popupCustomerEmail.topAnchor.constraint(equalTo: popupCustomerName.bottomAnchor, constant: 8),
            popupCustomerEmail.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            popupCustomerEmail.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            popupCustomerEmail.bottomAnchor.constraint(equalTo: popupCustomerPhone.topAnchor, constant: -8),
            
            popupCustomerPhone.topAnchor.constraint(equalTo: popupCustomerEmail.bottomAnchor, constant: 8),
            popupCustomerPhone.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            popupCustomerPhone.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            popupCustomerPhone.bottomAnchor.constraint(equalTo: popupButton.topAnchor, constant: -8),
            ])

        // PopupButton constraints
        popupButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupButton.heightAnchor.constraint(equalToConstant: 44),
            popupButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 15),
            popupButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -15),
            popupButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -8)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
