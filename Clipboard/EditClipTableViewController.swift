//
//  EditClipTableViewController.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class EditClipTableViewController: UITableViewController {
    
    public enum Mode {
        case Add, Edit
    }
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    
    private var mode: Mode = .Add
    private var contents: [String : Any] = [:]
    private var originalContentsText: NSAttributedString!
    private var index: Int?
    private var clip: Clip?
    
    private var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        if let clip = self.clip {
            self.titleTextField.text = clip.title
            self.setContents(clip.contents)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setContents(_ contents: [String : Any]) {
        self.contents = contents
        
        if contents.count == 0 {
            self.contentsTextView.text = "(Empty)"
            self.contentsTextView.textColor = UIColor.gray
            return
        }
        
        if let rtf = ClipboardManager.textFromRtf(inItem: contents) {
            self.contentsTextView.attributedText = rtf
        }
        else if let html = ClipboardManager.textFromHtml(inItem: contents) {
            self.contentsTextView.attributedText = html
        }
        else if let plaintext = ClipboardManager.textFromPlaintext(inItem: contents) {
            self.contentsTextView.text = plaintext
        }
        else if let image = ClipboardManager.textFromImage(inItem: contents, maxImageWidth: self.contentsTextView.bounds.width, maxImageHeight: nil) {
            self.contentsTextView.attributedText = image
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
    
    func setIndex(_ index: Int) {
        self.index = index
    }
    
    func setClip(_ clip: Clip) {
        self.clip = clip
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
            NotificationCenter.default.post(name: Notification.Name("UpdateMain"), object: nil)
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if self.mode == .Add {
            if let i = self.index {
                guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
                    fatalError("Couldn't find entity description.")
                }
                
                let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
                self.setClipTitleAndContents(clip: clip)
                clip.index = Int16(i)
                self.saveContext()
            }
            else {
                print("Error when adding: index wasn't set.")
            }
        }
        else {
            if let clip = self.clip {
                self.setClipTitleAndContents(clip: clip)
                self.saveContext()
            }
            else {
                print("Error when saving: clip wasn't set.")
            }
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setClipTitleAndContents(clip: Clip) {
        clip.title = self.titleTextField.text
        if let title = self.titleTextField.text {
            if title.isEmpty {
                clip.title = nil
            }
        }
        
        if let text = self.contentsTextView.attributedText {
            if self.mode == .Add || !text.isEqual(to: self.originalContentsText) {
                do {
                    let rtfData: Data = try text.data(from: NSMakeRange(0, text.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf])
                    let htmlData: Data = try text.data(from: NSMakeRange(0, text.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.html])
                    clip.contents = [kUTTypeRTF as String : rtfData, kUTTypeHTML as String : htmlData, kUTTypePlainText as String : text.string]
                }
                catch let error as NSError {
                    print("Error when saving: \(error), \(error.userInfo)")
                }
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
