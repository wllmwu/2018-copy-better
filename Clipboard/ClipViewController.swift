//
//  ClipViewController.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class ClipViewController: UIViewController {
    
    private var clip: Clip?
    private var contents: NSAttributedString?
    private var managedObjectContext: NSManagedObjectContext!
    private var allClips: [Clip]?
    private var isLastCopied: Bool = false
    @IBOutlet weak var contentsTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if self.isLastCopied {
            let addButton: UIBarButtonItem = UIBarButtonItem(title: "Add to list", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ClipViewController.addLastCopied))
            self.navigationItem.title = "Last Copied"
            self.navigationItem.rightBarButtonItem = addButton
            self.contentsTextField.attributedText = self.contents
        }
        else {
            if let _ = self.clip {
                let copyButton: UIBarButtonItem = UIBarButtonItem(title: "Copy", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ClipViewController.copyClip))
                let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ClipViewController.segueToEdit))
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
                self.navigationItem.title = clip.title
                self.contentsTextField.attributedText = clip.contents
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
    
    func setLastCopied(contents: NSAttributedString, allClipsList: [Clip]) {
        self.allClips = allClipsList
        self.contents = contents
    }
    
    @objc func segueToEdit() {
        self.performSegue(withIdentifier: "ClipToEditClip", sender: self)
    }
    
    @objc func copyClip() {
        if let contents = self.contents {
            ClipboardManager.copyToPasteboard(attributedString: contents)
        }
        else {
            ClipboardManager.copyToPasteboard(attributedString: NSAttributedString())
        }
    }
    
    @objc func addLastCopied() {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            fatalError("Couldn't find entity description.")
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = nil
        if let contents = self.contentsTextField.attributedText {
            clip.contents = contents
        }
        else {
            clip.contents = NSAttributedString()
        }
        clip.index = 0
        self.allClips!.insert(clip, at: 0)
        
        // reassign indices
        for i in 1..<self.allClips!.count {
            self.allClips![i].index += 1
        }
        
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
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
