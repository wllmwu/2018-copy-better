//
//  ClipViewController.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class ClipViewController: UIViewController {
    
    /**
     The clip that this view is displaying. Should be set when `isLastCopied` is `false`; otherwise, may be left as `nil`.
     */
    private var clip: Clip!
    private var contents: [String : Any] = [:]
    private var managedObjectContext: NSManagedObjectContext!
    //private var allClips: [Clip]?
    private var isLastCopied: Bool = false
    /**
     The folder from where this view was entered. Should be set when `isLastCopied` is `true`; otherwise, may be left as `nil`. If the last copied clip is added to records, it should be inserted into this folder.
     */
    private var currentFolder: Folder!
    @IBOutlet weak var contentsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if self.isLastCopied {
            let addButton: UIBarButtonItem = UIBarButtonItem(title: AppStrings.ADD_TO_LIST_BUTTON_TITLE, style: UIBarButtonItem.Style.plain, target: self, action: #selector(ClipViewController.addLastCopied))
            self.navigationItem.title = AppStrings.LAST_COPIED_TITLE
            self.navigationItem.rightBarButtonItem = addButton
            self.setContentsText(contents: self.contents)
        }
        else {
            let copyButton: UIBarButtonItem = UIBarButtonItem(title: AppStrings.COPY_BUTTON_TITLE, style: UIBarButtonItem.Style.plain, target: self, action: #selector(ClipViewController.copyClip))
            let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ClipViewController.segueToEdit))
            self.navigationItem.rightBarButtonItems = [copyButton, editButton]
            
            if let title = self.clip.title {
                self.setTitle(title)
            }
            else {
                self.navigationItem.largeTitleDisplayMode = .never
            }
            self.setContentsText(contents: clip.contents)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Instance methods
    
    private func setTitle(_ title: String) {
        self.navigationItem.title = title
    }
    
    private func setContentsText(contents: [String : Any]) {
        if contents.count == 0 {
            self.contentsTextView.text = AppStrings.EMPTY_CLIP_PLACEHOLDER
            self.contentsTextView.textColor = UIColor.gray
            return
        }
        
        let textViewSize: CGSize = self.contentsTextView.contentSize
        DispatchQueue.global(qos: .utility).async {
            if let rtfd = ClipboardManager.attributedStringFromRtfd(inItem: contents) {
                DispatchQueue.main.async {
                    self.contentsTextView.attributedText = rtfd
                }
            }
            else if let rtf = ClipboardManager.attributedStringFromRtf(inItem: contents) {
                DispatchQueue.main.async {
                    self.contentsTextView.attributedText = rtf
                }
            }
            else if let html = ClipboardManager.attributedStringFromHtml(inItem: contents) {
                DispatchQueue.main.async {
                    self.contentsTextView.attributedText = html
                }
            }
            else if let plaintext = ClipboardManager.stringFromPlaintext(inItem: contents) {
                DispatchQueue.main.async {
                    self.contentsTextView.text = plaintext
                }
            }
            else if let image = ClipboardManager.imageFromImage(inItem: contents, maxWidth: textViewSize.width, maxHeight: 0) {
                DispatchQueue.main.async {
                    self.contentsTextView.attributedText = ClipboardManager.attributedStringWithImage(image)
                }
            }
            else {
                DispatchQueue.main.async {
                    print("ClipViewController: couldn't find usable data representations.")
                    self.contentsTextView.text = "\u{fffd}"
                }
            }
        }
    }
    
    func setContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func setClip(_ clip: Clip) {
        self.clip = clip
        self.contents = clip.contents
    }
    
    func setLastCopied(contents: [String : Any], folder: Folder) {
        self.contents = contents
        self.currentFolder = folder
        self.isLastCopied = true
    }
    
    @objc func segueToEdit() {
        self.performSegue(withIdentifier: "ClipToEditClip", sender: self)
    }
    
    @objc func copyClip() {
        ClipboardManager.copyToPasteboard(item: self.contents)
        self.showToast(message: AppStrings.TOAST_MESSAGE_COPIED)
    }
    
    @objc func addLastCopied() {
        if self.contents.count > 0 {
            guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
                AppDelegate.alertFatalError(message: "Couldn't find entity description.")
                return
            }
            
            // create new clip
            let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
            clip.title = nil
            clip.contents = self.contents
            clip.index = 0
            
            // reassign indices
            for c in self.currentFolder.clipsArray {
                c.index += 1
            }
            
            // insert the clip
            clip.folder = self.currentFolder
            
            if self.saveContext() {
                self.showToast(message: AppStrings.TOAST_MESSAGE_ADDED)
            }
        }
    }
    
    @discardableResult private func saveContext() -> Bool {
        do {
            try self.managedObjectContext.save()
            self.orderUpdates()
            return true
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
        return false
    }
    
    private func orderUpdates() {
        let defaults: UserDefaults = UserDefaults(suiteName: "group.com.williamwu.clips")!
        defaults.set(true, forKey: "mainNeedsUpdate")
        defaults.set(true, forKey: "widgetNeedsUpdate")
        defaults.set(true, forKey: "keyboardNeedsUpdate")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            if identifier == "ClipToEditClip" {
                let destinationNav: UINavigationController = segue.destination as! UINavigationController
                let destination: EditClipTableViewController = destinationNav.viewControllers.first as! EditClipTableViewController
                destination.setContext(self.managedObjectContext)
                destination.setMode(.Edit)
                destination.setClip(self.clip!)
            }
        }
    }
    
    @IBAction func unwindFromEdit(unwindSegue: UIStoryboardSegue) {
        if let clip = self.clip {
            if let title = clip.title {
                self.setTitle(title)
            }
            self.setContentsText(contents: clip.contents)
        }
    }
    
    @IBAction func swipeBack() {
        self.dismiss(animated: true, completion: nil)
    }

}
