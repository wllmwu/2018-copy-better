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
    private var isRootFolder: Bool = true
    private var folders: [Folder] = []
    private var selectedFolder: Folder?
    private var clips: [Clip] = []
    private var selectedClip: Clip?
    private let searchController: UISearchController = UISearchController(searchResultsController: nil)
    private var filteredFolders: [Folder] = []
    private var filteredClips: [Clip] = []
    
    private var showLastCopied: Bool = true
    private var lastCopied: [String : Any] = [:]
    private var pasteboardChangeCount: Int = 0
    private let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: - Public setters
    
    func setFolder(_ folder: Folder) {
        self.navigationItem.title = folder.name!
        self.isRootFolder = false
        self.folders = folder.subfoldersArray
        self.clips = folder.clipsArray
        self.showLastCopied = false
    }
    
    // MARK: - Lifecycle functions
    
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
        self.searchController.searchBar.placeholder = AppStrings.SEARCH_BAR_PLACEHOLDER
        self.searchController.searchBar.tintColor = UIColor(named: "Accent")
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
        let foldersRequest: NSFetchRequest = NSFetchRequest<Folder>(entityName: "Folder")
        foldersRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        let clipsRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        clipsRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        
        do {
            self.folders = try self.managedObjectContext.fetch(foldersRequest)
            self.clips = try self.managedObjectContext.fetch(clipsRequest)
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
    
    /**
     Convenience method to update the indices of all folders in the list.
     */
    private func updateFolderIndices() {
        self.updateFolderIndices(from: 0, to: self.folders.count)
    }
    
    /**
     Reassigns the `index` attribute of folders in the list to reflect their current positions, including the starting index and excluding the ending index. You must save the managed context afterwards.
     */
    private func updateFolderIndices(from start: Int, to end: Int) {
        for i in start..<end {
            let folder = self.folders[i]
            folder.index = Int16(i)
        }
    }
    
    /**
     Convenience method to update the indices of all clips in the list.
     */
    private func updateClipIndices() {
        self.updateClipIndices(from: 0, to: self.clips.count)
    }
    
    /**
     Reassigns the `index` attribute of clips in the list to reflect their current positions, including the starting index and excluding the ending index. You must save the managed context afterwards.
    */
    private func updateClipIndices(from start: Int, to end: Int) {
        for i in start..<end {
            let clip = self.clips[i]
            clip.index = Int16(i)
        }
    }
    
    private func orderUpdates() {
        self.defaults.set(true, forKey: "widgetNeedsUpdate")
        self.defaults.set(true, forKey: "keyboardNeedsUpdate")
    }
    
    @objc func showCopiedToast() {
        self.showToast(message: AppStrings.TOAST_MESSAGE_COPIED)
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
            /*for i in 1..<self.clips.count {
                self.clips[i].index += 1
            }*/
            self.updateClipIndices(from: 1, to: self.clips.count)
            
            if self.saveContext() {
                self.tableView.reloadData()
                self.showToast(message: AppStrings.TOAST_MESSAGE_ADDED)
            }
        }
    }
    
    private func addClip() {
        self.performSegue(withIdentifier: "MainToAddClip", sender: self)
    }
    
    private func addFolder(retrying: Bool) {
        var message: String? = nil
        if retrying {
            message = AppStrings.EMPTY_FOLDER_NAME_MESSAGE
        }
        let alert: UIAlertController = UIAlertController(title: AppStrings.NEW_FOLDER_ACTION, message: message, preferredStyle: .alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: AppStrings.CANCEL_ACTION, style: .cancel, handler: nil)
        let saveAction: UIAlertAction = UIAlertAction(title: AppStrings.SAVE_ACTION, style: .default) { (action) in
            if let textField = alert.textFields?.first {
                if let text = textField.text, !text.isEmpty {
                    self.createNewFolder(name: text)
                }
                else {
                    self.addFolder(retrying: true)
                }
            }
        }
        alert.addTextField { (textfield) in
            textfield.placeholder = AppStrings.FOLDER_NAME_PLACEHOLDER
        }
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func createNewFolder(name: String) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Folder", in: self.managedObjectContext) else {
            AppDelegate.alertFatalError(message: "Couldn't find entity description.")
            return
        }
        
        let folder = Folder(entity: entity, insertInto: self.managedObjectContext)
        folder.name = name
        folder.index = Int16(self.folders.count)
        self.folders.append(folder)
        
        if self.saveContext() {
            self.tableView.reloadData()
            self.showToast(message: AppStrings.TOAST_MESSAGE_ADDED)
        }
    }
    
    @IBAction func addItem() {
        let addFolderAction: UIAlertAction = UIAlertAction(title: AppStrings.NEW_FOLDER_ACTION, style: .default) { (action) in
            self.addFolder(retrying: false)
        }
        let addClipAction: UIAlertAction = UIAlertAction(title: AppStrings.NEW_CLIP_ACTION, style: .default) { (action) in
            self.addClip()
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: AppStrings.CANCEL_ACTION, style: .cancel, handler: nil)
        
        let alert: UIAlertController = UIAlertController(title: AppStrings.ADD_ITEM_TITLE, message: nil, preferredStyle: .actionSheet)
        alert.addAction(addFolderAction)
        alert.addAction(addClipAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.barButtonItem = self.addButton // for iPads
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltering() {
            return self.filteredFolders.count + self.filteredClips.count
        }
        return self.folders.count + self.clips.count + (self.showLastCopied ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.isFiltering() {
            if indexPath.row < self.filteredFolders.count {
                let folder: Folder = self.filteredFolders[indexPath.row]
                let cell: FolderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderTableViewCell
                cell.setName(folder.name!)
                return cell
            }
            else {
                let clip: Clip = self.filteredClips[indexPath.row - self.filteredFolders.count]
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
        }
        else {
            let offset = self.showLastCopied ? 1 : 0
            if self.showLastCopied && indexPath.row == 0 {
                let cell: ClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! ClipTableViewCell
                cell.setContents(self.lastCopied)
                return cell
            }
            else if indexPath.row < self.folders.count + offset {
                let folder: Folder = self.folders[indexPath.row - offset]
                let cell: FolderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderTableViewCell
                cell.setName(folder.name!)
                return cell
            }
            else {
                let clip: Clip = self.clips[indexPath.row - self.folders.count - offset]
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
        }
        
        /*if self.showLastCopied && indexPath.row == 0 && !self.isFiltering() {
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
        cell.tempSetID(id: clip.id) // TEMP
        return cell*/
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if self.isFiltering() { return false }
        if indexPath.row == 0 && self.showLastCopied { return false }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let offset = self.showLastCopied ? 1 : 0
            if indexPath.row < self.folders.count + offset {
                let index = indexPath.row - offset
                self.managedObjectContext.delete(self.folders[index])
                self.folders.remove(at: index)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.updateFolderIndices(from: index, to: self.folders.count)
            }
            else {
                let index = indexPath.row - self.folders.count - offset
                self.managedObjectContext.delete(self.clips[index])
                self.clips.remove(at: index)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.updateClipIndices(from: index, to: self.clips.count)
            }
            self.saveContext()
        }
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        if indexPath.row == 0 && self.showLastCopied { return false }
        return true
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let offset = self.showLastCopied ? 1 : 0
        if fromIndexPath.row < self.folders.count + offset { // moving a folder
            let index = fromIndexPath.row - offset
            let folder: Folder = self.folders[index]
            self.folders.remove(at: index)
            self.folders.insert(folder, at: to.row - offset)
            
            if to.row < fromIndexPath.row {
                self.updateFolderIndices(from: to.row - offset, to: index + 1)
            }
            else {
                self.updateFolderIndices(from: index, to: to.row - offset + 1)
            }
        }
        else { // moving a clip
            let index = fromIndexPath.row - self.folders.count - offset
            let clip: Clip = self.clips[index]
            self.clips.remove(at: index)
            self.clips.insert(clip, at: to.row - self.folders.count - offset)
            
            if to.row < fromIndexPath.row {
                self.updateClipIndices(from: to.row - offset, to: index + 1)
            }
            else {
                self.updateClipIndices(from: index, to: to.row - offset + 1)
            }
        }
        self.saveContext()
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let offset = self.showLastCopied ? 1 : 0
        if self.showLastCopied && sourceIndexPath.row == 0 { // can't move the Last Copied cell
            return sourceIndexPath
        }
        else if sourceIndexPath.row < self.folders.count + offset { // trying to move a folder
            if self.showLastCopied && proposedDestinationIndexPath.row == 0 { // can't move Last Copied
                return IndexPath(row: 1, section: 0)
            }
            else if proposedDestinationIndexPath.row >= self.folders.count + offset { // can't move into the clips
                return IndexPath(row: self.folders.count + offset - 1, section: 0)
            }
        }
        else if proposedDestinationIndexPath.row < self.folders.count + offset { // can't move a clip into the folders
            return IndexPath(row: self.folders.count + offset, section: 0)
        }
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.isFiltering() {
            if indexPath.row < self.filteredFolders.count {
                self.selectedFolder = self.filteredFolders[indexPath.row]
            }
            else {
                self.selectedClip = self.filteredClips[indexPath.row]
            }
        }
        else {
            let offset = self.showLastCopied ? 1 : 0
            if self.showLastCopied && indexPath.row == 0 {
                return indexPath
            }
            else if indexPath.row < self.folders.count + offset {
                self.selectedFolder = self.folders[indexPath.row - offset]
            }
            else {
                self.selectedClip = self.clips[indexPath.row - offset]
            }
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
    
    private func filterContentForSearchText(_ searchText: String) { // TODO: search subfolders too
        self.filteredFolders = self.folders.filter({ (folder: Folder) -> Bool in
            if folder.name!.lowercased().contains(searchText.lowercased()) {
                return true
            }
            return false
        })
        
        self.filteredClips = self.clips.filter({ (clip: Clip) -> Bool in
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
            else if identifier == "MainToLastCopied" {
                let destination: ClipViewController = segue.destination as! ClipViewController
                destination.setContext(self.managedObjectContext)
                destination.setIsLastCopied(true)
                destination.setLastCopied(contents: self.lastCopied, allClipsList: self.clips)
            }
            else if identifier == "MainToMain" {
                if let folder = self.selectedFolder {
                    let destination: MainTableViewController = segue.destination as! MainTableViewController
                    destination.setFolder(folder)
                }
            }
            else if identifier == "MainToClipTitle" || identifier == "MainToClipNoTitle" {
                if let clip = self.selectedClip {
                    let destination: ClipViewController = segue.destination as! ClipViewController
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
    
    @IBAction func unwindAndReloadData(unwindSegue: UIStoryboardSegue) {
        self.loadData()
    }

}
