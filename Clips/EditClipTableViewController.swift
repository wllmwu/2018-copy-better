//
//  EditClipTableViewController.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData
import ClipsKit
import WidgetKit

class EditClipTableViewController: UITableViewController {
    
    public enum Mode {
        case add, edit
    }
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    
    private var mode: Mode = .add
    private var contents: [String : Any] = [:]
    private var originalContentsText: NSAttributedString!
    /**
     The clip being edited. Should be set when `mode` is `.edit`; otherwise, may be left as `nil`.
     */
    private var clip: Clip!
    /**
     The folder where the new clip should be inserted. Should be set when `mode` is `.add`; otherwise, may be left as `nil`.
     */
    private var containingFolder: Folder!
    /**
     The index in the containing folder where the new clip should be inserted. Should be set when `mode` is `.add`; otherwise, may be left as `nil`.
     */
    private var indexInFolder: Int?
    
    private var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.tableView.rowHeight = UITableView.automaticDimension
        
        if self.mode == .add {
            self.navigationItem.title = AppStrings.ADD_CLIP_TITLE
            self.titleTextField.becomeFirstResponder()
        }
        else {
            self.titleTextField.text = self.clip.title
            self.setContents(self.clip.contents)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Public setters
    
    func setContext(_ context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func setMode(_ mode: Mode) {
        self.mode = mode
    }
    
    func setClip(_ clip: Clip) {
        self.clip = clip
    }
    
    func setLocationToAdd(folder: Folder, index: Int) {
        self.containingFolder = folder
        self.indexInFolder = index
    }
    
    // MARK: - Instance methods
    
    /**
     Displays the contents of this view's assigned clip in the best available format (including image types), or displays a placeholder if the contents have no usable format.
     */
    private func setContents(_ contents: [String : Any]) {
        self.contents = contents
        
        if contents.count == 0 {
            self.originalContentsText = NSAttributedString()
            return
        }
        
        if let rtfd = ClipboardManager.attributedStringFromRtfd(inItem: contents) {
            self.contentsTextView.attributedText = rtfd
        }
        else if let rtf = ClipboardManager.attributedStringFromRtf(inItem: contents) {
            self.contentsTextView.attributedText = rtf
        }
        else if let html = ClipboardManager.attributedStringFromHtml(inItem: contents) {
            self.contentsTextView.attributedText = html
        }
        else if let plaintext = ClipboardManager.stringFromPlaintext(inItem: contents) {
            self.contentsTextView.text = plaintext
        }
        else if let image = ClipboardManager.imageFromImage(inItem: contents, maxWidth: self.contentsTextView.contentSize.width, maxHeight: 0) {
            self.contentsTextView.attributedText = ClipboardManager.attributedStringWithImage(image)
        }
        else {
            print("EditClipTableViewController: couldn't find usable data representations.")
        }
        self.originalContentsText = self.contentsTextView.attributedText
    }
    
    @discardableResult private func saveContext() -> Bool {
        do {
            try self.managedObjectContext.save()
            return true
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
        return false
    }
    
    private func saveClipTitleAndContents(clip: Clip) {
        clip.title = self.titleTextField.text
        if let title = self.titleTextField.text {
            if title.isEmpty {
                clip.title = nil // no empty strings
            }
        }
        
        if let text = self.contentsTextView.attributedText {
            if self.mode == .add || !text.isEqual(to: self.originalContentsText) {
                clip.contents = ClipboardManager.itemFromAttributedString(text)
            }
            // else the text hasn't changed when Save is pressed, so just leave the clip as it is
        }
        else {
            clip.contents = [:]
        }
    }
    
    // MARK: - Interface actions
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if self.mode == .add {
            guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
                AppDelegate.alertFatalError(message: "Couldn't find entity description.")
                return
            }
            
            let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
            self.saveClipTitleAndContents(clip: clip)
            clip.index = Int16(self.indexInFolder!)
            clip.folder = self.containingFolder
            
            if self.saveContext() {
                self.showToast(message: AppStrings.TOAST_MESSAGE_SAVED)
            }
            
            self.performSegue(withIdentifier: "UnwindFromAdd", sender: self)
        }
        else {
            self.saveClipTitleAndContents(clip: self.clip)
            if self.saveContext() {
                self.showToast(message: AppStrings.TOAST_MESSAGE_SAVED)
                if self.clip.isFavorite {
                    WidgetCenter.shared.reloadTimelines(ofKind: "com.williamwu.clips.favorites-widget")
                }
            }
            
            self.performSegue(withIdentifier: "UnwindFromEdit", sender: self)
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
