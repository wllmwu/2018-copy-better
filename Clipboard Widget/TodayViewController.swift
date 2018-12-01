//
//  TodayViewController.swift
//  Clipboard Widget
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var openAppButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomCompactConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomExpandedConstraint: NSLayoutConstraint!
    
    private var managedObjectContext: NSManagedObjectContext!
    private var clips: [Clip] = []
    
    private var showLastCopied: Bool = true
    private var lastCopied: [String : Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.extensionContext?.widgetActiveDisplayMode == .expanded {
            self.tableViewBottomExpandedConstraint.priority = .defaultHigh
            self.tableViewBottomCompactConstraint.priority = .defaultLow
        }
        else {
            self.tableViewBottomCompactConstraint.priority = .defaultHigh
            self.tableViewBottomExpandedConstraint.priority = .defaultLow
        }
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let expanded: Bool = activeDisplayMode == .expanded
        self.preferredContentSize = expanded ? CGSize(width: maxSize.width, height: 300) : maxSize
        // TODO: calculate preferred height when expanded!
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clips.count + (self.showLastCopied ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: WidgetClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! WidgetClipTableViewCell
        return cell
    }
    
}
