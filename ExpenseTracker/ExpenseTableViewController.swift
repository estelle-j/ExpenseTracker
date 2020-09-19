//
//  ExpenseTableViewController.swift
//  ExpenseTracker
//
//  Created by Estelle Jezequel on 15/09/2020.
//  Copyright © 2020 Estelle Jezequel. All rights reserved.
//

import UIKit
import os.log

class ExpenseTableViewController: UITableViewController, XMLParserDelegate {
    
    
    //MARK: Properties
    var parser = XMLParser()
    var observationArray = [Observation]()
    var expenses = [Expense]()
    
    // Change the designator if you want to change the currency
    let currencyDesignator = "usd"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem

        // Load any saved expenses, otherwise load sample data.
        if let savedExpenses = loadExpenses() {
            expenses += savedExpenses
        }

        // Get euro reference exchange rates
        
        let urlString = URL(string: "https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/" + currencyDesignator + ".xml")
        
        // Parse exchange rates
        self.parser = XMLParser(contentsOf: urlString!)!
        self.parser.delegate = self
        let success:Bool = self.parser.parse()
        if success {
            print("success")
        } else {
            print("parse failure!")
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expenses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ExpenseTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ExpenseTableViewCell else {
            fatalError("The dequeued cell is not an instance of ExpenseTableViewCell.")
        }
        
        let expense = expenses[indexPath.row]

        // Configure the cell...
        cell.nameLabel.text = expense.name + " $"
        cell.euroAmountLabel.text = expense.amountBaseCurrency + " €"
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        cell.dateLabel.text = formatter.string(from: expense.dateExpense)

        return cell
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            expenses.remove(at: indexPath.row)
            saveExpenses()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        super.prepare(for: segue, sender: sender)
        
        switch (segue.identifier ?? "") {
            
        case "AddItem":
            os_log("Adding a new expense.", log: OSLog.default, type: .debug)
            
        case "ShowDetail":
            guard let expenseDetailViewController = segue.destination as? ExpenseViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
             
            guard let selectedExpenseCell = sender as? ExpenseTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
             
            guard let indexPath = tableView.indexPath(for: selectedExpenseCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
             
            let selectedExpense = expenses[indexPath.row]
            expenseDetailViewController.expense = selectedExpense

        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    //MARK: Actions
    
    @IBAction func unwindToExpenseList(sender: UIStoryboardSegue) {

        if let sourceViewController = sender.source as? ExpenseViewController, let expense = sourceViewController.expense {
            
            expense.setExchangeRate(exchangeRate: getExchangeRate(date: expense.dateExpense))
            
            // Set amount in euro
            expense.setAmountBaseCurrency()

            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing expense.
                expenses[selectedIndexPath.row] = expense
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            } else {
                // Find index to add the cell
                let newIndexPath = IndexPath(row: expenses.count, section: 0)
                
                // Add a new expense
                expenses.append(expense)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            // Save the expenses.
            saveExpenses()
        }
    }
    
    
    //MARK: XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if(elementName=="Obs")
        {
            let observation = Observation()
            for string in attributeDict {
                let strvalue = string.value as NSString
                switch string.key {
                  case "TIME_PERIOD":
                    // Get date of the exchange rate
                    let obsDate = strvalue as String
                    let obsComponents = obsDate.components(separatedBy: "-")
                    let calendar = Calendar(identifier: .gregorian)
                    let dateComponents = DateComponents(year: Int(obsComponents[0]), month: Int(obsComponents[1]), day: Int(obsComponents[2]))
                    observation.date = calendar.date(from: dateComponents)!
                    break
                  case "OBS_VALUE":
                    // Get value of the exchange rate
                    observation.rate = Double(strvalue as String)!
                    break
                  default:
                    break
                }
            }
            observationArray.append(observation)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
    
    
    //MARK: Private Methods
    
    private func saveExpenses() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(expenses, toFile: Expense.ExpensesArchiveURL.path)

        if isSuccessfulSave {
            os_log("Expenses successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save expenses...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadExpenses() -> [Expense]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Expense.ExpensesArchiveURL.path) as? [Expense]
    }
    
    /* Find exchange rate for a given date */
    private func getExchangeRate(date: Date) -> Double {
        
        var index = observationArray.count - 1
        var observationDate = observationArray[index].date
        while (index > -1) && (Calendar.current.compare(date, to: observationDate, toGranularity: .day) == .orderedAscending) {
            index = index - 1
            observationDate = observationArray[index].date
        }
        var rate = 1.0
        if (index != -1) {
            rate = observationArray[index].rate
        }
        return rate
    }

}
