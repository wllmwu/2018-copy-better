//
//  SettingsTableViewController.swift
//  Clips
//
//  Created by William Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import ClipsKit

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var enableFavoritesSwitch: UISwitch!
    @IBOutlet weak var showCurrentInMainSwitch: UISwitch!
    @IBOutlet weak var askforTitleSwitch: UISwitch!
    @IBOutlet weak var autoAddLastCopiedSwitch: UISwitch!
    @IBOutlet weak var storeFormattingInfoSwitch: UISwitch!
    @IBOutlet weak var wrapClipsInKeyboardSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.enableFavoritesSwitch.isOn = DefaultsManager.favoritesEnabled
        self.showCurrentInMainSwitch.isOn = DefaultsManager.showLastCopiedInApp
        self.askforTitleSwitch.isOn = DefaultsManager.askForTitleForLastCopiedInApp
        self.autoAddLastCopiedSwitch.isOn = DefaultsManager.autoAddLastCopiedInApp
        self.storeFormattingInfoSwitch.isOn = DefaultsManager.storeClipFormattingInApp
        self.wrapClipsInKeyboardSwitch.isOn = DefaultsManager.wrapClipsInKeyboard
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Interface actions
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "UnwindFromSettings", sender: self)
    }
    
    @IBAction func didToggleEnableFavoritesSwitch(_ sender: UISwitch) {
        DefaultsManager.favoritesEnabled = self.enableFavoritesSwitch.isOn
    }
    
    @IBAction func didToggleShowCurrentInMainSwitch(_ sender: UISwitch) {
        DefaultsManager.showLastCopiedInApp = self.showCurrentInMainSwitch.isOn
    }
    
    @IBAction func didToggleAskForTitleSwitch(_ sender: UISwitch) {
        DefaultsManager.askForTitleForLastCopiedInApp = self.askforTitleSwitch.isOn
    }
    
    @IBAction func didToggleAutoAddLastCopiedSwitch(_ sender: UISwitch) {
        DefaultsManager.autoAddLastCopiedInApp = self.autoAddLastCopiedSwitch.isOn
    }
    
    @IBAction func didToggleStoreFormattingInfoSwitch(_ sender: UISwitch) {
        DefaultsManager.storeClipFormattingInApp = self.storeFormattingInfoSwitch.isOn
    }
    
    @IBAction func didToggleWrapClipsInKeyboardSwitch(_ sender: UISwitch) {
        DefaultsManager.wrapClipsInKeyboard = self.wrapClipsInKeyboardSwitch.isOn
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 4
        }
        else if section == 3 {
            return 2
        }
        return 1
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
