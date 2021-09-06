//
//  ClipsKeyboardCollectionViewCell.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 12/19/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import ClipsKit

class KeyboardClipCell: UICollectionViewCell {
    
    private var index: Int!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentsLabel: UILabel!
    @IBOutlet weak var xButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var contentsLabelLeadingToTitleLabel: NSLayoutConstraint!
    @IBOutlet weak var contentsLabelLeadingToEdge: NSLayoutConstraint!
    @IBOutlet weak var contentsLabelTrailingToXButton: NSLayoutConstraint!
    @IBOutlet weak var contentsLabelTrailingToDeleteButton: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetLabels()
        self.resetButtons()
    }
    
    // MARK: - Public setters and methods
    
    func setClip(_ clip: Clip) {
        if let title = clip.title {
            self.titleLabel.text = title
        }
        else {
            self.titleLabel.text = nil
            self.contentsLabelLeadingToTitleLabel.priority = .defaultLow
            self.contentsLabelLeadingToEdge.priority = .defaultHigh
        }
        self.contentsLabel.text = ClipboardManager.stringFromItem(clip.contents)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.index = Int(clip.index)
    }
    
    func hideXButton() {
        self.xButton.isHidden = true
    }
    
    func wrapClipText() {
        self.contentsLabel.numberOfLines = 3
        self.contentsLabel.adjustsFontSizeToFitWidth = true
        self.contentsLabel.minimumScaleFactor = 0.6
    }
    
    // MARK: - Private methods
    
    private func resetLabels() {
        self.contentsLabelLeadingToTitleLabel.priority = .defaultHigh
        self.contentsLabelLeadingToEdge.priority = .defaultLow
        self.contentsLabel.numberOfLines = 1
        self.contentsLabel.adjustsFontSizeToFitWidth = false
    }
    
    private func resetButtons() {
        self.deleteButton.isHidden = true
        self.cancelButton.isHidden = true
        self.contentsLabelTrailingToXButton.priority = .defaultHigh
        self.contentsLabelTrailingToDeleteButton.priority = .defaultLow
        self.xButton.isHidden = false
    }
    
    // MARK: - Actions
    
    @IBAction func xTapped(_ sender: UIButton) {
        self.xButton.isHidden = true
        self.contentsLabelTrailingToXButton.priority = .defaultLow
        self.contentsLabelTrailingToDeleteButton.priority = .defaultHigh
        self.deleteButton.isHidden = false
        self.cancelButton.isHidden = false
    }
    
    @IBAction func deleteTapped(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name("DeleteClip"), object: nil, userInfo: ["index" : self.index])
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        self.resetButtons()
    }
    
}
