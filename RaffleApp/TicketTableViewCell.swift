//
//  TicketTableViewCell.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 20/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class TicketTableViewCell: UITableViewCell {
    @IBOutlet var customerName: UILabel!
    @IBOutlet var ticketNumber: UILabel!
    @IBOutlet var purchaseDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
