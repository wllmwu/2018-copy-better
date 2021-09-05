//
//  MainTableViewController.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData
import ClipsKit

class MainTableViewController: UITableViewController, UISearchResultsUpdating {
    
    private var managedObjectContext: NSManagedObjectContext!
    /// The folder whose contents this view controller is displaying.
    private var folder: Folder!
    private var isRootFolder: Bool = false
    private var subfolders: [Folder] = []
    /// The subfolder that was just selected (when applicable), used to configure the destination in a segue. Should be reset to `nil` when no longer needed.
    private var selectedFolder: Folder?
    private var clips: [Clip] = []
    /// The clip that was just selected (when applicable), used to configure the destination in a segue. Should be reset to `nil` when no longer needed.
    private var selectedClip: Clip?
    private var searchController: UISearchController!
    private var filteredFolders: [Folder] = []
    private var filteredClips: [Clip] = []
    
    private var showLastCopied: Bool = true
    private var favoritesEnabled: Bool = true
    private var shouldAddLastCopied: Bool = false
    private var lastCopied: [String : Any] = [:]
    private var pasteboardChangeCount: Int = 0
    private let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // MARK: - Public setters
    
    func setContext(_ moc: NSManagedObjectContext) {
        self.managedObjectContext = moc
    }
    
    func setFolder(_ folder: Folder) {
        self.folder = folder
        self.navigationItem.title = folder.name!
    }
    
