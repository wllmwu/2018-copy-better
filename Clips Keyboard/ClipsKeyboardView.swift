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
        self.setupKeyStyle(self.previousColumnButton)
        self.setupKeyStyle(self.nextKeyboardButton)
        self.setupKeyStyle(self.spaceKey)
        self.setupKeyStyle(self.backspaceKey)
        self.setupKeyStyle(self.nextColumnButton)
        self.setNextKeyboardButtonVisible(false)
    }
    
    func setNextKeyboardButtonVisible(_ visible: Bool) {
        
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
        self.showButtonTapFeedback(forTopButton: sender)
        if let string = self.lastCopied {
            self.delegate?.insertText(string)
        }
    }
    
    @IBAction func addLastCopied(_ sender: UIButton) {
        self.showButtonTapFeedback(forTopButton: sender)
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
        if col < self.strings.count / 4 {
            let indexPath: IndexPath = IndexPath(row: (col + 1) * 4, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    // MARK: - Private instance methods
    
    private func setupKeyStyle(_ button: UIButton) {
        button.layer.cornerRadius = 5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.masksToBounds = false
    }
    
    private func showButtonTapFeedback(forTopButton button: UIButton) {
        button.backgroundColor = UIColor.lightGray
        button.layer.cornerRadius = 4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            button.backgroundColor = nil
        }
    }
    
    private func extractTitlesAndStrings(from clips: [Clip]) {
        for i in 0..<clips.count {
            if let string = ClipboardManager.stringFromItem(clips[i].contents) {
                self.titles.append(clips[i].title)
                self.strings.append(string)
            }
        }
    }
    
    private func currentColumn() -> Int {
        let indexPaths: [IndexPath] = self.collectionView.indexPathsForVisibleItems
        var maxIndex: Int = 0
        for indexPath in indexPaths {
            if maxIndex < indexPath.row {
                maxIndex = indexPath.row
            }
        }
        return maxIndex / 4
    }
    
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.strings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ClipsKeyboardCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClipsKeyboardCell", for: indexPath) as! ClipsKeyboardCollectionViewCell
        cell.setup(title: self.titles[indexPath.row], contents: self.strings[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.delegate?.insertText(self.strings[indexPath.row])
    }
    
}
