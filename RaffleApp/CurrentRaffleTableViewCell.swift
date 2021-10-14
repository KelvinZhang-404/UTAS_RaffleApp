//
//  CurrentRaffleTableViewCell.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 19/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit
// ignore this line, for testing git
class CurrentRaffleTableViewCell: UITableViewCell {
    @IBOutlet var raffleName: UILabel!
    @IBOutlet var raffleStatus: UILabel!
    @IBOutlet var raffleImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
