//
//  ClipsKeyboardView.swift
//  Clips Keyboard
//
//  Created by William Wu on 1/3/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit
import ClipsKit

protocol ClipsKeyboardViewDelegate: class {
    var superfolder: Folder? { get }
    var isRootFolder: Bool { get }
    var isFavorites: Bool { get }
    var subfolders: [Folder] { get }
    var clips: [Clip] { get }
    var shouldWrapClips: Bool { get }
    var favoritesEnabled: Bool { get }
    
    func selectFolder(_ folder: Folder)
    func selectClip(_ clip: Clip)
    func goToFavorites()
    
    func insertText(_ text: String)
    func deleteBackwards()
    func addLastCopied(_ contents: [String : Any])
    func keyboardReturn()
}

class ClipsKeyboardView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private var filteredClips: [Clip] = []
    private var indexOffset: Int = 0
    private var lastCopied: [String : Any]?
    private static let numItemsOnPage: Int = 5
    
    @IBOutlet weak var lastCopiedLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var nextKeyboardButton: KeyboardButton!
    @IBOutlet weak var spaceKey: KeyboardButton!
    @IBOutlet weak var backspaceKey: KeyboardButton!
    @IBOutlet weak var returnKey: KeyboardButton!
    @IBOutlet weak var messageLabel: UILabel!
    private var backspaceKeyTimer: Timer?
    private var backspaceKeyIsDown: Bool = false
    
    @IBOutlet weak var spaceKeyToNextKeyboardButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var spaceKeyToLeadingEdgeConstraint: NSLayoutConstraint!
    
    weak var delegate: ClipsKeyboardViewDelegate!

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.collectionView.register(UINib(nibName: "KeyboardFolderCell", bundle: nil), forCellWithReuseIdentifier: "KeyboardFolderCell")
        self.collectionView.register(UINib(nibName: "KeyboardClipCell", bundle: nil), forCellWithReuseIdentifier: "KeyboardClipCell")
        self.collectionView.collectionViewLayout = self.createLayout()
    }
    
    // MARK: - Public setters and methods
    
    func setNextKeyboardButtonVisible(_ visible: Bool) {
        self.nextKeyboardButton.isHidden = !visible
        if visible {
            self.spaceKeyToNextKeyboardButtonConstraint.priority = .defaultHigh
            self.spaceKeyToLeadingEdgeConstraint.priority = .defaultLow
        }
        else {
            self.spaceKeyToNextKeyboardButtonConstraint.priority = .defaultLow
            self.spaceKeyToLeadingEdgeConstraint.priority = .defaultHigh
        }
    }
    
    func setReturnKeyTitle(_ title: String) {
        self.returnKey.setTitle(title, for: .normal)
    }
    
    func loadData() {
        // filter clips to include only those with (plain)text
        self.filteredClips = []
        for clip in self.delegate.clips {
            if ClipboardManager.containsText(item: clip.contents) {
                self.filteredClips.append(clip)
            }
        }
        self.indexOffset = (!self.delegate.isRootFolder || self.delegate.favoritesEnabled) ? 1 : 0
        
        self.collectionView.reloadData()
        if self.filteredClips.count == 0 {
            self.showEmptyMessage()
        }
        else {
            self.setMessageLabelVisible(false)
        }
        
        self.updateLastCopied()
    }
    
    @objc func updateLastCopied() {
        if self.lastCopied == nil || ClipboardManager.pasteboardHasChangedSinceLastRetrieval {
            let item = ClipboardManager.retrieveFromPasteboard()
            self.lastCopied = item
            self.lastCopiedLabel.text = ClipboardManager.stringFromItem(item)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func setMessageLabelVisible(_ visible: Bool) {
        self.messageLabel.isHidden = !visible
    }
    
    func setMessageLabelText(_ text: String) {
        self.messageLabel.text = text
    }
    
    func showErrorMessage() {
        self.setMessageLabelText(AppStrings.KEYBOARD_ERROR_MESSAGE)
        self.setMessageLabelVisible(true)
    }
    
    func showEmptyMessage() {
        self.setMessageLabelText(AppStrings.KEYBOARD_EMPTY_MESSAGE)
        self.setMessageLabelVisible(true)
    }
    
    // MARK: - Actions
    
    @IBAction func insertLastCopied(_ sender: UIButton) {
        guard let item = self.lastCopied, let string = ClipboardManager.stringFromItem(item) else {
            return
        }
        self.delegate.insertText(string)
    }
    
    @IBAction func addLastCopied(_ sender: UIButton) {
        if let item = self.lastCopied {
            self.delegate.addLastCopied(item)
        }
    }
    
    @IBAction func space(_ sender: UIButton) {
        self.delegate.insertText(" ")
    }
    
    @IBAction func backspaceDown(_ sender: UIButton) {
        self.backspace()
        self.backspaceKeyIsDown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if (self.backspaceKeyIsDown) {
                self.backspaceKeyTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ClipsKeyboardView.backspace), userInfo: nil, repeats: true)
            }
        }
    }
    
    @IBAction func backspaceUp(_ sender: UIButton) {
        self.backspaceKeyTimer?.invalidate()
        self.backspaceKeyIsDown = false
    }
    
    @objc func backspace() {
        self.delegate.deleteBackwards()
    }
    
    @IBAction func returnPressed() {
        self.delegate.keyboardReturn()
    }
    
    // MARK: - Private instance methods
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            if sectionIndex == 0 {
                // folder section
                let folderItemSize = NSCollectionLayoutSize(widthDimension: .absolute(88), heightDimension: .absolute(66))
                let folderItem = NSCollectionLayoutItem(layoutSize: folderItemSize)
                let folderGroupSize = NSCollectionLayoutSize(widthDimension: .estimated(132), heightDimension: .absolute(66))
                let folderGroup = NSCollectionLayoutGroup.horizontal(layoutSize: folderGroupSize, subitems: [folderItem])
                let folderSection = NSCollectionLayoutSection(group: folderGroup)
                folderSection.orthogonalScrollingBehavior = .continuous
                return folderSection
            }
            else {
                // clip section
                let clipItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                let clipItem = NSCollectionLayoutItem(layoutSize: clipItemSize)
                let clipGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(132))
                let clipGroup = NSCollectionLayoutGroup.vertical(layoutSize: clipGroupSize, subitems: [clipItem])
                let clipSection = NSCollectionLayoutSection(group: clipGroup)
                return clipSection
            }
        }
        return layout
    }
    
    // MARK: - Collection view data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            // folder section
            return self.delegate.subfolders.count + self.indexOffset
        }
        else {
            // clip section
            return self.filteredClips.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            // folder section
            if indexPath.row < self.indexOffset {
                let cell: KeyboardFolderCell = collectionView.dequeueReusableCell(withReuseIdentifier: "KeyboardFolderCell", for: indexPath) as! KeyboardFolderCell
                
                if self.delegate.isRootFolder {
                    // Favorites cell
                    cell.setFormat(.favorites)
                    cell.setName(AppStrings.FAVORITES_TITLE)
                }
                else {
                    // superfolder cell
                    cell.setFormat(.superfolder)
                    cell.setName(self.delegate.superfolder!.name)
                }
                
                return cell
            }
            else {
                // regular folder cell
                let folder: Folder = self.delegate.subfolders[indexPath.row - self.indexOffset]
                let cell: KeyboardFolderCell = collectionView.dequeueReusableCell(withReuseIdentifier: "KeyboardFolderCell", for: indexPath) as! KeyboardFolderCell
                cell.setFormat(.folder)
                cell.setName(folder.name)
                return cell
            }
        }
        else {
            // clip cell
            let clip: Clip = self.filteredClips[indexPath.row]
            let cell: KeyboardClipCell = collectionView.dequeueReusableCell(withReuseIdentifier: "KeyboardClipCell", for: indexPath) as! KeyboardClipCell
            cell.setClip(clip)
            if self.delegate.isFavorites {
                cell.hideXButton()
            }
            if self.delegate.shouldWrapClips {
                cell.wrapClipText()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            // folder section
            if indexPath.row < self.indexOffset {
                if self.delegate.isRootFolder {
                    // Favorites cell
                    self.delegate.goToFavorites()
                }
                else {
                    // superfolder cell
                    self.delegate.selectFolder(self.delegate.superfolder!)
                }
            }
            else {
                // regular folder cell
                self.delegate.selectFolder(self.delegate.subfolders[indexPath.row - self.indexOffset])
            }
        }
        else {
            // clip cell
            self.delegate.selectClip(self.filteredClips[indexPath.row])
        }
    }
    
}
