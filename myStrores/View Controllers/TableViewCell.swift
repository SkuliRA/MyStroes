//
//  TableViewCell.swift
//  myStrores
//
//  Created by Skuli on 14.02.2023.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var store1Label: UILabel!
    @IBOutlet weak var store2Label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
