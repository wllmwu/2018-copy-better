//
//  ClipsKeyboardView.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 1/3/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit

protocol ClipsKeyboardViewDelegate: class {
    func insertText(_ text: String)
    func deleteBackwards()
    func addLastCopied(_ text: String)
}

class ClipsKeyboardView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private var titles: [String?] = []
    private var strings: [String] = []
    private var indices: [Int] = []
    private var lastCopied: String?
    private var pasteboardChangeCount: Int = 0
    
    @IBOutlet var lastCopiedLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionViewLayout: UICollectionViewFlowLayout!
    @IBOutlet var previousColumnButton: KeyboardButton!
    @IBOutlet var nextKeyboardButton: KeyboardButton!
    @IBOutlet var spaceKey: KeyboardButton!
    @IBOutlet var backspaceKey: KeyboardButton!
    @IBOutlet var nextColumnButton: KeyboardButton!
    
    @IBOutlet var spaceKeyToNextKeyboardButtonConstraint: NSLayoutConstraint!
    @IBOutlet var spaceKeyToPreviousColumnButtonConstraint: NSLayoutConstraint!
    
    weak var delegate: ClipsKeyboardViewDelegate?

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    /*override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.collectionView.register(UINib(nibName: "ClipsKeyboardCell", bundle: nil), forCellWithReuseIdentifier: "ClipsKeyboardCell")
        self.collectionViewLayout.itemSize = CGSize(width: self.frame.size.width, height: 44)
        self.setupKeyStyle(self.previousColumnButton)
        self.setupKeyStyle(self.nextKeyboardButton)
        self.setupKeyStyle(self.spaceKey)
        self.setupKeyStyle(self.backspaceKey)
        self.setupKeyStyle(self.nextColumnButton)
        self.setNextKeyboardButtonVisible(false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.collectionView.register(UINib(nibName: "ClipsKeyboardCell", bundle: nil), forCellWithReuseIdentifier: "ClipsKeyboardCell")
        self.collectionViewLayout.itemSize = CGSize(width: UIScreen.main.bounds.size.width, height: 44)
        //self.setNextKeyboardButtonVisible(false)
    }
    
    func setNextKeyboardButtonVisible(_ visible: Bool) {
        if visible {
            self.spaceKeyToNextKeyboardButtonConstraint.priority = .defaultHigh
            self.spaceKeyToPreviousColumnButtonConstraint.priority = .defaultLow
        }
        else {
            self.spaceKeyToNextKeyboardButtonConstraint.priority = .defaultLow
            self.spaceKeyToPreviousColumnButtonConstraint.priority = .defaultHigh
        }
    }
    
    func loadData(clips: [Clip]) {
        self.extractTitlesAndStrings(from: clips)
        self.collectionView.reloadData()
        DispatchQueue.global(qos: .utility).async {
            if self.pasteboardChangeCount != UIPasteboard.general.changeCount {
                self.pasteboardChangeCount = UIPasteboard.general.changeCount
                self.lastCopied = ClipboardManager.stringFromItem(ClipboardManager.retrieveFromPasteboard())
                DispatchQueue.main.async {
                    self.lastCopiedLabel.text = self.lastCopied
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func insertLastCopied(_ sender: UIButton) {
        if let string = self.lastCopied {
            self.delegate?.insertText(string)
        }
    }
    
    @IBAction func addLastCopied(_ sender: UIButton) {
        if let string = self.lastCopied {
            self.delegate?.addLastCopied(string)
        }
    }
    
    @IBAction func space(_ sender: UIButton) {
        self.delegate?.insertText(" ")
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        self.delegate?.deleteBackwards()
    }
    
    @IBAction func scrollToPreviousColumn(_ sender: UIButton) {
        let col: Int = self.currentColumn()
        if col > 0 {
            let indexPath: IndexPath = IndexPath(row: (col - 1) * 4, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    @IBAction func scrollToNextColumn(_ sender: UIButton) {
        let col: Int = self.currentColumn()
        if col < (self.strings.count - 1) / 4 {
            let indexPath: IndexPath = IndexPath(row: (col + 1) * 4, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    // MARK: - Private instance methods
    
    private func extractTitlesAndStrings(from clips: [Clip]) {
        self.titles = []
        self.strings = []
        for i in 0..<clips.count {
            if let string = ClipboardManager.stringFromItem(clips[i].contents) {
                self.titles.append(clips[i].title)
                self.strings.append(string)
                self.indices.append(Int(clips[i].index))
            }
        }
    }
    
    private func currentColumn() -> Int {
        let indexPaths: [IndexPath] = self.collectionView.indexPathsForVisibleItems
        if let indexPath = indexPaths.first {
            return indexPath.row / 4
        }
        return 0
    }
    
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.strings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ClipsKeyboardCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClipsKeyboardCell", for: indexPath) as! ClipsKeyboardCollectionViewCell
        cell.setup(title: self.titles[indexPath.row], contents: self.strings[indexPath.row], index: self.indices[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.insertText(self.strings[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell: ClipsKeyboardCollectionViewCell = collectionView.cellForItem(at: indexPath) as! ClipsKeyboardCollectionViewCell
        cell.backgroundColor = UIColor.lightGray
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell: ClipsKeyboardCollectionViewCell = collectionView.cellForItem(at: indexPath) as! ClipsKeyboardCollectionViewCell
        UIView.animate(withDuration: 0.2) {
            cell.backgroundColor = nil
        }
    }
    
}
