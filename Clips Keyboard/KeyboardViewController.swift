//
//  KeyboardViewController.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 12/16/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class KeyboardViewController: UIInputViewController, ClipsKeyboardViewDelegate {
    
    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    private var keyboardView: ClipsKeyboardView!
    private var defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    private var pasteboardCheckTimer: Timer?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInterface()
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.deleteClip(_:)), name: Notification.Name("DeleteClip"), object: nil)
        
        let container = ClipsPersistentContainer(name: "Clips")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
                self.keyboardView.showErrorMessage()
            }
        })
        self.managedObjectContext = container.viewContext
        
        if !self.defaults.bool(forKey: "launchedBefore") {
            // main app has never been launched - set some default settings and data
            /*self.defaults.set(true, forKey: "showLastCopiedInMain")
            self.defaults.set(true, forKey: "showLastCopiedInWidget")
            self.defaults.set(5, forKey: "numClipsInWidget")
            
            self.addDefaultData()
            self.defaults.set(true, forKey: "keyboardNeedsUpdate")
            
            self.defaults.set(true, forKey: "launchedBefore")*/
            self.keyboardView.showErrorMessage()
        }
        else {
            let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            do {
                self.clips = try self.managedObjectContext.fetch(fetchRequest)
                self.keyboardView.loadData(clips: self.clips)
                self.defaults.set(false, forKey: "keyboardNeedsUpdate")
            }
            catch let error as NSError {
                print("Couldn't fetch. \(error), \(error.userInfo)")
                self.keyboardView.showErrorMessage()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.pasteboardCheckTimer = Timer.scheduledTimer(timeInterval: 1, target: self.keyboardView, selector: #selector(ClipsKeyboardView.updateLastCopied), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.pasteboardCheckTimer?.invalidate()
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
        self.keyboardView.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
    
    // MARK: - Private instance methods
    
    private func loadInterface() {
        let nib: UINib = UINib(nibName: "ClipsKeyboardView", bundle: nil)
        self.keyboardView = (nib.instantiate(withOwner: nil, options: nil).first as! ClipsKeyboardView)
        self.keyboardView.delegate = self
        
        guard let inputView: UIInputView = self.inputView else {
            return
        }
        inputView.addSubview(self.keyboardView)
        self.keyboardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.keyboardView.leftAnchor.constraint(equalTo: inputView.leftAnchor),
            self.keyboardView.topAnchor.constraint(equalTo: inputView.topAnchor),
            self.keyboardView.rightAnchor.constraint(equalTo: inputView.rightAnchor),
            self.keyboardView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor)
            ])
        self.keyboardView.setNextKeyboardButtonVisible(self.needsInputModeSwitchKey)
        self.keyboardView.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        self.keyboardView.setMessageLabelVisible(false)
    }
    
    /*private func addDefaultData() {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        Clip.addDefaultClip1(entity: entity, context: self.managedObjectContext)
        Clip.addDefaultClip2(entity: entity, context: self.managedObjectContext)
        
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }*/
    
    private func loadData() {
        DispatchQueue.global(qos: .utility).async {
            if self.defaults.bool(forKey: "keyboardNeedsUpdate") {
                let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                do {
                    self.clips = try self.managedObjectContext.fetch(fetchRequest)
                    DispatchQueue.main.async {
                        self.keyboardView.loadData(clips: self.clips)
                        self.defaults.set(false, forKey: "keyboardNeedsUpdate")
                    }
                }
                catch let error as NSError {
                    print("Couldn't fetch. \(error), \(error.userInfo)")
                    self.keyboardView.showErrorMessage()
                }
            }
            else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("KeyboardUpdateLastCopied"), object: nil)
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
    
    @objc func deleteClip(_ notification: Notification) {
        guard let index: Int = notification.userInfo?["index"] as? Int else {
            return
        }
        
        let clip: Clip = self.clips[index]
        self.managedObjectContext.delete(clip)
        self.clips.remove(at: index)
        
        for i in 0..<self.clips.count {
            self.clips[i].index = Int16(i)
        }
        
        self.saveContext()
        self.keyboardView.loadData(clips: self.clips)
    }
    
    // MARK: - Clips keyboard view delegate
    
    func insertText(_ text: String) {
        self.textDocumentProxy.insertText(text)
    }
    
    func deleteBackwards() {
        self.textDocumentProxy.deleteBackward()
    }
    
    func addLastCopied(_ text: String) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = nil
        clip.contents = ClipboardManager.itemFromPlaintext(text)
        clip.index = 0
        self.clips.insert(clip, at: 0)
        
        // reassign indices
        for i in 1..<self.clips.count {
            self.clips[i].index += 1
        }
        
        self.saveContext()
        self.keyboardView.loadData(clips: self.clips)
    }

}
