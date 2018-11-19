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
    private var lastCopied: NSAttributedString = NSAttributedString()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Couldn't find AppDelegate")
        }
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
        
        self.showLastCopied = UserDefaults.standard.bool(forKey: "showLastCopiedInMain")
        if self.showLastCopied {
            self.retrieveLastCopied()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.showLastCopied = UserDefaults.standard.bool(forKey: "showLastCopiedInMain")
        self.loadData()
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func loadData() {
        let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        do {
            self.clips = try self.managedObjectContext.fetch(fetchRequest)
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func retrieveLastCopied() {
        self.lastCopied = ClipboardManager.retrieveFromPasteboard()
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    private func reassignIndices() {
        for i in 0..<self.clips.count {
            let clip = self.clips[i]
            clip.index = Int16(i)
        }
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
            cell.setContents(self.lastCopied)
            return cell
        }
        
        let index: Int = indexPath.row - (self.showLastCopied ? 1 : 0)
        let clip: Clip = self.clips[index]
        var cell: ClipTableViewCell
        if let _ = clip.title {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipWithTitleCell", for: indexPath) as! ClipTableViewCell
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! ClipTableViewCell
        }
        cell.setClip(clip)
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if !self.isEditing { return false }
        if indexPath.row == 0 && self.showLastCopied { return false }
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let correction: Int = self.showLastCopied ? 1 : 0
            // Delete the row from the data source
            self.managedObjectContext.delete(self.clips[indexPath.row - correction])
            self.clips.remove(at: indexPath.row - correction)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            self.reassignIndices()
            self.saveContext()
        }
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let correction: Int = self.showLastCopied ? 1 : 0
        let moved: Clip = self.clips[fromIndexPath.row - correction]
        moved.index = Int16(to.row - correction)
//        moved.setValue((to.row - correction), forKey: "index")
        self.clips.remove(at: fromIndexPath.row - correction)
        self.clips.insert(moved, at: to.row - correction)
        
        self.reassignIndices()
        self.saveContext()
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
        if let identifier = segue.identifier {
            if identifier == "MainToAddClip" {
                let destinationNav: UINavigationController = segue.destination as! UINavigationController
                let destination: EditClipTableViewController = destinationNav.viewControllers.first as! EditClipTableViewController
                destination.setContext(self.managedObjectContext)
                destination.setMode(.Add)
                destination.setIndex(self.clips.count) // append new clip to end of list
            }
        }
    }

}
