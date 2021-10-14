//
//  VeiwRaffleDetailViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 19/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class VeiwRaffleDetailViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    var raffle: Raffle?
    var customers: [Customer]?
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var startLabel: UILabel!
    @IBOutlet var endLabel: UILabel!
    @IBOutlet var drawnMethodLabel: UILabel!
    @IBOutlet var ticketAmountLabel: UILabel!
    @IBOutlet var soldLabel: UILabel!
    @IBOutlet var prizeLabel: UILabel!
    @IBOutlet var drawButton: UIButton!
    @IBOutlet weak var sellTicketButton: UIBarButtonItem!
    @IBOutlet var seeTicketsButton: UIButton!
    @IBOutlet weak var tickePriceLabel: UILabel!
    
    @IBOutlet weak var ticketSellView: UIView!
    @IBOutlet weak var selectCustomerField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var ticketNumberField: UITextField!
    @IBOutlet var createCustomerField: UITextField!
    @IBOutlet var customerNameField: UILabel!
    @IBOutlet var totalPriceField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(getter: UICommandAlternate.action))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        raffle = database.selectRaffleByID(id: raffle!.raffleID)
        setWidgets()
        self.title = raffle?.name.uppercased()
        ticketSellView.isHidden = true
        
//        customers = database.selectAllCustomers()
//        if customers?.count ?? 0 > 0 {
//            setPicker()
//            dismissPickerView()
//        }
        
    }
    
    @objc func action() {
          view.endEditing(true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        customerNameField.text = createCustomerField.text
        emailField.text = ""
        phoneField.text = ""
        emailField.isEnabled = true
        phoneField.isEnabled = true
    }
    
    @objc func calculateTotalPrice(_ textField: UITextField) {
        let number = Int(ticketNumberField.text ?? "") ?? 0
        if number > 0 {
            totalPriceField.text = "$"+String(Double(number) * raffle!.ticketPrice)
        } else {
            totalPriceField.text = ""
        }
    }
    
    func setWidgets() {
        createCustomerField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        ticketNumberField.addTarget(self, action: #selector(calculateTotalPrice(_:)), for: .editingChanged)
        // Set Raffle Status
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let today = Date()
        
        var status:String
        let startDate = dateFormatter.date(from: raffle!.startDate)
        let endDate = dateFormatter.date(from: raffle!.endDate)
        let tickets = database.selectTicketsByRaffle(id: raffle!.raffleID)
        if today > endDate! || tickets.count >= raffle!.ticketAmount {
            status = "Due"
            statusLabel.textColor = UIColor.systemRed
            drawButton.isEnabled = true
            drawButton.alpha = 1
            sellTicketButton.isEnabled = false
        } else if today > startDate! {
            status = "In progress"
            statusLabel.textColor = UIColor.systemGreen
            sellTicketButton.isEnabled = true
        } else {
            status = "Holding"
            statusLabel.textColor = UIColor.systemBlue
            sellTicketButton.isEnabled = false
        }
        
        if tickets.count < 1 {
            drawButton.isEnabled = false
            drawButton.alpha = 0.5
            seeTicketsButton.isHidden = true
        } else {
            seeTicketsButton.isHidden = false
        }
        
        tickePriceLabel.text = "$" + String(format:"%.2f", raffle!.ticketPrice)
        statusLabel.text = status
        startLabel.text = raffle?.startDate
        endLabel.text = raffle?.endDate
        drawnMethodLabel.text = raffle?.drawnMethod
        ticketAmountLabel.text = String(raffle!.ticketAmount)
        soldLabel.text = String(tickets.count)
        prizeLabel.text = "$" + String(format: "%.2f", Double(tickets.count) * raffle!.ticketPrice)
        
        if raffle?.status == "completed" {
            statusLabel.text = raffle?.status
            drawButton.setTitle("Raffle Completed", for: .normal)
            drawButton.isEnabled = false
            drawButton.alpha = 0.5
        }
    }
    
    @IBAction func sellButtonClicked(_ sender: Any) {
        ticketSellView.isHidden = false
        
        customers = database.selectAllCustomers()
        if customers!.count > 0 {
            selectCustomerField.isEnabled = true;
            setPicker()
            dismissPickerView()
        } else {
            selectCustomerField.isEnabled = false;
        }
    }
    
    @IBAction func confirmButtonClicked(_ sender: Any) {
        let customerName = customerNameField.text
        let email = emailField.text
        let phone = phoneField.text
        let ticketNumber = ticketNumberField.text
        
        if customerName?.isEmpty ?? true || email?.isEmpty ?? true || phone?.isEmpty ?? true || ticketNumber?.isEmpty ?? true {
            presentAlert(with: "Must fill in all the fields to save your ticket")
        } else if let customer = database.selectCustomerByName(name: customerName!) {
            let purchaseNumber = Int(ticketNumber!)!
            let ticketsForCustomer = database.selectTicketsByRaffleCustomer(raffleID: raffle!.raffleID, customerID: customer.customerID)
            let ticketsForRaffle = database.selectTicketsByRaffle(id: raffle!.raffleID)
            
            if ticketsForCustomer.count + purchaseNumber > raffle!.purchaseLimit {
                presentAlert(with: "Can only buy \(raffle!.purchaseLimit) tickets for customer \(customerName!)")
            } else if ticketsForRaffle.count + purchaseNumber > raffle!.ticketAmount {
                presentAlert(with: "Tickets sold out, please reduce the number or choose another raffle")
            } else {
                // buy ticket
                buyTicketsForCustomer(customer: customer, number: purchaseNumber)
                presentAlert(with:  "\(String(purchaseNumber)) ticket(s) is/are sold to \(customerName!)")
                setWidgets()
            }
        } else {
            let purchaseNumber = Int(ticketNumber!)!
            let ticketsForRaffle = database.selectTicketsByRaffle(id: raffle!.raffleID)
            
            if purchaseNumber > raffle!.purchaseLimit {
                presentAlert(with: "Can only buy \(raffle!.purchaseLimit) tickets for customer \(customerName!)")
            } else if ticketsForRaffle.count + purchaseNumber > raffle!.ticketAmount {
                presentAlert(with: "Tickets sold out, please reduce the number or choose another raffle")
            } else {
                // buy ticket, insert customer
                database.insert(customer: Customer(name: customerName!, email: email!, phone: Int32(phone!)!))
                let customer = database.selectCustomerByName(name: customerName!)
                buyTicketsForCustomer(customer: customer!, number: purchaseNumber)
                presentAlert(with:  "\(String(purchaseNumber)) ticket(s) is/are sold to \(customerName!)")
                updateCustomerList()
                setWidgets()
            }
        }
        ticketSellView.isHidden = true
    }
    
    func buyTicketsForCustomer(customer: Customer, number: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let today = dateFormatter.string(from: Date())
        let ticketsForRaffle = database.selectTicketsByRaffle(id: raffle!.raffleID)
        
        if raffle?.drawnMethod == "Manual" {
            var i = 0
            while i < number {
                i += 1
                let ticket = Ticket(raffleID: raffle!.raffleID, customerID: customer.customerID, ticketNo: Int32(ticketsForRaffle.count + i), purchaseDate: today)
                database.insert(ticket: ticket)
            }
        } else if raffle?.drawnMethod == "Margin" {
            var i = 0
            var ticketsNumber: [Int] = [Int]()
            for existingTicket in ticketsForRaffle {
                ticketsNumber.append(Int(existingTicket.ticketNo))
            }
            while i < number { // randomly assign ticket number for multiple purchases.
                var number = Int.random(in: 1 ... Int(raffle!.ticketAmount))
                while ticketsNumber.contains(number) {
                    number = Int.random(in: 1 ... Int(raffle!.ticketAmount))
                }
                ticketsNumber.append(number)
                let ticket = Ticket(raffleID: raffle!.raffleID, customerID: customer.customerID, ticketNo: Int32(number), purchaseDate: today)
                database.insert(ticket: ticket)
                i += 1
            }
        }
    }
    
    func updateCustomerList() {
        customers = database.selectAllCustomers()
    }
    
    // ------- START SETTING PICKER ------- //
    func setPicker() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        selectCustomerField.inputView = pickerView
    }
    
    func dismissPickerView() {
       let toolBar = UIToolbar()
       toolBar.sizeToFit()
       let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.action))
       toolBar.setItems([button], animated: true)
       toolBar.isUserInteractionEnabled = true
       selectCustomerField.inputAccessoryView = toolBar
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // number of session
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return customers?.count ?? 0 // number of dropdown items
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return customers?[row].name // dropdown item
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectCustomerField.text = customers![row].name // selected item
        customerNameField.text = customers![row].name
        emailField.text = customers![row].email
        phoneField.text = String(customers![row].phone)
        emailField.isEnabled = false
        phoneField.isEnabled = false
    }
    // ------- END SETTING PICKER ------- //
    
    func presentAlert(with message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showTicketsSegue"
        {
            guard let ticketTableViewController = segue.destination as? TicketTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            let currentRaffle = raffle
            ticketTableViewController.raffle = currentRaffle!
        }
        
        if segue.identifier == "drawSegue" {
            guard let raffleDrawViewController = segue.destination as? RaffleDrawViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            let currentRaffle = raffle
            raffleDrawViewController.raffle = currentRaffle
        }
    }
}
