//
//  PastRaffleTableViewCell.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 21/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import UIKit

class PastRaffleTableViewCell: UITableViewCell {
    @IBOutlet var raffleImage: UIImageView!
    @IBOutlet var raffleName: UILabel!
    @IBOutlet var raffleDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
