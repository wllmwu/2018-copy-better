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
        if let rtf = ClipboardManager.textFromRtf(inItem: self.contents) {
            //DispatchQueue.global(qos: .utility).async {
                self.setContentsLabelAttributedText(rtf)
            //}
            //self.setContentsLabelAttributedText(rtf)
        }
        else if let html = ClipboardManager.textFromHtml(inItem: self.contents) {
            //DispatchQueue.global(qos: .utility).async {
                self.setContentsLabelAttributedText(html)
            //}
            //self.setContentsLabelAttributedText(html)
        }
        else if let plaintext = ClipboardManager.textFromPlaintext(inItem: self.contents) {
            self.contentsLabel.text = plaintext
        }
        /*else if let image = ClipboardManager.textFromImage(inItem: self.contents, maxImageWidth: nil, maxImageHeight: self.contentsLabel.bounds.height) {
            self.contentsLabel.attributedText = image
        }*/
        /*else if ClipboardManager.imageExists(inItem: self.contents) {
            let height = self.contentsImageView.bounds.height
            DispatchQueue.global(qos: .utility).async {
                let image: UIImage = ClipboardManager.imageFromImage(inItem: self.contents)!
                let scaledImage: UIImage = ClipboardManager.scaleImage(image, maxImageWidth: nil, maxImageHeight: height)
                DispatchQueue.main.async {
                    self.contentsImageView.image = scaledImage
                }
            }
        }*/
        else if let image = ClipboardManager.imageFromImage(inItem: self.contents, maxImageWidth: nil, maxImageHeight: self.contentsImageView.bounds.height) {
            self.contentsLabel.text = ""
            self.contentsImageView.image = image
            //self.contentsImageView.setImage(image, maxImageWidth: nil, maxImageHeight: self.contentsImageView.bounds.height)
        }
        /*else if let image = ClipboardManager.imageFromImage(inItem: self.contents) {
            let height = self.contentsLabel.bounds.height
            DispatchQueue.global(qos: .utility).async {
                let imageInText = ClipboardManager.prepareTextFromImage(image, maxImageWidth: nil, maxImageHeight: height)
                DispatchQueue.main.async {
                    self.contentsLabel.attributedText = imageInText
                }
            }
        }*/
        else {
            print("ClipTableViewCell: couldn't find usable data representations.")
        }
    }
    
    private func setContentsLabelAttributedText(_ attributedString: NSAttributedString) {
        self.contentsLabel.text = ""
        self.contentsLabel.setAttributedTextAsync(attributedString)
        /*DispatchQueue.global(qos: .utility).async {
            let string: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            string.removeAttribute(.font, range: NSMakeRange(0, string.length))
            
            DispatchQueue.main.async {
                self.contentsLabel.attributedText = string
            }
        }*/
        //let string: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        //string.removeAttribute(.font, range: NSMakeRange(0, string.length))
        //self.contentsLabel.attributedText = attributedString
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