    // MARK: - Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        
        if self.managedObjectContext == nil {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                AppDelegate.alertFatalError(message: "Couldn't find AppDelegate.")
                return
            }
            self.managedObjectContext = appDelegate.persistentContainer.viewContext
        }
        
        if self.folder == nil {
            if let rootFolder = Folder.getRootFolder(context: self.managedObjectContext) {
                self.folder = rootFolder
                self.isRootFolder = true
            }
            
            // set up search controller
            self.searchController = UISearchController(searchResultsController: nil)
            self.searchController.searchResultsUpdater = self
            self.searchController.obscuresBackgroundDuringPresentation = false
            self.searchController.searchBar.placeholder = AppStrings.SEARCH_BAR_PLACEHOLDER
            self.searchController.searchBar.tintColor = UIColor(named: "Accent")
            self.searchController.searchBar.searchBarStyle = .minimal
            self.tableView.tableHeaderView = self.searchController.searchBar
            self.definesPresentationContext = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.showCopiedToast), name: Notification.Name("ShowCopiedToast"), object: nil) // triggered by individual cells
        NotificationCenter.default.addObserver(self, selector: #selector(MainTableViewController.addLastCopied), name: Notification.Name("AddLastCopiedInMain"), object: nil) // triggered by the Last Copied cell
        
        self.loadData()
        
        if self.shouldAddLastCopied {
            self.addLastCopied()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ShowCopiedToast"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("AddLastCopiedInMain"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Instance methods
    
    public func refreshRootFolder() {
        if let rootFolder = Folder.getRootFolder(context: self.managedObjectContext) {
            self.folder = rootFolder
        }
        self.loadData()
    }
    
    /**
     Loads the current pasteboard (Last Copied), and calls `retrieveData()`; resets `selectedFolder` and `selectedClip` to `nil`; and reloads the table view.
     */
    public func loadData() {
        self.showLastCopied = self.defaults.bool(forKey: "showLastCopiedInMain")
        if self.showLastCopied && self.pasteboardChangeCount != UIPasteboard.general.changeCount {
            // the pasteboard changeCount gets reset to 0 when the device is restarted
            self.retrieveLastCopied()
            self.pasteboardChangeCount = UIPasteboard.general.changeCount
        }
        self.favoritesEnabled = self.defaults.bool(forKey: "enableFavorites")
        self.selectedFolder = nil
        self.selectedClip = nil
        
        self.retrieveData()
        self.tableView.reloadData()
    }
    
    /**
     Fetches folders and clips from the current folder to display, storing them in `self.subfolders` and `self.clips`.
     */
    private func retrieveData() {
        self.subfolders = self.folder.subfoldersArray
        self.clips = self.folder.clipsArray
    }
    
    private func retrieveLastCopied() {
        self.lastCopied = ClipboardManager.retrieveFromPasteboard()
    }
    
    /**
     Tries to save the managed object context, and returns whether the operation was successful.
     */
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
    
    /**
     Convenience version of `updateFolderIndices(from:to:)` that updates the indices of all folders in the list.
     */
    private func updateFolderIndices() {
        self.updateFolderIndices(from: 0, to: self.subfolders.count)
    }
    
    /**
     Reassigns the `index` attribute of folders in the list to reflect their current positions, including the starting index and excluding the ending index. You must save the managed context afterwards.
     */
    private func updateFolderIndices(from start: Int, to end: Int) {
        for i in start..<end {
            let folder = self.subfolders[i]
            folder.index = Int16(i)
        }
    }
    
    /**
     Convenience version of `updateClipIndices(from:to:)` that updates the indices of all clips in the list.
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
    
    /**
     Displays the custom toast view with (localized) message "Copied". Exposed to Objective-C so it can be called by the notification observer.
     */
    @objc func showCopiedToast() {
        self.showToast(message: AppStrings.TOAST_MESSAGE_COPIED)
    }
    
    /**
     Creates a new clip with the contents of the pasteboard and inserts it into the current folder as the new first clip. Also updates indices and orders the context to save.
     */
    @objc func addLastCopied() {
        if self.lastCopied.count > 0 {
            let alert: UIAlertController = UIAlertController(title: AppStrings.NEW_CLIP_FROM_PASTEBOARD_ACTION, message: nil, preferredStyle: .alert)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: AppStrings.CANCEL_ACTION, style: .cancel, handler: nil)
            let saveAction: UIAlertAction = UIAlertAction(title: AppStrings.SAVE_ACTION, style: .default) { (action) in
                var title = alert.textFields?.first?.text
                if title == "" {
                    title = nil
                }
                self.createNewClip(title: title, contents: self.lastCopied, index: 0)
            }
            alert.addTextField { (textfield) in
                textfield.placeholder = AppStrings.CLIP_NAME_PLACEHOLDER
                textfield.autocapitalizationType = .sentences
            }
            alert.addAction(cancelAction)
            alert.addAction(saveAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.shouldAddLastCopied = true
        }
    }
    
    private func createNewClip(title: String?, contents: [String : Any], index: Int16) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            AppDelegate.alertFatalError(message: "Couldn't find entity description.")
            return
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = title
        clip.contents = contents
        clip.index = index
        clip.folder = self.folder
        
        self.clips.insert(clip, at: Int(index))
        self.updateClipIndices(from: Int(index) + 1, to: self.clips.count)
        
        if self.saveContext() {
            self.tableView.reloadData()
            self.showToast(message: AppStrings.TOAST_MESSAGE_ADDED)
            self.shouldAddLastCopied = false
        }
    }
    
    /**
     Triggers the segue to the view for creating a new clip.
     */
    private func addClip() {
        self.performSegue(withIdentifier: "MainToAddClip", sender: self)
    }
    
    /**
     Displays the alert prompt for creating a new folder.
     */
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
            textfield.autocapitalizationType = .sentences
        }
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     Creates a new folder with the given name and inserts it into the current folder (appends to the list of existing folders). Also orders the context to save.
     */
    private func createNewFolder(name: String) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Folder", in: self.managedObjectContext) else {
            AppDelegate.alertFatalError(message: "Couldn't find entity description.")
            return
        }
        
        let folder = Folder(entity: entity, insertInto: self.managedObjectContext)
        folder.name = name
        folder.index = Int16(self.subfolders.count)
        folder.superfolder = self.folder
        self.subfolders.append(folder)
        
        if self.saveContext() {
            self.tableView.reloadData()
            self.showToast(message: AppStrings.TOAST_MESSAGE_ADDED)
        }
    }
    
    /**
     Displays the action sheet for selecting whether to create a new folder or a new clip.
     */
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
        if self.isFiltering() {
            return 1
        }
        else {
            return 2 // separate the Last Copied and/or Favorites cells from the folders and clips to make indexing easier
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltering() {
            return self.filteredFolders.count + self.filteredClips.count
        }
        else {
            if section == 0 { // Last Copied and/or Favorites cells
                return (self.showLastCopied ? 1 : 0) + (self.isRootFolder && self.favoritesEnabled ? 1 : 0)
            }
            else { // folders and clips
                return self.subfolders.count + self.clips.count
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.isFiltering() {
            if indexPath.row < self.filteredFolders.count { // folder
                let folder: Folder = self.filteredFolders[indexPath.row]
                let cell: FolderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderTableViewCell
                cell.setName(folder.name!)
                return cell
            }
            else { // clip
                let clip: Clip = self.filteredClips[indexPath.row - self.filteredFolders.count]
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
                cell.setFavorite(clip.isFavorite && self.favoritesEnabled)
                cell.setClip(clip)
                return cell
            }
        }
        else {
            if indexPath.section == 0 {
                if self.showLastCopied && indexPath.row == 0 { // Last Copied cell
                    let cell: ClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! ClipTableViewCell
                    cell.setContents(self.lastCopied)
                    return cell
                }
                else { // Favorites cell
                    return tableView.dequeueReusableCell(withIdentifier: "FavoritesCell", for: indexPath)
                }
            }
            else {
                if indexPath.row < self.subfolders.count { // folder
                    let folder: Folder = self.subfolders[indexPath.row]
                    let cell: FolderTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderTableViewCell
                    cell.setName(folder.name!)
                    return cell
                }
                else { // clip
                    let clip: Clip = self.clips[indexPath.row - self.subfolders.count]
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
                    cell.setFavorite(clip.isFavorite && self.favoritesEnabled)
                    cell.setClip(clip)
                    return cell
                }
            }
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if self.isFiltering() {
            return false
        }
        else if indexPath.section == 0 {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if indexPath.row < self.subfolders.count {
                let index = indexPath.row
                let folder: Folder = self.subfolders[index]
                
                let title: String = AppStrings.DELETE_FOLDER_CONFIRM_MESSAGE_1 + folder.name! + AppStrings.DELETE_FOLDER_CONFIRM_MESSAGE_2
                let confirmAlert: UIAlertController = UIAlertController(title: title, message: AppStrings.NO_UNDO_MESSAGE, preferredStyle: .alert) // confirm deletion
                let cancelAction: UIAlertAction = UIAlertAction(title: AppStrings.CANCEL_ACTION, style: .cancel, handler: nil)
                let okAction: UIAlertAction = UIAlertAction(title: AppStrings.OK_ACTION, style: .destructive) { (action) in
                    self.managedObjectContext.delete(self.subfolders[index])
                    self.subfolders.remove(at: index)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self.updateFolderIndices(from: index, to: self.subfolders.count)
                    self.saveContext()
                }
                confirmAlert.addAction(cancelAction)
                confirmAlert.addAction(okAction)
                self.present(confirmAlert, animated: true, completion: nil)
            }
            else {
                let index = indexPath.row - self.subfolders.count
                self.managedObjectContext.delete(self.clips[index])
                Clip.deleteCopyInteractions(for: self.clips[index])
                self.clips.remove(at: index)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.updateClipIndices(from: index, to: self.clips.count)
                self.saveContext()
            }
        }
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        if indexPath.section == 0 {
            return false
        }
        return true
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        if fromIndexPath.row < self.subfolders.count { // moving a folder
            let index = fromIndexPath.row
            let folder: Folder = self.subfolders[index]
            self.subfolders.remove(at: index)
            self.subfolders.insert(folder, at: to.row)
            
            if to.row < fromIndexPath.row {
                self.updateFolderIndices(from: to.row, to: index + 1)
            }
            else {
                self.updateFolderIndices(from: index, to: to.row + 1)
            }
        }
        else { // moving a clip
            let fromIndex = fromIndexPath.row - self.subfolders.count
            let toIndex = to.row - self.subfolders.count
            let clip: Clip = self.clips[fromIndex]
            self.clips.remove(at: fromIndex)
            self.clips.insert(clip, at: toIndex)
            
            if to.row < fromIndexPath.row {
                self.updateClipIndices(from: toIndex, to: fromIndex + 1)
            }
            else {
                self.updateClipIndices(from: fromIndex, to: toIndex + 1)
            }
        }
        self.saveContext()
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == 0 {
            return sourceIndexPath
        }
        else {
            if sourceIndexPath.row < self.subfolders.count { // trying to move a folder
                if proposedDestinationIndexPath.section == 0 {
                    return IndexPath(row: 0, section: 1)
                }
                else if proposedDestinationIndexPath.row >= self.subfolders.count { // can't move a folder into the clips
                    return IndexPath(row: self.subfolders.count - 1, section: 1)
                }
            }
            else if proposedDestinationIndexPath.section == 0 || proposedDestinationIndexPath.row < self.subfolders.count { // can't move a clip into the folders
                return IndexPath(row: self.subfolders.count, section: 1)
            }
        }
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if self.isFiltering() {
            return nil
        }
        else if indexPath.section == 0 {
            return nil
        }
        
        var actions: [UIContextualAction] = []
        if self.isEditing {
            let deleteAction: UIContextualAction = UIContextualAction(style: .destructive, title: AppStrings.DELETE_ACTION_TITLE) { (action, view, completionHandler) in
                self.tableView(self.tableView, commit: .delete, forRowAt: indexPath)
                completionHandler(true)
            }
            actions.append(deleteAction)
        }
        else {
            let moveAction: UIContextualAction = UIContextualAction(style: .normal, title: AppStrings.MOVE_ACTION_TITLE) { (action, view, completionHandler) in
                if indexPath.row < self.subfolders.count {
                    self.selectedFolder = self.subfolders[indexPath.row]
                }
                else {
                    self.selectedClip = self.clips[indexPath.row - self.subfolders.count]
                }
                self.performSegue(withIdentifier: "MainToMoveItem", sender: self)
                completionHandler(true)
            }
            moveAction.backgroundColor = UIColor(named: "Accent")
            actions.append(moveAction)
            
            if indexPath.row >= self.subfolders.count && self.favoritesEnabled {
                let clip: Clip = self.clips[indexPath.row - self.subfolders.count]
                let favoriteAction: UIContextualAction = UIContextualAction(style: .normal, title: nil) { (action, view, completionHandler) in
                    clip.isFavorite = !clip.isFavorite
                    self.saveContext()
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
        }
        
        return UISwipeActionsConfiguration(actions: actions)
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
        else if indexPath.section == 1 {
            if indexPath.row < self.subfolders.count {
                self.selectedFolder = self.subfolders[indexPath.row]
            }
            else {
                self.selectedClip = self.clips[indexPath.row - self.subfolders.count]
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
        if self.searchController == nil {
            return false
        }
        return self.searchController.isActive && !self.searchBarIsEmpty()
    }
    
    private func searchBarIsEmpty() -> Bool {
        if self.searchController == nil {
            return true
        }
        return self.searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            self.filteredFolders = []
            self.filteredClips = []
        }
        else {
            // search folders
            let folderRequest: NSFetchRequest = NSFetchRequest<Folder>(entityName: "Folder")
            folderRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchText)
            do {
                self.filteredFolders = try self.managedObjectContext.fetch(folderRequest)
            }
            catch let error as NSError {
                print("Couldn't fetch. \(error), \(error.userInfo)")
            }
            
            // search clip titles
            let clipRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            clipRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
            do {
                self.filteredClips = try self.managedObjectContext.fetch(clipRequest)
            }
            catch let error as NSError {
                print("Couldn't fetch. \(error), \(error.userInfo)")
            }
        }
        
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
                destination.setMode(.add)
                destination.setLocationToAdd(folder: self.folder, index: self.clips.count)
            }
            else if identifier == "MainToLastCopied" {
                let destination: ClipViewController = segue.destination as! ClipViewController
                destination.setContext(self.managedObjectContext)
                destination.setLastCopied(contents: self.lastCopied, folder: self.folder)
            }
            else if identifier == "MainToFavorites" {
                let destination: FavoritesTableViewController = segue.destination as! FavoritesTableViewController
                destination.setContext(self.managedObjectContext)
            }
            else if identifier == "MainToMain" {
                if let folder = self.selectedFolder {
                    let destination: MainTableViewController = segue.destination as! MainTableViewController
                    destination.setContext(self.managedObjectContext)
                    destination.setFolder(folder)
                }
            }
            else if identifier == "MainToClipTitle" || identifier == "MainToClipNoTitle" {
                if let clip = self.selectedClip {
                    let destination: ClipViewController = segue.destination as! ClipViewController
                    destination.setContext(self.managedObjectContext)
                    destination.setClip(clip)
                }
                else {
                    print("Error with segue: selected clip wasn't set.")
                }
            }
            else if identifier == "MainToMoveItem" {
                let destinationNav: UINavigationController = segue.destination as! UINavigationController
                let destination: FolderPickerTableViewController = destinationNav.viewControllers.first as! FolderPickerTableViewController
                destination.setFolder(self.folder)
                if let selected = self.selectedFolder {
                    destination.setFolderToMove(selected) // if moving a clip, don't need to bother
                }
            }
        }
    }
    
    /**
     Reloads data. This handles unwinding from views that don't completely cover the screen (returning from those does not trigger `viewWillAppear(_:)`).
     */
    @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
        self.loadData()
    }
    
    /**
     Dismisses this view.
     */
    @IBAction func swipeBack() {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Moves the selected folder to the new folder chosen in the folder picker. This is triggered by unwinding from the folder picker if the user didn't cancel the operation.
     */
    @IBAction func unwindFromFolderPicker(unwindSegue: UIStoryboardSegue) {
        let source: FolderPickerTableViewController = unwindSegue.source as! FolderPickerTableViewController
        let chosenFolder: Folder = source.getSelectedFolder()
        
        if chosenFolder.objectID != self.folder.objectID {
            if let selected = self.selectedFolder {
                selected.superfolder = chosenFolder
                let index = Int(selected.index)
                self.subfolders.remove(at: index)
                tableView.deleteRows(at: [IndexPath(row: index, section: 1)], with: .fade)
                self.updateFolderIndices(from: index, to: self.subfolders.count)
                selected.index = Int16(chosenFolder.subfolders!.count - 1)
                self.saveContext()
            }
            else if let selected = self.selectedClip {
                selected.folder = chosenFolder
                let index = Int(selected.index)
                self.clips.remove(at: index)
                tableView.deleteRows(at: [IndexPath(row: index + self.subfolders.count, section: 1)], with: .fade)
                self.updateClipIndices(from: index, to: self.clips.count)
                selected.index = Int16(chosenFolder.clips!.count - 1)
                self.saveContext()
            }
        }
        
        self.showToast(message: AppStrings.TOAST_MESSAGE_MOVED)
    }

}
