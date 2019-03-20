//
//  MainTableViewController.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class MainTableViewController: UITableViewController, UISearchResultsUpdating {
    
    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    
    private var showLastCopied: Bool = true
    private var lastCopied: [String : Any] = [:]
    private var pasteboardChangeCount: Int = 0
    
    private let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    private var selectedClip: Clip?
    
    private let searchController: UISearchController = UISearchController(searchResultsController: nil)
    private var filteredClips: [Clip] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            AppDelegate.alertFatalError(message: "Couldn't find AppDelegate.")
            return
        }
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
        self.retrieveData()
        
        //NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.updateLastCopied), name: Notification.Name(rawValue: "UpdateLastCopied"), object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.updateMain), name: Notification.Name(rawValue: "UpdateMain"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.loadData), name: Notification.Name("AppDidBecomeActive"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.showCopiedToast), name: Notification.Name("ShowCopiedToast"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.addLastCopied), name: Notification.Name("AddLastCopiedInMain"), object: nil)
        
        // set up search controller
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "search bar placeholder")
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Instance methods
    
    @objc private func loadData() {
        self.showLastCopied = self.defaults.bool(forKey: "showLastCopiedInMain")
        if self.showLastCopied && self.pasteboardChangeCount != UIPasteboard.general.changeCount {
            self.retrieveLastCopied()
            self.pasteboardChangeCount = UIPasteboard.general.changeCount
        }
        
        if self.defaults.bool(forKey: "mainNeedsUpdate") {
            self.retrieveData()
        }
        
        self.tableView.reloadData()
    }
    
    private func retrieveData() {
        let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        do {
            self.clips = try self.managedObjectContext.fetch(fetchRequest)
            self.defaults.set(false, forKey: "mainNeedsUpdate")
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
        }
    }
    
    private func retrieveLastCopied() {
        self.lastCopied = ClipboardManager.retrieveFromPasteboard()
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
    
    private func reassignIndices() {
        for i in 0..<self.clips.count {
            let clip = self.clips[i]
            clip.index = Int16(i)
        }
    }
    
    private func orderUpdates() {
        self.defaults.set(true, forKey: "widgetNeedsUpdate")
        self.defaults.set(true, forKey: "keyboardNeedsUpdate")
    }
    
    @objc func showCopiedToast() {
        self.showToast(message: NSLocalizedString("Copied", comment: "\"Copied\" toast message"))
    }
    
    @objc func addLastCopied() {
        if self.lastCopied.count > 0 {
            guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
                AppDelegate.alertFatalError(message: "Couldn't find entity description.")
                return
            }
            
            // create new clip
            let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
            clip.title = nil
            clip.contents = self.lastCopied
            clip.index = 0
            self.clips.insert(clip, at: 0)
            
            // reassign indices
            for i in 1..<self.clips.count {
                self.clips[i].index += 1
            }
            
            if self.saveContext() {
                self.tableView.reloadData()
                self.showToast(message: NSLocalizedString("Added", comment: "\"Added\" toast message"))
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltering() {
            return self.filteredClips.count
        }
        return self.clips.count + (self.showLastCopied ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && self.showLastCopied && !self.isFiltering() {
            let cell: ClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! ClipTableViewCell
            cell.setContents(self.lastCopied)
            return cell
        }
        
        let clip: Clip
        if self.isFiltering() {
            clip = self.filteredClips[indexPath.row]
        }
        else {
            clip = self.clips[indexPath.row - (self.showLastCopied ? 1 : 0)]
        }
        let cell: ClipTableViewCell
        if let title = clip.title {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipWithTitleCell", for: indexPath) as! ClipTableViewCell
            cell.setTitle(title)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! ClipTableViewCell
        }
        cell.setContents(clip.contents)
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if self.isFiltering() { return false }
        if indexPath.row == 0 && self.showLastCopied { return false }
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.row == 0 && self.showLastCopied { return sourceIndexPath }
        else if proposedDestinationIndexPath.row == 0 && self.showLastCopied {
            return IndexPath.init(row: 1, section: 0)
        }
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.showLastCopied && indexPath.row == 0 && !self.isFiltering() { return indexPath }
        
        if self.isFiltering() {
            self.selectedClip = self.filteredClips[indexPath.row]
        }
        else {
            self.selectedClip = self.clips[indexPath.row - (self.showLastCopied ? 1 : 0)]
        }
        return indexPath
    }
    
    // MARK: - Search results updating delegate
    
    func updateSearchResults(for searchController: UISearchController) {
        if self.isEditing {
            self.setEditing(false, animated: true)
        }
        self.filterContentForSearchText(searchController.searchBar.text!)
    }
    
    // MARK: - Search bar helper methods
    
    private func isFiltering() -> Bool {
        return self.searchController.isActive && !self.searchBarIsEmpty()
    }
    
    private func searchBarIsEmpty() -> Bool {
        return self.searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        self.filteredClips = self.clips.filter({( clip: Clip ) -> Bool in
            if let title = clip.title {
                if title.lowercased().contains(searchText.lowercased()) {
                    return true
                }
            }
            if let contents = ClipboardManager.stringFromItem(clip.contents) { // async?
                if contents.lowercased().contains(searchText.lowercased()) {
                    return true
                }
            }
            return false
        })
        
        self.tableView.reloadData()
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
                destination.setAllClips(self.clips)
            }
            else if identifier == "LastCopiedToClip" {
                let destination: ClipViewController = segue.destination as! ClipViewController
                destination.setContext(self.managedObjectContext)
                destination.setIsLastCopied(true)
                destination.setLastCopied(contents: self.lastCopied, allClipsList: self.clips)
            }
            else if identifier == "ClipWithTitleToClip" || identifier == "ClipNoTitleToClip" {
                let destination: ClipViewController = segue.destination as! ClipViewController
                if let clip = self.selectedClip {
                    destination.setContext(self.managedObjectContext)
                    destination.setIsLastCopied(false)
                    destination.setClip(clip)
                }
                else {
                    print("Error with segue: selected clip wasn't set.")
                }
            }
        }
    }

}
