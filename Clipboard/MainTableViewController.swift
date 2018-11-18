//
//  MainTableViewController.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class MainTableViewController: UITableViewController {
    
    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    
    private var showLastCopied: Bool = true
    private var lastCopied: NSAttributedString?
    
    private var emptyContents = NSAttributedString(string: "Empty", attributes: <#T##[NSAttributedStringKey : Any]?#>)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Couldn't find AppDelegate")
        }
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
        
        // user preference: show last copied
        if let _ = UserDefaults.standard.object(forKey: "showLastCopied") {
            // key exists
            self.showLastCopied = UserDefaults.standard.bool(forKey: "showLastCopied")
        }
        else {
            // key doesn't exist
            UserDefaults.standard.set(true, forKey: "showLastCopied")
        }
        
        if self.showLastCopied {
            self.retrieveLastCopied()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadData() {
        let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        do {
            self.clips = try managedObjectContext.fetch(fetchRequest)
        }
        catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func retrieveLastCopied() {
        self.lastCopied = ClipboardManager.retrieveFromPasteboard()
        if self.lastCopied == nil {
            self.lastCopied = self.emptyContents
        }
    }
    
    @IBAction func toggleEditing(_ sender: UIBarButtonItem) {
        self.isEditing = !self.isEditing
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clips.count + (self.showLastCopied ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && self.showLastCopied {
            let cell: ClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! ClipTableViewCell
            cell.setup(contents: self.lastCopied!)
            return cell
        }
        
        let row: Int = indexPath.row - (self.showLastCopied ? 1 : 0)
        let clip: Clip = self.clips[row]
        var cell: ClipTableViewCell
        if let title = clip.title {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipWithTitleCell", for: indexPath) as! ClipTableViewCell
            cell.setup(title: title, contents: clip.contents)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! ClipTableViewCell
            cell.setup(contents: clip.contents)
        }
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.row == 0 && self.showLastCopied { return false }
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.clips.remove(at: indexPath.row)
            // call to ClipboardManager
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        // call to ClipboardManager
        let moved: Clip = self.clips[fromIndexPath.row]
        self.clips.remove(at: fromIndexPath.row)
        self.clips.insert(moved, at: to.row)
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        if indexPath.row == 0 && self.showLastCopied { return false }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.row == 0 && self.showLastCopied { return sourceIndexPath }
        else if proposedDestinationIndexPath.row == 0 && self.showLastCopied {
            return IndexPath.init(row: 1, section: 0)
        }
        return proposedDestinationIndexPath
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
