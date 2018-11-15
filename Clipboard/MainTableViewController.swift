//
//  MainTableViewController.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class MainTableViewController: UITableViewController {
    
    private var clipTitles: [String] = []
    private var clipContents: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        // get titles and contents from ClipboardManager
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func toggleEditing(_ sender: UIBarButtonItem) {
        self.isEditing = !self.isEditing
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.clipContents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: ClipTableViewCell
        if indexPath.row == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! ClipTableViewCell
        }
        else if !self.clipTitles[indexPath.row].isEmpty {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipWithTitleCell", for: indexPath) as! ClipTableViewCell
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! ClipTableViewCell
        }
        
        cell.setup(title: self.clipTitles[indexPath.row], contents: self.clipContents[indexPath.row])
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if indexPath.row == 0 { return false }
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            self.clipTitles.remove(at: indexPath.row)
            self.clipContents.remove(at: indexPath.row)
            // call to ClipboardManager
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        // call to ClipboardManager
        let movedTitle = self.clipTitles[fromIndexPath.row], movedContents = self.clipContents[fromIndexPath.row]
        self.clipTitles.remove(at: fromIndexPath.row)
        self.clipTitles.insert(movedTitle, at: to.row)
        self.clipContents.remove(at: fromIndexPath.row)
        self.clipContents.insert(movedContents, at: to.row)
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        if indexPath.row == 0 { return false }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.row == 0 { return sourceIndexPath }
        else if proposedDestinationIndexPath.row == 0 {
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
