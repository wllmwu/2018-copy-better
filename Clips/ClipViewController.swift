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
    
    private var clip: Clip?
    private var contents: [String : Any] = [:]
    private var managedObjectContext: NSManagedObjectContext!
    private var allClips: [Clip]?
    private var isLastCopied: Bool = false
    @IBOutlet weak var contentsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if self.isLastCopied {
            let addButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Add to list", comment: "\"Add to list\" button title"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ClipViewController.addLastCopied))
            self.navigationItem.title = NSLocalizedString("Last copied", comment: "\"Last copied\" title")
            self.navigationItem.rightBarButtonItem = addButton
            self.setContentsText(contents: self.contents)
        }
        else {
            if let clip = self.clip {
                let copyButton: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Copy", comment: "\"Copy\" button title"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(ClipViewController.copyClip))
                let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ClipViewController.segueToEdit))
                if let title = clip.title {
                    self.navigationItem.title = title
                }
                self.navigationItem.rightBarButtonItems = [copyButton, editButton]
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.isLastCopied {
            if let clip = self.clip {
                self.setContentsText(contents: clip.contents)
            }
        }
    }
    
    // MARK: - Instance methods
    
    private func setContentsText(contents: [String : Any]) {
        if contents.count == 0 {
            self.contentsTextView.text = NSLocalizedString("(Empty)", comment: "empty clip contents placeholder")
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
    
    func setIsLastCopied(_ isLastCopied: Bool) {
        self.isLastCopied = isLastCopied
    }
    
    func setClip(_ clip: Clip) {
        self.clip = clip
        self.contents = clip.contents
    }
    
    func setLastCopied(contents: [String : Any], allClipsList: [Clip]) {
        self.allClips = allClipsList
        self.contents = contents
    }
    
    @objc func segueToEdit() {
        self.performSegue(withIdentifier: "ClipToEditClip", sender: self)
    }
    
    @objc func copyClip() {
        ClipboardManager.copyToPasteboard(item: self.contents)
        self.showToast(message: NSLocalizedString("Copied", comment: "\"Copied\" toast message"))
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
            self.allClips!.insert(clip, at: 0)
            
            // reassign indices
            for i in 1..<self.allClips!.count {
                self.allClips![i].index += 1
            }
            
            if self.saveContext() {
                self.showToast(message: NSLocalizedString("Added", comment: "\"Added\" toast message"))
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

}
