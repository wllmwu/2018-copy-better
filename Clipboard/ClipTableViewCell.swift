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
    @IBOutlet weak var contentsImageView: UIImageView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var addButton: UIButton?
    
    private var contents: [String : Any]!
    private var tableViewController: MainTableViewController?
    
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
        
        self.reset()
    }
    
    private func reset() {
        // reset contentsLabel's font, text size, and text color
        var defaultSize: CGFloat = 17
        if let _ = self.titleLabel {
            defaultSize = 11
        }
        self.contentsLabel.font = UIFont.systemFont(ofSize: defaultSize)
        self.contentsLabel.textColor = UIColor.black
    }
    
    private func setContentsLabelText() {
        if self.contents.count == 0 {
            self.contentsLabel.text = "(Empty)"
            self.contentsLabel.textColor = UIColor.gray
            return
        }
        
        self.reset()
        let imageViewHeight = self.contentsImageView.bounds.height
        DispatchQueue.global(qos: .utility).async {
            if let rtf = ClipboardManager.textFromRtf(inItem: self.contents) {
                DispatchQueue.main.async {
                    self.setContentsLabelAttributedText(rtf)
                }
            }
            else if let html = ClipboardManager.textFromHtml(inItem: self.contents) {
                DispatchQueue.main.async {
                    self.setContentsLabelAttributedText(html)
                }
            }
            else if let plaintext = ClipboardManager.textFromPlaintext(inItem: self.contents) {
                DispatchQueue.main.async {
                    self.contentsLabel.text = plaintext
                }
            }
            else if let image = ClipboardManager.imageFromImage(inItem: self.contents, maxImageWidth: nil, maxImageHeight: imageViewHeight) {
                DispatchQueue.main.async {
                    self.contentsLabel.text = ""
                    self.contentsImageView.image = image
                }
            }
            else {
                print("ClipTableViewCell: couldn't find usable data representations.")
            }
        }
    }
    
    private func setContentsLabelAttributedText(_ attributedString: NSAttributedString) {
        // remove font and attachments
        let string: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        string.removeAttribute(.font, range: NSMakeRange(0, string.length))
        string.enumerateAttribute(NSAttributedStringKey.attachment, in: NSMakeRange(0, string.length), options: []) { (value, range, stop) in
            if let _ = value as? NSTextAttachment {
                string.replaceCharacters(in: range, with: "")
            }
        }
        self.contentsLabel.attributedText = attributedString
    }
    
    func setTableViewController(_ table: MainTableViewController) {
        self.tableViewController = table
    }
    
    func setTitle(_ title: String) {
        if let label = self.titleLabel {
            label.text = title
        }
    }
    
    func setContents(_ contents: [String : Any]) {
        self.contents = contents
        self.setContentsLabelText()
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        ClipboardManager.copyToPasteboard(item: self.contents)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        self.tableViewController?.addLastCopied()
    }

}
