//
//  FolderPickerTableViewCell.swift
//  Copy Better
//
//  Created by Bill Wu on 9/7/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import UIKit

class FolderPickerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var label: UILabel!

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
    
    // MARK: - Public setters
    
    /**
     Sets this cell's label to display the given string.
     */
    func setFolderName(_ name: String?) {
        self.label.text = name
    }
    
    /**
     Sets this cell's selection style and accessory type accordingly. Use for folders only, to indicate which folder is being moved.
     */
    func setSelectable(_ selectable: Bool) {
        if selectable {
            self.selectionStyle = .default
            self.accessoryType = .disclosureIndicator
            self.label.textColor = .label
        }
        else {
            self.selectionStyle = .none
            self.accessoryType = .none
            self.label.textColor = .systemGray
        }
    }
    
    /**
     Sets this cell's label to display the given string.
     */
    func setClipTitle(_ title: String?) {
        self.label.text = title
    }
    
    /**
     Sets this cell's label to display the given contents (converts to plaintext form).
     */
    func setClipContents(_ contents: [String : Any]) {
        if contents.count == 0 {
            self.label.text = AppStrings.EMPTY_CLIP_PLACEHOLDER
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            if let plaintext = ClipboardManager.stringFromPlaintext(inItem: contents) {
                DispatchQueue.main.async {
                    self.label.text = plaintext.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            else if let rtf = ClipboardManager.attributedStringFromRtf(inItem: contents) {
                DispatchQueue.main.async {
                    self.label.text = rtf.string.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            else if let html = ClipboardManager.attributedStringFromHtml(inItem: contents) {
                DispatchQueue.main.async {
                    self.label.text = html.string.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            else if let _ = ClipboardManager.imageFromImage(inItem: contents, maxWidth: 0, maxHeight: 0) {
                DispatchQueue.main.async {
                    self.label.text = AppStrings.IMAGE_CLIP_PLACEHOLDER
                }
            }
            else {
                DispatchQueue.main.async {
                    print("FolderPickerTableViewCell: couldn't find usable data representations.")
                    self.label.text = "\u{fffd}"
                }
            }
        }
    }

}
