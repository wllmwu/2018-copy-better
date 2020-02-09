//
//  SettingsTableViewController.swift
//  Clips
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
    @IBOutlet weak var tipsLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    private let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.showCurrentInMainSwitch.isOn = self.defaults.bool(forKey: "showLastCopiedInMain")
        self.showCurrentInWidgetSwitch.isOn = self.defaults.bool(forKey: "showLastCopiedInWidget")
        let numClips: Int = self.defaults.integer(forKey: "numClipsInWidget")
        self.numClipsInWidgetStepper.value = Double(numClips)
        self.numClipsInWidgetLabel.text = String(numClips)
        self.tipsLabel.sizeToFit()
        self.aboutLabel.sizeToFit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Instance methods
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didToggleShowCurrentInMainSwitch(_ sender: UISwitch) {
        self.defaults.set(self.showCurrentInMainSwitch.isOn, forKey: "showLastCopiedInMain")
    }
    
    @IBAction func toggleShowCurrentInWidgetSwitch(_ sender: UISwitch) {
        self.defaults.set(self.showCurrentInWidgetSwitch.isOn, forKey: "showLastCopiedInWidget")
    }
    
    @IBAction func changeNumClips(_ sender: UIStepper) {
        self.numClipsInWidgetLabel.text = String(Int(self.numClipsInWidgetStepper.value))
        self.defaults.set(Int(self.numClipsInWidgetStepper.value), forKey: "numClipsInWidget")
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return 2
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return (indexPath.row == 0) ? self.tipsLabel.bounds.height + 16 : self.aboutLabel.bounds.height + 16
        }
        return 45
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
