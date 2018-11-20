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
    
    private var clip: Clip?
    private var tableViewController: MainTableViewController?
    
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
            titleLabel.text = clip.title
        }
        
        self.setContents(clip.contents)
    }
    
    func getClip() -> Clip? {
        return self.clip
    }
    
    func setTableViewController(_ table: MainTableViewController) {
        self.tableViewController = table
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
        if let clip = self.clip {
            ClipboardManager.copyToPasteboard(attributedString: clip.contents)
        }
        else {
            ClipboardManager.copyToPasteboard(attributedString: NSAttributedString())
        }
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        self.tableViewController?.addLastCopied()
    }

}
