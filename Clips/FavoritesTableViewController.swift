//
//  FavoritesTableViewController.swift
//  Copy Better
//
//  Created by William Wu on 9/26/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import UIKit
import CoreData
import ClipsKit
import WidgetKit

class FavoritesTableViewController: UITableViewController {
    
    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    private var selectedClip: Clip?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FavoritesTableViewController.showCopiedToast), name: Notification.Name("ShowCopiedToast"), object: nil) // triggered by individual cells
        
        self.loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ShowCopiedToast"), object: nil)
    }
    
    // MARK: - Public setters
    
    func setContext(_ moc: NSManagedObjectContext) {
        self.managedObjectContext = moc
    }
    
    // MARK: - Instance methods
    
    private func loadData() {
        if let favorites = Clip.getFavorites(context: self.managedObjectContext, limit: nil) {
            self.clips = favorites
        }
        self.selectedClip = nil
        self.tableView.reloadData()
    }
    
    /**
     Displays the custom toast view with (localized) message "Copied". Exposed to Objective-C so it can be called by the notification observer.
     */
    @objc func showCopiedToast() {
        self.showToast(message: AppStrings.TOAST_MESSAGE_COPIED)
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
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
            cell.setFavorite(clip.isFavorite)
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
            let clip: Clip = self.clips.remove(at: indexPath.row)
            if let folder: Folder = clip.folder {
                // reassign indices
                for c in folder.clipsArray.suffix(from: Int(clip.index) + 1) {
                    c.index -= 1
                }
            }
            Clip.deleteClip(clip, context: self.managedObjectContext)
            if self.clips.count > 0 {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            else {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            self.saveContext()
            WidgetCenter.shared.reloadTimelines(ofKind: "com.williamwu.clips.favorites-widget")
        }
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if self.clips.count == 0 {
            return nil
        }
        var actions: [UIContextualAction] = []
        let deleteAction: UIContextualAction = UIContextualAction(style: .destructive, title: AppStrings.DELETE_ACTION_TITLE) { (action, view, completionHandler) in
            self.tableView(self.tableView, commit: .delete, forRowAt: indexPath)
            completionHandler(true)
        }
        actions.append(deleteAction)
        if !self.isEditing {
            let clip: Clip = self.clips[indexPath.row]
            let favoriteAction: UIContextualAction = UIContextualAction(style: .normal, title: nil) { (action, view, completionHandler) in
                clip.isFavorite = !clip.isFavorite
                self.saveContext()
                WidgetCenter.shared.reloadTimelines(ofKind: "com.williamwu.clips.favorites-widget")
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                completionHandler(true)
            }
            if clip.isFavorite {
                favoriteAction.image = UIImage(systemName: "star.slash")
                favoriteAction.backgroundColor = UIColor.systemRed
            }
            else {
                favoriteAction.image = UIImage(systemName: "star")
                favoriteAction.backgroundColor = UIColor.systemGreen
            }
            actions.append(favoriteAction)
        }
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        self.selectedClip = self.clips[indexPath.row]
        return indexPath
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            if identifier == "FavToClipTitle" || identifier == "FavToClipNoTitle" {
                if let clip = self.selectedClip {
                    let destination: ClipViewController = segue.destination as! ClipViewController
                    destination.setContext(self.managedObjectContext)
                    destination.setClip(clip)
                }
                else {
                    print("Error with segue: selected clip wasn't set.")
                }
            }
        }
    }
    
    @IBAction func swipeBack() {
        self.dismiss(animated: true, completion: nil)
    }

}
