//
//  ClipTableViewCell.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class ClipTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    private var title: String?
    private var contents: String! = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(title: String, contents: String) {
        self.title = title
        self.contents = contents
        self.titleLabel.text = title
        self.contentsLabel.text = contents
    }
    
    func setup(contents: String) {
        self.title = nil
        self.contents = contents
        self.contentsLabel.text = contents
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        UIPasteboard.general.string = self.contents
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // use ClipboardManager to add the new clip
    }

}
