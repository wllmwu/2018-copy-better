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
    private var contents: NSAttributedString!
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // reset contentsLabel's font, text size, and text color
        var defaultSize: CGFloat = 17
        if let _ = self.titleLabel {
            defaultSize = 11
        }
        self.contentsLabel.attributedText = NSAttributedString(string: "", attributes: [
            .font : UIFont.systemFont(ofSize: defaultSize),
            .foregroundColor : UIColor.black
            ])
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
        self.contents = contents
        if contents.string.isEmpty {
            self.contentsLabel.text = "(Empty)"
            self.contentsLabel.textColor = UIColor.gray
        }
        else {
            // force text size in the label
            let text: NSMutableAttributedString = NSMutableAttributedString(attributedString: contents)
            if let _ = self.titleLabel {
                text.addAttribute(.font, value: UIFont.systemFont(ofSize: 11), range: NSMakeRange(0, text.length))
            }
            else {
                text.addAttribute(.font, value: UIFont.systemFont(ofSize: 17), range: NSMakeRange(0, text.length))
            }
            self.contentsLabel.attributedText = text
        }
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        ClipboardManager.copyToPasteboard(attributedString: self.contents)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        self.tableViewController?.addLastCopied()
    }

}
