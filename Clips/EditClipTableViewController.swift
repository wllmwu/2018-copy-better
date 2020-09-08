//
//  EditClipTableViewController.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class EditClipTableViewController: UITableViewController {
    
    public enum Mode {
        case Add, Edit
    }
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    
    private var mode: Mode = .Add
    private var contents: [String : Any] = [:]
    private var originalContentsText: NSAttributedString!
    /**
     The clip being edited. Should be set when `mode` is `.Edit`; otherwise, may be left as `nil`.
     */
    private var clip: Clip!
    /**
     The folder where the new clip should be inserted. Should be set when `mode` is `.Add`; otherwise, may be left as `nil`.
     */
    private var containingFolder: Folder!
    /**
     The index in the containing folder where the new clip should be inserted. Should be set when `mode` is `.Add`; otherwise, may be left as `nil`.
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
        
        if self.mode == .Add {
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
    
    // MARK: - Instance methods
    
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
        let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
        // the unwind segue should result in a refresh for the clip/folder view
        defaults.set(true, forKey: "widgetNeedsUpdate")
        defaults.set(true, forKey: "keyboardNeedsUpdate")
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if self.mode == .Add {
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
            self.saveClipTitleAndContents(clip: clip)
            if self.saveContext() {
                self.showToast(message: AppStrings.TOAST_MESSAGE_SAVED)
            }
            
            self.performSegue(withIdentifier: "UnwindFromEdit", sender: self)
        }
    }
    
    private func saveClipTitleAndContents(clip: Clip) {
        clip.title = self.titleTextField.text
        if let title = self.titleTextField.text {
            if title.isEmpty {
                clip.title = nil // no empty strings
            }
        }
        
        if let text = self.contentsTextView.attributedText {
            if self.mode == .Add || !text.isEqual(to: self.originalContentsText) {
                clip.contents = ClipboardManager.itemFromAttributedString(text)
            }
            // else the text hasn't changed when Save is pressed, so just leave the clip as it is
        }
        else {
            clip.contents = [:]
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
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
