//
//  ClipsKeyboardCollectionViewCell.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 12/19/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class ClipsKeyboardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentsLabel: UILabel!
    
    @IBOutlet var contentsLabelLeadingToTitleLabel: NSLayoutConstraint!
    @IBOutlet var contentsLabelLeadingToEdge: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetConstraints()
    }
    
    private func resetConstraints() {
        self.contentsLabelLeadingToTitleLabel.priority = .defaultHigh
        self.contentsLabelLeadingToEdge.priority = .defaultLow
    }
    
    /*func setup(clip: Clip) {
        self.reset()
        if let title = clip.title {
            self.titleLabel.text = title
        }
        else {
            self.titleLabel.text = nil
            self.contentsLabelLeadingToTitleLabel.priority = .defaultLow
            self.contentsLabelLeadingToEdge.priority = .defaultHigh
        }
        self.setContents(clip.contents)
    }*/
    
    func setup(title clipTitle: String?, contents: String) {
        self.resetConstraints()
        if let title = clipTitle {
            self.titleLabel.text = title
        }
        else {
            self.titleLabel.text = nil
            self.contentsLabelLeadingToTitleLabel.priority = .defaultLow
            self.contentsLabelLeadingToEdge.priority = .defaultHigh
        }
        self.contentsLabel.text = contents
    }
    
    /*private func setContents(_ item: [String : Any]) {
        if item.count == 0 {
            self.contentsLabel.text = NSLocalizedString("(Empty)", comment: "empty clip contents placeholder")
            self.contentsLabel.textColor = UIColor.gray
            return
        }
        
        let imageViewSize: CGSize = self.contentsImageView.frame.size
        DispatchQueue.global(qos: .utility).async {
            if let rtf = ClipboardManager.textFromRtf(inItem: item) {
                DispatchQueue.main.async {
                    self.setContentsLabelAttributedText(rtf)
                }
            }
            else if let html = ClipboardManager.textFromHtml(inItem: item) {
                DispatchQueue.main.async {
                    self.setContentsLabelAttributedText(html)
                }
            }
            else if let plaintext = ClipboardManager.textFromPlaintext(inItem: item) {
                DispatchQueue.main.async {
                    self.contentsLabel.text = plaintext
                }
            }
            else if let image = ClipboardManager.imageFromImage(inItem: item, maxWidth: imageViewSize.width, maxHeight: imageViewSize.height) {
                DispatchQueue.main.async {
                    self.contentsLabel.text = ""
                    self.contentsImageView.image = image
                }
            }
            else {
                print("ClipsKeyboardCollectionViewCell: couldn't find usable data representations.")
                self.contentsLabel.text = "\u{fffd}"
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
    }*/
    
}
