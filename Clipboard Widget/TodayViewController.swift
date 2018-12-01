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
    private var numClips: Int = 10
    
    private var showLastCopied: Bool = true
    private var lastCopied: [String : Any] = [:]
    
    private let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clipboard")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        let container = ClipboardPersistentContainer(name: "Clipboard")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.managedObjectContext = container.viewContext
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.showLastCopied = self.defaults.bool(forKey: "showLastCopiedInWidget")
        self.numClips = self.defaults.integer(forKey: "numClipsInWidget")
        
        if self.defaults.bool(forKey: "widgetNeedsUpdate") {
            let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            DispatchQueue.global(qos: .utility).async {
                do {
                    let new: [Clip] = try self.managedObjectContext.fetch(fetchRequest)
                    DispatchQueue.main.async {
                        self.clips = new
                        self.tableView.reloadData()
                    }
                }
                catch let error as NSError {
                    print("Couldn't fetch. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.extensionContext?.widgetActiveDisplayMode == .expanded {
            self.tableViewBottomExpandedConstraint.priority = .defaultHigh
            self.tableViewBottomCompactConstraint.priority = .defaultLow
            self.openAppButton.isHidden = false
        }
        else {
            self.tableViewBottomCompactConstraint.priority = .defaultHigh
            self.tableViewBottomExpandedConstraint.priority = .defaultLow
            self.openAppButton.isHidden = true
        }
    }
    
    // MARK: - Instance methods
    
    /*private func updateData() {
        let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        do {
            self.clips = try self.managedObjectContext.fetch(fetchRequest)
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
        }
    }*/
    
    @IBAction func openAppButtonTapped(_ sender: UIButton) {
    }
    
    // MARK: - Widget providing
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        do {
            if self.defaults.bool(forKey: "widgetNeedsUpdate") {
                let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                self.clips = try self.managedObjectContext.fetch(fetchRequest)
                self.tableView.reloadData()
                self.defaults.set(false, forKey: "widgetNeedsUpdate")
                completionHandler(.newData)
            }
            else {
                completionHandler(.noData)
            }
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
            completionHandler(.failed)
        }
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        // completionHandler(NCUpdateResult.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let expanded: Bool = activeDisplayMode == .expanded
        let expandedHeight: CGFloat = CGFloat(self.clips.count + (self.showLastCopied ? 1 : 0)) * self.tableView.estimatedRowHeight + 38
        self.preferredContentSize = expanded ? CGSize(width: maxSize.width, height: expandedHeight) : maxSize
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.extensionContext?.widgetActiveDisplayMode == .compact {
            return 2
        }
        return self.clips.count + (self.showLastCopied ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && self.showLastCopied {
            let cell: WidgetClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! WidgetClipTableViewCell
            cell.setParentViewController(self)
            cell.setContents(self.lastCopied)
            return cell
        }
        
        let clip: Clip = self.clips[indexPath.row - (self.showLastCopied ? 1 : 0)]
        let cell: WidgetClipTableViewCell
        if let title = clip.title {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipWithTitleCell", for: indexPath) as! WidgetClipTableViewCell
            cell.setTitle(title)
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "ClipNoTitleCell", for: indexPath) as! WidgetClipTableViewCell
        }
        cell.setContents(clip.contents)
        return cell
    }
    
}
