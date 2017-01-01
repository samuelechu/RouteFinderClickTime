//
//  DirectionsCell.swift
//  ClickTimeRouteFinder
//
//  Created by Samuel Chu on 12/31/16.
//  Copyright © 2016 Samuel Chu. All rights reserved.
//

import UIKit

class DirectionsCell: UITableViewCell {

    @IBOutlet weak var direction: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
