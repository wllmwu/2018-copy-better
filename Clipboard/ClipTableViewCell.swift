//
//  ClipTableViewCell.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class ClipTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var addButton: UIButton?
    
    private var clip: Clip!
    
    /*private let emptyContents = NSAttributedString(string: "Empty", attributes: [
        .font : UIFont.systemFont(ofSize: 11),
        .foregroundColor : UIColor.gray
        ])*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setClip(_ clip: Clip) {
        self.clip = clip
        
        if let titleLabel = self.titleLabel {
            titleLabel.text = self.clip.title
        }
        
        self.setContents(clip.contents)
    }
    
    func setContents(_ contents: NSAttributedString) {
        if contents.string.isEmpty {
            self.contentsLabel.text = "(Empty)"
            self.contentsLabel.textColor = UIColor.gray
        }
        else {
            self.contentsLabel.attributedText = contents
        }
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        //UIPasteboard.general.string = self.contents
        
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // use ClipboardManager to add the new clip
    }

}
