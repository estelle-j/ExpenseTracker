//
//  StringProtocolExtension.swift
//  ExpenseTracker
//
//  Created by Estelle Jezequel on 17/09/2020.
//  Copyright © 2020 Estelle Jezequel. All rights reserved.
//

import Foundation

extension StringProtocol {
    var firstUppercased: String { return prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { return prefix(1).capitalized + dropFirst() }
}
