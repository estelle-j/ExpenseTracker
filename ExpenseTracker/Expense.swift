//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Estelle Jezequel on 15/09/2020.
//  Copyright © 2020 Estelle Jezequel. All rights reserved.
//

import UIKit
import os.log

class Expense: NSObject, NSCoding {
    
    //MARK: Properties
    
    var name: String
    var descriptionText: String
    var amountBaseCurrency: String
    var dateExpense: Date
    var exchangeRate: Double
    
    //MARK: Archiving Paths
     
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ExpensesArchiveURL = DocumentsDirectory.appendingPathComponent("expensesData")
    
    
    //MARK: Types
    
    struct PropertyKey {
        static let name = "name"
        static let descriptionText = "description"
        static let amountEuro = "amountEuro"
        static let dateExpense = "dateExpense"
        static let exchangeRate = "exchangeRate"
    }
    
    //MARK: Initialization
    
    init?(name: String, descriptionText: String, amountEuro: String, dateExpense: Date, exchangeRate: Double) {
        // Initialization should fail if there is no name
        guard !name.isEmpty else {
            return nil
        }
        // Initialize stored properties
        self.name = name
        self.descriptionText = descriptionText
        self.amountBaseCurrency = name
        self.dateExpense = dateExpense
        self.exchangeRate = exchangeRate
    }
    
    //MARK: NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: PropertyKey.name)
        coder.encode(descriptionText, forKey: PropertyKey.descriptionText)
        coder.encode(amountBaseCurrency, forKey: PropertyKey.amountEuro)
        coder.encode(dateExpense, forKey: PropertyKey.dateExpense)
        coder.encode(exchangeRate, forKey: PropertyKey.exchangeRate)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {

        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for an Expense object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Because description is an optional property of Expense, just use conditional cast.
        guard let descriptionText = aDecoder.decodeObject(forKey: PropertyKey.descriptionText) else {
            return nil
        }
        
        guard let amountEuro = aDecoder.decodeObject(forKey: PropertyKey.amountEuro) else {
            return nil
        }
        
        guard let dateExpense = aDecoder.decodeObject(forKey: PropertyKey.dateExpense) as? Date else {
            os_log("Unable to decode the date for an Expense object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let exchangeRate = aDecoder.decodeObject(forKey: PropertyKey.exchangeRate) else {
            return nil
        }
        
        self.init(name: name, descriptionText: descriptionText as! String, amountEuro: amountEuro as! String, dateExpense: dateExpense, exchangeRate: exchangeRate as! Double)
    }
    
    //MARK: Private Methods
    
    /* Parse number for different keyboard, depending on the decimal separator used*/
    func parseNumber(_ text:String) -> Double? {

        // since we only support english localization, keyboard always show '.' as decimal separator,
        // hence we need to force en_US locale
        let fmtUS = NumberFormatter()
        fmtUS.locale = Locale(identifier: "en_US")
        if let number = fmtUS.number(from: text)?.doubleValue {
            print("parsed using \(fmtUS.locale)")
            return number
        }

        let fmtCurrent = NumberFormatter()
        fmtCurrent.locale = Locale.current
        if let number = fmtCurrent.number(from: text)?.doubleValue {
            print("parsed using \(fmtCurrent.locale)")
            return number
        }

        print("can't parse number")
        return nil
    }
    
    /* Set exchange rate to the expense */
    func setExchangeRate(exchangeRate: Double) {
        self.exchangeRate = exchangeRate
    }
    
    /* Set amount in the base currency */
    func setAmountBaseCurrency() {
        var baseCurrencyAmount = parseNumber(self.name) ?? 0.0
        // Apply exchange rate
        baseCurrencyAmount = baseCurrencyAmount / exchangeRate
        let baseCurrencyAmountString = String(format: "%.2f", baseCurrencyAmount).replacingOccurrences(of: ".", with: Locale.current.decimalSeparator!, options: .literal, range: nil)
        self.amountBaseCurrency = baseCurrencyAmountString
    }

    
}
