//
//  ClipTableViewCell.swift
//  Clips
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
    @IBOutlet weak var tempIdLabel: UILabel?
    
    private var contents: [String : Any]!
    
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
    
    // MARK: - Instance methods
    
    func tempSetID(id: Int16) { // TEMP
        if let label = self.tempIdLabel {
            label.text = String(format: "%d", id)
        }
    }
    
    private func reset() {
        // reset contentsLabel's font, text size, and text color
        var defaultSize: CGFloat = 17
        if let _ = self.titleLabel {
            defaultSize = 11
        }
        self.contentsLabel.font = UIFont.systemFont(ofSize: defaultSize)
        self.contentsLabel.textColor = UIColor.label
        self.contentsImageView.image = nil
    }
    
    private func setContentsLabelText() {
        if self.contents.count == 0 {
            self.contentsLabel.text = AppStrings.EMPTY_CLIP_PLACEHOLDER
            self.contentsLabel.textColor = UIColor.secondaryLabel
            return
        }
        
        self.reset()
        let imageViewSize: CGSize = self.contentsImageView.bounds.size
        DispatchQueue.global(qos: .utility).async {
            if let rtf = ClipboardManager.attributedStringFromRtf(inItem: self.contents) {
                DispatchQueue.main.async {
                    self.setContentsLabelAttributedText(rtf)
                }
            }
            else if let html = ClipboardManager.attributedStringFromHtml(inItem: self.contents) {
                DispatchQueue.main.async {
                    self.setContentsLabelAttributedText(html)
                }
            }
            else if let plaintext = ClipboardManager.stringFromPlaintext(inItem: self.contents) {
                DispatchQueue.main.async {
                    self.contentsLabel.text = plaintext.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            else if let image = ClipboardManager.imageFromImage(inItem: self.contents, maxWidth: imageViewSize.width, maxHeight: imageViewSize.height) {
                DispatchQueue.main.async {
                    self.contentsLabel.text = ""
                    self.contentsImageView.image = image
                }
            }
            else {
                DispatchQueue.main.async {
                    print("ClipTableViewCell: couldn't find usable data representations.")
                    self.contentsLabel.text = "\u{fffd}"
                }
            }
        }
    }
    
    private func setContentsLabelAttributedText(_ attributedString: NSAttributedString) {
        // remove font and attachments
        let string: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        string.removeAttribute(.font, range: NSMakeRange(0, string.length))
        string.enumerateAttribute(.attachment, in: NSMakeRange(0, string.length), options: []) { (value, range, stop) in
            if let _ = value as? NSTextAttachment {
                string.replaceCharacters(in: range, with: "")
            }
        }
        self.contentsLabel.attributedText = string
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
        NotificationCenter.default.post(name: Notification.Name("ShowCopiedToast"), object: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        if self.contents.count > 0 {
            NotificationCenter.default.post(name: Notification.Name("AddLastCopiedInMain"), object: nil)
        }
    }

}
