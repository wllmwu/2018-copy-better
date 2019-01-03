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
                self.keyboardView.loadData(clips: self.clips)
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
    
    // MARK: - Clips keyboard view delegate
    
    func insertText(_ text: String) {
        self.textDocumentProxy.insertText(text)
    }
    
    func deleteBackwards() {
        self.textDocumentProxy.deleteBackward()
    }
    
    func addLastCopied(_ text: String) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            fatalError("Couldn't find entity description.")
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = nil
        clip.contents = ClipboardManager.itemForPlaintext(text)
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
