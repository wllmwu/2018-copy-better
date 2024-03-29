//
//  WidgetClipTableViewCell.swift
//  Clips Widget
//
//  Created by William Wu on 11/30/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import ClipsKit

class WidgetClipTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var contentsImageView: UIImageView!
    @IBOutlet weak var copyButton: UIButton?
    @IBOutlet weak var addButton: UIButton?
    
    private var contents: [String : Any]!
//    private var parentViewController: TodayViewController!

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
        
        self.contentsImageView.image = nil
    }
    
//    func setParentViewController(_ viewController: TodayViewController) {
//        self.parentViewController = viewController
//    }
    
    func setTitle(_ title: String) {
        if let label = self.titleLabel {
            label.text = title
        }
    }
    
    func setContents(_ item: [String : Any]) {
        self.contents = item
        self.contentsLabel.textColor = UIColor.label
        self.contentsImageView.image = nil
        
        if item.count == 0 {
            self.contentsLabel.text = AppStrings.EMPTY_CLIP_PLACEHOLDER
            self.contentsLabel.textColor = UIColor.secondaryLabel
        }
        else {
            let imageViewSize: CGSize = self.contentsImageView.bounds.size
            DispatchQueue.global(qos: .utility).async {
                if let plaintext = ClipboardManager.stringFromPlaintext(inItem: item) {
                    DispatchQueue.main.async {
                        self.contentsLabel.text = plaintext.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                else if let rtf = ClipboardManager.attributedStringFromRtf(inItem: item) {
                    DispatchQueue.main.async {
                        self.contentsLabel.text = rtf.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                else if let html = ClipboardManager.attributedStringFromHtml(inItem: item) {
                    DispatchQueue.main.async {
                        self.contentsLabel.text = html.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                else if let image = ClipboardManager.imageFromImage(inItem: item, maxWidth: imageViewSize.width, maxHeight: imageViewSize.height) {
                    DispatchQueue.main.async {
                        self.contentsLabel.text = ""
                        self.contentsImageView.image = image
                    }
                }
                else {
                    print("Couldn't find usable data representations.")
                    self.contentsLabel.text = "\u{fffd}"
                }
            }
        }
    }
    
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        ClipboardManager.copyToPasteboard(item: self.contents)
        sender.setTitle(AppStrings.TOAST_MESSAGE_COPIED, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
            sender.setTitle(AppStrings.COPY_BUTTON_TITLE, for: .normal)
        })
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        if self.contents.count > 0 {
            NotificationCenter.default.post(name: Notification.Name("AddLastCopiedInWidget"), object: nil)
            sender.setTitle(AppStrings.TOAST_MESSAGE_ADDED, for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: {
                sender.setTitle(AppStrings.ADD_BUTTON_TITLE, for: .normal)
            })
        }
    }
    
}
