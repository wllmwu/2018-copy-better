//
//  FolderPickerTableViewController.swift
//  Copy Better
//
//  Created by Bill Wu on 9/4/20.
//  Copyright © 2020 William Wu. All rights reserved.
//

import UIKit
import ClipsKit

class FolderPickerTableViewController: UITableViewController {
    
    private var currentFolder: Folder!
    /**
     The folder that the user intends to move. If the user is moving a clip, then this should be `nil`.
     */
    private var folderToMove: Folder?
    private var isRootFolder: Bool!
    private var subfolders: [Folder] = []
    private var clips: [Clip] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Public setters and getters
    
    func setFolder(_ folder: Folder) {
        self.currentFolder = folder
        self.subfolders = folder.subfoldersArray
        self.clips = folder.clipsArray
        self.isRootFolder = (folder.superfolder == nil) // if no superfolder, then we're in the root
    }
    
    func setFolderToMove(_ folder: Folder) {
        self.folderToMove = folder
    }
    
    func getSelectedFolder() -> Folder {
        return self.currentFolder
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // if not in the root folder, then there is an extra cell for the superfolder
        return self.subfolders.count + self.clips.count + (self.isRootFolder ? 0 : 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let offset = self.isRootFolder ? 0 : 1
        let cell: FolderPickerTableViewCell
        if !self.isRootFolder && indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "SuperfolderCell", for: indexPath) as! FolderPickerTableViewCell
            cell.setFolderName(self.currentFolder.superfolder?.name)
        }
        else if indexPath.row < self.subfolders.count + offset {
            let folder: Folder = self.subfolders[indexPath.row - offset]
            cell = tableView.dequeueReusableCell(withIdentifier: "FolderCell", for: indexPath) as! FolderPickerTableViewCell
            cell.setFolderName(folder.name)
            if folder.objectID == self.folderToMove?.objectID {
                // remove selection indicators
                cell.setSelectable(false)
            }
            else {
                cell.setSelectable(true)
            }
        }
        else {
            let clip: Clip = self.clips[indexPath.row - self.subfolders.count - offset]
            if let title = clip.title {
                cell = tableView.dequeueReusableCell(withIdentifier: "ClipTitleCell", for: indexPath) as! FolderPickerTableViewCell
                cell.setClipTitle(title)
            }
            else {
                cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! FolderPickerTableViewCell
                cell.setClipContents(clip.contents)
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let offset = self.isRootFolder ? 0 : 1
        if !self.isRootFolder && indexPath.row == 0 {
            return indexPath
        }
        else if indexPath.row < self.subfolders.count + offset && self.subfolders[indexPath.row - offset].objectID == self.folderToMove?.objectID {
            // prevent user from moving a folder inside itself
            return nil
        }
        else if indexPath.row >= self.subfolders.count + offset {
            // prevent selection of a clip
            return nil
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let offset = self.isRootFolder ? 0 : 1
        if !self.isRootFolder && indexPath.row == 0 { // go to superfolder
            self.setFolder(self.currentFolder.superfolder!)
            self.tableView.reloadData()
        }
        else if indexPath.row < self.subfolders.count + offset {
            self.setFolder(self.subfolders[indexPath.row - offset])
            self.tableView.reloadData()
        }
    }

    // MARK: - Interface actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "UnwindFromFolderPicker", sender: self)
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
