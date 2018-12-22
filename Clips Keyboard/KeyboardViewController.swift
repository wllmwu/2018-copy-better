//
//  KeyboardViewController.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 12/16/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class KeyboardViewController: UIInputViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    private var titles: [String?] = []
    private var strings: [String] = []
    private var lastCopied: String?
    private var pasteboardChangeCount: Int = 0
    private var defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    private var keyboardView: UIView!
    @IBOutlet var lastCopiedLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var previousColumnButton: UIButton!
    @IBOutlet var nextKeyboardButton: UIButton!
    @IBOutlet var spaceKey: UIButton!
    @IBOutlet var backspaceKey: UIButton!
    @IBOutlet var nextColumnButton: UIButton!
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInterface()
        
        // Perform custom UI setup here
        /*self.nextKeyboardButton = UIButton(type: .system)
        
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        self.view.addSubview(self.nextKeyboardButton)
        
        self.nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true*/
        
        let container = ClipsPersistentContainer(name: "Clips")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.managedObjectContext = container.viewContext
        
        if !self.defaults.bool(forKey: "launchedBefore") {
            // main app has never been launched - set some default settings and data
            self.defaults.set(true, forKey: "showLastCopiedInMain")
            self.defaults.set(true, forKey: "showLastCopiedInWidget")
            self.defaults.set(5, forKey: "numClipsInWidget")
            
            self.addDefaultData()
            self.defaults.set(true, forKey: "keyboardNeedsUpdate")
            
            self.defaults.set(true, forKey: "launchedBefore")
        }
        else {
            let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            do {
                self.clips = try self.managedObjectContext.fetch(fetchRequest)
                self.extractTitlesAndStrings()
                self.defaults.set(false, forKey: "keyboardNeedsUpdate")
            }
            catch let error as NSError {
                print("Couldn't fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
    
    // MARK: - Private instance methods
    
    private func loadInterface() {
        let nib = UINib(nibName: "ClipsKeyboardView", bundle: nil)
        self.keyboardView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        self.keyboardView.frame.size = self.view.frame.size
        self.view.addSubview(self.keyboardView)
        
        self.collectionView.register(UINib(nibName: "ClipsKeyboardCell", bundle: nil), forCellWithReuseIdentifier: "ClipsKeyboardCell")
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        self.setupKeyStyle(self.previousColumnButton)
        self.setupKeyStyle(self.nextKeyboardButton)
        self.setupKeyStyle(self.spaceKey)
        self.setupKeyStyle(self.backspaceKey)
        self.setupKeyStyle(self.nextColumnButton)
    }
    
    private func setupKeyStyle(_ button: UIButton) {
        button.layer.cornerRadius = 4
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.masksToBounds = false
    }
    
    private func addDefaultData() {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            fatalError("Couldn't find entity description.")
        }
        
        Clip.addDefaultClip1(entity: entity, context: self.managedObjectContext)
        Clip.addDefaultClip2(entity: entity, context: self.managedObjectContext)
        
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    private func extractTitlesAndStrings() {
        for i in 0..<self.clips.count {
            if let string = ClipboardManager.stringFromItem(self.clips[i].contents) {
                self.titles.append(self.clips[i].title)
                self.strings.append(string)
            }
        }
    }
    
    private func loadData() {
        DispatchQueue.global(qos: .utility).async {
            if self.pasteboardChangeCount != UIPasteboard.general.changeCount {
                self.pasteboardChangeCount = UIPasteboard.general.changeCount
                self.lastCopied = ClipboardManager.stringFromItem(ClipboardManager.retrieveFromPasteboard())
                self.lastCopiedLabel.text = self.lastCopied
            }
            
            if self.defaults.bool(forKey: "keyboardNeedsUpdate") {
                let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                do {
                    self.clips = try self.managedObjectContext.fetch(fetchRequest)
                    self.extractTitlesAndStrings()
                    self.defaults.set(false, forKey: "keyboardNeedsUpdate")
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
                catch let error as NSError {
                    print("Couldn't fetch. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
            self.orderUpdates()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    private func orderUpdates() {
        self.defaults.set(true, forKey: "mainNeedsUpdate")
        self.defaults.set(true, forKey: "widgetNeedsUpdate")
    }
    
    private func showButtonTapFeedback(forTopButton button: UIButton) {
        button.backgroundColor = UIColor.lightGray
        button.layer.cornerRadius = 4
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            button.backgroundColor = nil
        }
    }
    
    @IBAction func insertLastCopied(_ sender: UIButton) {
        self.showButtonTapFeedback(forTopButton: sender)
        if let string = self.lastCopied {
            self.textDocumentProxy.insertText(string)
        }
    }
    
    @IBAction func addLastCopied(_ sender: UIButton) {
        self.showButtonTapFeedback(forTopButton: sender)
        
        if let string = self.lastCopied {
            guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
                fatalError("Couldn't find entity description.")
            }
            
            // create new clip
            let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
            clip.title = nil
            clip.contents = ClipboardManager.itemForPlaintext(string)
            clip.index = 0
            self.clips.insert(clip, at: 0)
            
            // reassign indices
            for i in 1..<self.clips.count {
                self.clips[i].index += 1
            }
            
            self.saveContext()
            self.extractTitlesAndStrings()
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - Collection view data source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.clips.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ClipsKeyboardCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClipsKeyboardCell", for: indexPath) as! ClipsKeyboardCollectionViewCell
        cell.setup(title: self.titles[indexPath.row], contents: self.strings[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.size.width, height: 44)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.textDocumentProxy.insertText(self.strings[indexPath.row])
    }

}
