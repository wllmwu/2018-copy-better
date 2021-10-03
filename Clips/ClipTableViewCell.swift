//
//  ClipTableViewCell.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import ClipsKit

class ClipTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var contentsImageView: UIImageView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var addButton: UIButton?
    @IBOutlet weak var favoriteIcon: UIImageView?
    
    @IBOutlet weak var primaryLabelToEdge: NSLayoutConstraint?
    @IBOutlet weak var primaryLabelToFavoriteIcon: NSLayoutConstraint?
    
    private var contents: [String : Any]!
    private var clip: Clip!
    
    /*
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
    */
    
    // MARK: - Public setters
    
    func setClip(_ clip: Clip) {
        self.clip = clip
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
    
    func setFavorite(_ isFavorite: Bool) {
        if isFavorite {
            self.favoriteIcon?.isHidden = false
            self.primaryLabelToEdge?.priority = .defaultLow
            self.primaryLabelToFavoriteIcon?.priority = .defaultHigh
        }
        else {
            self.primaryLabelToFavoriteIcon?.priority = .defaultLow
            self.primaryLabelToEdge?.priority = .defaultHigh
            self.favoriteIcon?.isHidden = true
        }
    }
    
    // MARK: - Instance methods
    
    /**
     Resets the contents label and image view, the favorite icon, and the constraints associated with the favorite icon.
     */
    private func reset() {
        // reset contentsLabel's font, text size, and text color
        var defaultSize: CGFloat = 17
        if let _ = self.titleLabel {
            defaultSize = 11
        }
        self.contentsLabel.font = UIFont.systemFont(ofSize: defaultSize)
        self.contentsLabel.textColor = UIColor.label
        self.contentsImageView.image = nil
        self.primaryLabelToFavoriteIcon?.priority = .defaultLow
        self.primaryLabelToEdge?.priority = .defaultHigh
        self.favoriteIcon?.isHidden = true
    }
    
    /**
     Displays the contents of this cell's assigned clip in the best available format (including image types), or displays a placeholder if the contents are empty or have no usable format.
     */
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
    
    /**
     Sets the cell's contents label text as an attributed string, without special font or attachment attributes.
     */
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
    
    // MARK: - Interface actions
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        ClipboardManager.copyToPasteboard(item: self.contents)
        if let clip = self.clip {
            Clip.donateCopyInteraction(with: clip) { (error) in
                if let e = error {
                    print("Interaction donation failed: \(e.localizedDescription)")
                }
            }
        }
        NotificationCenter.default.post(name: Notification.Name("ShowCopiedToast"), object: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        if self.contents.count > 0 {
            NotificationCenter.default.post(name: Notification.Name("AddLastCopiedInMain"), object: nil)
        }
    }

}
