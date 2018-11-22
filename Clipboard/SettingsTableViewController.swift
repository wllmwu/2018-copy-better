//
//  SettingsTableViewController.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var showCurrentInMainSwitch: UISwitch!
    @IBOutlet weak var showCurrentInWidgetSwitch: UISwitch!
    @IBOutlet weak var numClipsInWidgetStepper: UIStepper!
    @IBOutlet weak var numClipsInWidgetLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let defaults: UserDefaults = UserDefaults.standard
        self.showCurrentInMainSwitch.isOn = defaults.bool(forKey: "showLastCopiedInMain")
        self.showCurrentInWidgetSwitch.isOn = defaults.bool(forKey: "showLastCopiedInWidget")
        let numClips: Int = defaults.integer(forKey: "numClipsInWidget")
        self.numClipsInWidgetStepper.value = Double(numClips)
        self.numClipsInWidgetLabel.text = String(numClips)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        let defaults: UserDefaults = UserDefaults.standard
        defaults.set(self.showCurrentInMainSwitch.isOn, forKey: "showLastCopiedInMain")
        defaults.set(self.showCurrentInWidgetSwitch.isOn, forKey: "showLastCopiedInWidget")
        defaults.set(Int(self.numClipsInWidgetStepper.value), forKey: "numClipsInWidget")
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didToggleShowCurrentInMainSwitch(_ sender: UISwitch) {
        if sender.isOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateLastCopied"), object: nil)
        }
    }
    
    @IBAction func toggleShowCurrentInWidgetSwitch(_ sender: UISwitch) {
    }
    
    @IBAction func changeNumClips(_ sender: UIStepper) {
        self.numClipsInWidgetLabel.text = String(Int(self.numClipsInWidgetStepper.value))
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 2 }
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
