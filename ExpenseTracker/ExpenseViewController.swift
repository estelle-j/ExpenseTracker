//
//  ExpenseViewController.swift
//  ExpenseTracker
//
//  Created by Estelle Jezequel on 15/09/2020.
//  Copyright © 2020 Estelle Jezequel. All rights reserved.
//

import UIKit
import os.log

class ExpenseViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, XMLParserDelegate {

    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var descriptionTextView: UITextView!
    
    @IBOutlet weak var exchangeRateTextView: UITextView!
    
    @IBOutlet weak var amountEuroLabel: UILabel!
    
    @IBOutlet weak var dateTextField: UITextField!
    
    let datePicker = UIDatePicker()
    
    var parser = XMLParser()
    var observationArray = [Observation]()
    
    var expense: Expense?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Handle the text field's user input through delegate callbacks
        nameTextField.delegate = self
        
        descriptionTextView.delegate = self
        exchangeRateTextView.delegate = self
        exchangeRateTextView.isEditable = false
        
        dateTextField.delegate = self
        
        // Set descriptionTextView border color
        descriptionTextView.layer.borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
        descriptionTextView.layer.borderWidth = 1.0
        descriptionTextView.layer.cornerRadius = 5.0
        
        // Set first letter in uppercase only
        descriptionTextView.text.firstUppercased
        
        self.descriptionTextView.addDoneButton(title: "Done", target: self, selector: #selector(tapDone(sender:)))
        
        amountEuroLabel.text = ""
        
        self.dateTextField.addDoneButton(title: "Done", target: self, selector: #selector(tapDoneDate(sender:)))
        
        createDatePicker()
        
        // To change the language of the date picker, uncomment the following line and set the language
        //datePicker.locale = Locale.init(identifier: "fr_FR")
        
        self.dateTextField.inputView = datePicker
        
        // Set up views if editing an existing Expense.
        if let expense = expense {
            navigationItem.title = "Expense"
            nameTextField.text = expense.name
            descriptionTextView.text = expense.descriptionText
            // Set first letter in uppercase only
            descriptionTextView.text.firstUppercased
            
            amountEuroLabel.text = expense.amountBaseCurrency + " €"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            dateTextField.text = formatter.string(from: expense.dateExpense)
            
            exchangeRateTextView.text = "Exchange rate on " + formatter.string(from: expense.dateExpense) + ":\n\n" + "1 EUR = " + String(format: "%.4f", expense.exchangeRate).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator!, options: .literal, range: nil) + " USD\n" + "1 USD = " + String(format: "%.4f", 1/expense.exchangeRate).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator!, options: .literal, range: nil) + " EUR"
        }

        // Enable the Save button only if the text field has a valid Expense name.
        updateSaveButtonState()
        
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing
        saveButton.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
    
    
    //MARK: Navigation
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddExpenseMode = presentingViewController is UINavigationController
        
        if isPresentingInAddExpenseMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController {
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The ExpenseViewController is not inside a navigation controller.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        // Configure the destination view controller only when the save button is pressed.
        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let name = nameTextField.text ?? ""
        let descriptionText = descriptionTextView.text ?? ""
        let amountEuro = amountEuroLabel.text ?? ""
        let dateExpense = datePicker.date
        // Set the expense to be passed to ExpenseTableViewController after the unwind segue.
        expense = Expense(name: name, descriptionText: descriptionText, amountEuro: amountEuro, dateExpense: dateExpense, exchangeRate: 1)

    }

    
    //MARK: Private Methods
    
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    private func createDatePicker() {
        datePicker.datePickerMode = UIDatePicker.Mode.date
        
        let calendar = Calendar(identifier: .gregorian)
        let minimumDateComponents = DateComponents(year:1999 , month: 1, day: 4)
        datePicker.minimumDate = calendar.date(from: minimumDateComponents)
        datePicker.maximumDate = Date()
        // Set default date
        datePicker.date = Date()
    }
    
    // Remove keyboard when done editing
    @objc func tapDone(sender: Any) {
        self.view.endEditing(true)
    }
    
    @objc func tapDoneDate(sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateTextField.text = dateFormatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
        

}

