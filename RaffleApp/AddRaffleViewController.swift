//
//  EditRaffleViewController.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 19/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

extension UITextField {

    func addInputViewDatePicker(target: Any, selector: Selector) {

        let screenWidth = UIScreen.main.bounds.width

        //Add DatePicker as inputView
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 216))
        datePicker.datePickerMode = .date
        self.inputView = datePicker

        //Add Tool Bar as input AccessoryView
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelPressed))
        let doneBarButton = UIBarButtonItem(title: "Done", style: .plain, target: target, action: selector)
        toolBar.setItems([cancelBarButton, flexibleSpace, doneBarButton], animated: false)

        self.inputAccessoryView = toolBar
    }

    @objc func cancelPressed() {
        self.resignFirstResponder()
    }
}

extension UIImage {
    // extend UIImage with a method to write the image as a JPG to the Documents directory
    // and return the actual filename (not path!) for that image
    // all you need to do is provide a filename for the image
    func save(as filename: String) -> String {
        let filepath: String = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true).first!

        let fileurl = URL(fileURLWithPath: filepath)
            .appendingPathComponent(filename)
            .deletingPathExtension()
            .appendingPathExtension("jpeg") // ensure file extension is JPEG, and not something else

        do {
            try self.jpegData(compressionQuality: 0.75 )?.write(to: fileurl)
        }
        catch {
            print("failed to save image as JPG at \(fileurl)")
        }
        return fileurl.lastPathComponent    // return the actual filename (without the path)
    }
}

class AddRaffleViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var raffleNameField: UITextField!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet var startDateField: UITextField!
    @IBOutlet var endDateField: UITextField!
    @IBOutlet var methodPicker: UITextField!
    @IBOutlet var ticketAmountField: UITextField!
    @IBOutlet var ticketPriceLabel: UITextField!
    @IBOutlet var ticketLimitField: UITextField!
    @IBOutlet weak var raffleImage: UIImageView!
    
    var currentDate: String?
    var selectedMethod: String?
    var methods = ["Manual", "Margin"]
    let database : SQLiteDatabase = SQLiteDatabase(databaseName: "MyDatabase")
    var imageName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(getter: UICommandAlternate.action))
        view.addGestureRecognizer(tap)
        startDateField.addInputViewDatePicker(target: self, selector: #selector(startDoneButtonPressed))
        endDateField.addInputViewDatePicker(target: self, selector: #selector(endDoneButtonPressed))
        setPicker()
        dismissPickerView()
        setOtherFields()
    }
    
    @objc func startDoneButtonPressed() {
        if let  datePicker = self.startDateField.inputView as? UIDatePicker {
//            datePicker.minimumDate = Date() //Today's date
            let maximum = Date().addingTimeInterval(60 * 60 * 24 * 30) //30 days forward time from today.
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            
            let pickedDate = datePicker.date
            
            if pickedDate > maximum {
                presentAlert(with: "Start date cannot be over 30 days!")
            } else {
                self.startDateField.text = dateFormatter.string(from: pickedDate)
                endDateField.isEnabled = true
                currentDate = startDateField.text
            }
        }
        self.startDateField.resignFirstResponder()
    }

    @objc func endDoneButtonPressed() {
        if let  datePicker = self.endDateField.inputView as? UIDatePicker {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            
            let minimumDate = dateFormatter.date(from: currentDate!)
            let minimum = minimumDate!.addingTimeInterval(60 * 60 * 24) //the day after start date
            let maximum = minimumDate!.addingTimeInterval(60 * 60 * 24 * 31) //31 days forward time from start date.
            
            let pickedDate = datePicker.date
            
            if pickedDate > maximum || pickedDate < minimum {
                presentAlert(with: "End date should be within 31 days from start date")
            } else {
                self.endDateField.text = dateFormatter.string(from: pickedDate)
            }
        }
        self.endDateField.resignFirstResponder()
    }
    
    // ------- START SETTING PICKER ------- //
    func setPicker() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        methodPicker.inputView = pickerView
    }
    
    func dismissPickerView() {
       let toolBar = UIToolbar()
       toolBar.sizeToFit()
       let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.action))
       toolBar.setItems([button], animated: true)
       toolBar.isUserInteractionEnabled = true
       methodPicker.inputAccessoryView = toolBar
    }
    
    @objc func action() {
          view.endEditing(true)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // number of session
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return methods.count // number of dropdown items
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return methods[row] // dropdown item
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedMethod = methods[row] // selected item
        methodPicker.text = selectedMethod
//        self.dismissPickerView()
    }
    // ------- END SETTING PICKER ------- //
    
    func setOtherFields() {
        ticketAmountField.delegate = self
        ticketAmountField.delegate = self
        ticketLimitField.delegate = self
        ticketAmountField.keyboardType = .numberPad
        ticketPriceLabel.keyboardType = .decimalPad
        ticketLimitField.keyboardType = .numberPad
    }
    
    // restricting the input value to digital number
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "0123456789").inverted
        return string.rangeOfCharacter(from: invalidCharacters) == nil
    }
    
    func presentAlert(with message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
              switch action.style{
              case .default:
                    print("default")

              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")
        }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    // ------- START Select Image -------- //
    @IBAction func imageSelectorClicked(_ sender: Any) {
        if checkAvailability() {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            presentAlert(with: "No available Media Source")
        }
    }
    
    // set selected image to image view && dismiss the source
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        if let image = info[.editedImage] 
        {
            // save the URL of the image (this URL still refers to the camera roll)
            // here we save the URL in a class variable imageUrl – this could be any
            // URL variable if yours
            let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL
        
            // set the aspect ratio for the picked image
            raffleImage.contentMode = .scaleAspectFit
            // copy the picked image into the view
            raffleImage.image = (image as! UIImage)
            dismiss(animated: true, completion: nil)
            
            // extract the image from the view, and save it as a PNG file in our Documents directory
            // is the imageURL that was picked non-nil?
            if let imageUrl = imageUrl {
                // yes - extract just the filename of the current image from the reference
                // (this is a UUID, so it’s a pretty unique name)
                let filename = (imageUrl.path as NSString).lastPathComponent
                // make a copy of the image that is in the UIImageView and save it as a
                // JPEG in the Documents directory, using that UIImage extension from earlier
                imageName = raffleImage.image!.save(as: filename)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        dismiss(animated: true, completion: nil)
    }

    func checkAvailability() -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        {
            print("PhotoLibrary available")
            return true
        }
        else
        {
            print("No photoLibrary available")
            return false
        }
    }
    // ------- END Select Image -------- //
    
    @IBAction func saveRaffle(_ sender: Any) {
        let name = raffleNameField.text
        let description = descriptionText.text
        let drawnMethod = methodPicker.text
        let startDate = startDateField.text
        let endDate = endDateField.text
        let ticketAmount = ticketAmountField.text
        let ticketPrice = ticketPriceLabel.text
        let purchaseLimit = ticketLimitField.text
        let image = imageName
        
        if name?.isEmpty ?? true || description?.isEmpty ?? true || drawnMethod?.isEmpty ?? true || startDate?.isEmpty ?? true || endDate?.isEmpty ?? true || ticketAmount?.isEmpty ?? true || ticketPrice?.isEmpty ?? true || purchaseLimit?.isEmpty ?? true || image?.isEmpty ?? true {
            presentAlert(with: "Must fill in all the fields and select an image to save your raffle")
        } else {
            let raffle: Raffle = Raffle(name: name!, description: description!, drawnMethod: drawnMethod!, startDate: startDate!, endDate: endDate!, status: "not completed", ticketAmount: Int32(ticketAmount!)!, ticketPrice: Double(ticketPrice!)!, purchaseLimit: Int32(purchaseLimit!)!, image: image!)
            database.insert(raffle: raffle)
            presentAlert(with: "Successfully add a raffle")
        }
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
