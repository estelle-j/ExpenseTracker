//
//  ExpenseTableViewCell.swift
//  ExpenseTracker
//
//  Created by Estelle Jezequel on 15/09/2020.
//  Copyright © 2020 Estelle Jezequel. All rights reserved.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var euroAmountLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
