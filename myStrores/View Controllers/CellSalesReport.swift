//
//  CellSalesReport.swift
//  myStrores
//
//  Created by Skuli on 27.02.2023.
//

import UIKit

class CellSalesReport: UITableViewCell {
    
    @IBOutlet weak var art: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var bonus: UILabel!
    @IBOutlet weak var manDisc: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var quantity: UILabel!
    @IBOutlet weak var size: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var store: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
