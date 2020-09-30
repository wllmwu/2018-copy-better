//
//  FolderTableViewCell.swift
//  Copy Better
//
//  Created by Bill Wu on 8/12/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    */
    
    func setName(_ name: String) {
        self.nameLabel.text = name
    }
    
}
