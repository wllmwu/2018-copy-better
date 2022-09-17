//
//  KeyboardViewController.swift
//  Clips Keyboard
//
//  Created by Bill Wu on 12/16/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData
import ClipsKit

class KeyboardViewController: UIInputViewController, ClipsKeyboardViewDelegate {
    
    private var managedObjectContext: NSManagedObjectContext!
    private var currentFolder: Folder!
    internal var superfolder: Folder?
    private var rootFolder: Folder!
    internal var isRootFolder: Bool = false
    internal var isFavorites: Bool = false
    internal var subfolders: [Folder] = []
    internal var clips: [Clip] = []
    internal var shouldWrapClips: Bool = false
    internal var favoritesEnabled: Bool = true
    
    private var keyboardView: ClipsKeyboardView!
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
        
        if !DefaultsManager.hasLaunched {
            // main app has never been launched - tell the user to check the app first
            self.keyboardView.showErrorMessage()
        }
        else if !DefaultsManager.hasLaunched2_0 {
            // has launched before updating to version 2.0 - migrate old clips to the new model
            container.migrateModelV1To2()
            DefaultsManager.hasLaunched2_0 = true
        }
        
        if let rootFolder = Folder.getRootFolder(context: self.managedObjectContext) {
            self.rootFolder = rootFolder
            self.currentFolder = self.rootFolder
            self.isRootFolder = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.shouldWrapClips = DefaultsManager.wrapClipsInKeyboard
        self.favoritesEnabled = DefaultsManager.favoritesEnabled
        self.loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.pasteboardCheckTimer = Timer.scheduledTimer(timeInterval: 3, target: self.keyboardView, selector: #selector(ClipsKeyboardView.updateLastCopied), userInfo: nil, repeats: true)
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
        self.keyboardView.setReturnKeyTitle(self.returnKeyTitle())
    }
    
    private func loadData() {
        if self.isFavorites {
            self.subfolders = []
            self.clips = self.fetchFavorites()
        }
        else {
            self.subfolders = self.currentFolder.subfoldersArray
            self.clips = self.currentFolder.clipsArray
        }
        self.keyboardView.loadData()
    }
    
    private func fetchFavorites() -> [Clip] {
        if let favorites = Clip.getFavorites(context: self.managedObjectContext, limit: nil) {
            return favorites
        }
        return []
    }
    
    private func returnKeyTitle() -> String {
        if self.textDocumentProxy.returnKeyType == .go {
            return AppStrings.KEYBOARD_RETURN_GO
        }
        return AppStrings.KEYBOARD_RETURN_RETURN
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
            DefaultsManager.shouldRefreshAppContext = true
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    @objc func deleteClip(_ notification: Notification) {
        guard let index: Int = notification.userInfo?["index"] as? Int else {
            return
        }
        
        let clip: Clip = self.clips.remove(at: index)
        let array: [Clip] = clip.folder!.clipsArray
        for i in index + 1 ..< array.count {
            array[i].index -= 1
        }
        Clip.deleteClip(clip, context: self.managedObjectContext)
        
        self.saveContext()
        self.keyboardView.loadData()
    }
    
    // MARK: - Clips keyboard view delegate
    
    func selectFolder(_ folder: Folder) {
        self.currentFolder = folder
        self.superfolder = folder.superfolder
        self.isRootFolder = folder.superfolder == nil
        self.isFavorites = false
        self.loadData()
    }
    
    func selectClip(_ clip: Clip) {
        if let text = ClipboardManager.stringFromItem(clip.contents) {
            self.insertText(text)
            Clip.donateCopyInteraction(with: clip) { (error) in
                if let e = error {
                    print("Interaction donation failed: \(e.localizedDescription)")
                }
            }
        }
    }
    
    func goToFavorites() {
        self.superfolder = self.rootFolder
        self.isRootFolder = false
        self.isFavorites = true
        self.loadData()
    }
    
    func insertText(_ text: String) {
        self.textDocumentProxy.insertText(text)
    }
    
    func deleteBackwards() {
        self.textDocumentProxy.deleteBackward()
    }
    
    func addLastCopied(_ contents: [String : Any]) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        if self.isFavorites {
            self.selectFolder(self.rootFolder)
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = nil
        clip.contents = contents
        clip.index = 0
        clip.folder = self.currentFolder
        self.clips.insert(clip, at: 0)
        
        // reassign indices
        for i in 1..<self.clips.count {
            self.clips[i].index += 1
        }
        
        self.saveContext()
        self.keyboardView.loadData()
    }
    
    func keyboardReturn() {
        self.insertText("\n")
    }

}
