//
//  WidgetClipTableViewCell.swift
//  Clipboard Widget
//
//  Created by Bill Wu on 11/30/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class WidgetClipTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton?
    @IBOutlet weak var addButton: UIButton?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
