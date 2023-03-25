//
//  RecentlyDeletedTableViewController.swift
//  Copy Better
//
//  Created by William Wu on 9/16/22.
//  Copyright © 2022 William Wu. All rights reserved.
//

import UIKit
import CoreData
import ClipsKit

class RecentlyDeletedTableViewController: UITableViewController {

    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    private lazy var rootFolder: Folder = {
        return Folder.getRootFolder(context: self.managedObjectContext)!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        if self.managedObjectContext == nil {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                AppDelegate.alertFatalError(message: "Couldn't find AppDelegate.")
                return
            }
            self.managedObjectContext = appDelegate.persistentContainer.viewContext
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(RecentlyDeletedTableViewController.showCopiedToast), name: Notification.Name("ShowCopiedToast"), object: nil) // triggered by individual cells
        
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ShowCopiedToast"), object: nil)
    }
    
    // MARK: - Instance methods
    
    private func loadData() {
        self.clips = Clip.getRecentlyDeleted(context: self.managedObjectContext)
        self.deleteOverdueClips()
        self.tableView.reloadData()
    }
    
    /**
     Displays the custom toast view with (localized) message "Copied". Exposed to Objective-C so it can be called by the notification observer.
     */
    @objc func showCopiedToast() {
        self.showToast(message: AppStrings.TOAST_MESSAGE_COPIED)
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
    
    private func deleteOverdueClips() {
        let now = Date()
        var i = 0
        var deletedCount = 0
        while i < self.clips.count {
            let clip = self.clips[i]
            if let deleteDate = clip.deleteDate {
                if deleteDate < now {
                    self.clips.remove(at: i)
                    self.managedObjectContext.delete(clip)
                    deletedCount += 1
                    i -= 1
                }
            }
            i += 1
        }
        if deletedCount > 0 {
            self.saveContext()
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(self.clips.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.clips.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "HelpCell", for: indexPath)
        }
        else {
            let clip: Clip = self.clips[indexPath.row]
            let cell: ClipTableViewCell
            let title = clip.title
            if title != nil && title != "" {
                cell = tableView.dequeueReusableCell(withIdentifier: "ClipWithTitleCell", for: indexPath) as! ClipTableViewCell
                cell.setTitle(title!)
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! ClipTableViewCell
            }
            cell.setContents(clip.contents)
            cell.setClip(clip)
            return cell
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if self.clips.count == 0 {
            return false
        }
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.clips.remove(at: indexPath.row)
            if self.clips.count > 0 {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            else {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if self.clips.count == 0 {
            return nil
        }
        var actions: [UIContextualAction] = []
        let deleteAction = UIContextualAction(style: .destructive, title: AppStrings.DELETE_ACTION_TITLE) { (action, view, completionHandler) in
            self.managedObjectContext.delete(self.clips[indexPath.row])
            self.tableView(tableView, commit: .delete, forRowAt: indexPath)
            let success = self.saveContext()
            completionHandler(success)
        }
        actions.append(deleteAction)
        let restoreAction = UIContextualAction(style: .normal, title: AppStrings.RESTORE_ACTION_TITLE) { (action, view, completionHandler) in
            Clip.restoreClip(self.clips[indexPath.row], folder: self.rootFolder, context: self.managedObjectContext)
            self.tableView(tableView, commit: .delete, forRowAt: indexPath)
            let success = self.saveContext()
            completionHandler(success)
        }
        actions.append(restoreAction)
        return UISwipeActionsConfiguration(actions: actions)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
