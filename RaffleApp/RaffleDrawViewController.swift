//
//  raffleDrawViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 21/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class RaffleDrawViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    var raffle: Raffle!
    var tickets: [Ticket]!
//    var ticketNumberPool: [Int]!
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    
    @IBOutlet var raffleNameLabel: UILabel!
    @IBOutlet var drawMethodLabel: UILabel!
    
    @IBOutlet var manualChooseField: UITextField!
    @IBOutlet var winningTicketLabel: UILabel!
    @IBOutlet var completeButton: UIButton!
    @IBOutlet var manualRandomButton: UIButton!
    
    @IBOutlet var marginDrawView: UIView!
    @IBOutlet var teamAScoreField: UITextField!
    @IBOutlet var teamBScoreField: UITextField!
    @IBOutlet var calculateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(getter: UICommandAlternate.action))
        view.addGestureRecognizer(tap)
        
        marginDrawView.isHidden = true
        tickets = database.selectTicketsByRaffle(id: raffle.raffleID)
        initWidgets()
    }
    
    func initWidgets() {
        completeButton.isHidden = true
        raffleNameLabel.text = raffle.name
        drawMethodLabel.text = raffle.drawnMethod
        
        if raffle.drawnMethod == "Manual" {
            setPicker()
        } else if raffle.drawnMethod == "Margin" {
            marginDrawView.isHidden = false
        }
    }
    
    @IBAction func manualRandomSelect(_ sender: Any) {
        let number = Int.random(in: 1 ... tickets.count)
        winningTicketLabel.text = String(number)
        manualChooseField.text = ""
        manualChooseField.resignFirstResponder()
        completeButton.isHidden = false
    }
    
    @IBAction func calculateTicket(_ sender: Any) {
        let inputA = teamAScoreField.text
        let inputB = teamBScoreField.text
        if inputA?.isEmpty ?? true || inputB?.isEmpty ?? true {
            presentAlert(with: "Please input scores")
        } else {
            let numberA = Int(inputA!)
            let numberB = Int(inputB!)
            let ticketNumber = String(abs(numberA! - numberB!))
            winningTicketLabel.text = ticketNumber
            
            let ticket = database.selectTicketByRaffleTicket(raffleID: raffle.raffleID, ticketNo: Int32(ticketNumber)!)
            
            if ticket == nil {
                completeButton.setTitle("Nobody wins this Raffle", for: .normal)
                presentAlert(with: "No lucky winner. Raffle finished")
                updateRaffleStatus(with: "no winner")
            } else {
                let customer = database.selectCustomerByID(id: ticket!.customerID)
                completeButton.setTitle("Congrats! Lucky Ticket \(ticketNumber)!", for: .normal)
                presentAlert(with: "Winner created. Please go back")
                updateRaffleStatus(with: customer!.name)
            }
            completeButton.isHidden = false
            completeButton.alpha = 0.5
            completeButton.isEnabled = false
            teamAScoreField.isEnabled = false
            teamBScoreField.isEnabled = false
            calculateButton.isEnabled = false
            calculateButton.alpha = 0.5
            
//            updateRaffleStatus()
        }
    }
    
    // ------- START SETTING PICKER ------- //
    func setPicker() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        manualChooseField.inputView = pickerView
    }
    
    func dismissPickerView() {
       let toolBar = UIToolbar()
       toolBar.sizeToFit()
       let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.action))
       toolBar.setItems([button], animated: true)
       toolBar.isUserInteractionEnabled = true
       manualChooseField.inputAccessoryView = toolBar
    }
    
    @objc func action() {
          view.endEditing(true)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // number of session
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return tickets.count // number of dropdown items
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(tickets[row].ticketNo) // dropdown item
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        manualChooseField.text = String(tickets[row].ticketNo) // selected item
        winningTicketLabel.text = String(tickets[row].ticketNo)
        completeButton.isHidden = false
    }
    // ------- END SETTING PICKER ------- //
    
    @IBAction func completeButtonClicked(_ sender: Any) {
        let winningNumber = winningTicketLabel.text!
        let ticket = database.selectTicketByRaffleTicket(raffleID: raffle.raffleID, ticketNo: Int32(winningNumber)!)
        let customer = database.selectCustomerByID(id: ticket!.customerID)
        updateRaffleStatus(with: customer!.name)
        
        manualRandomButton.isEnabled = false
        manualRandomButton.alpha = 0.5
        
        manualChooseField.isEnabled = false
        
        completeButton.setTitle("Congrats! Lucky Ticket \(winningNumber)!", for: .normal)
        completeButton.alpha = 0.5
        completeButton.isEnabled = false
        presentAlert(with: "Winner created. Please go back")
    }
    
    func presentAlert(with message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateRaffleStatus(with customer: String) {
        raffle.status = "completed"
        raffle.winner = customer
        database.updateRaffleStatus(raffle: raffle)
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
