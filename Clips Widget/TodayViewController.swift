//
//  TodayViewController.swift
//  Clips Widget
//
//  Created by William Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData
import ClipsKit

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var openAppButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomCompactConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomExpandedConstraint: NSLayoutConstraint!
    
    private var managedObjectContext: NSManagedObjectContext!
    private var rootFolder: Folder!
    private var clips: [Clip] = []
    private var numItems: Int = 5
    
    private var showLastCopied: Bool = true
    private var lastCopied: [String : Any] = [:]
    private var pasteboardChangeCount: Int = 0
    
    private let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        self.tableView.estimatedRowHeight = 44
        self.extensionContext!.widgetLargestAvailableDisplayMode = .expanded
        
        let container = ClipsPersistentContainer(name: "Clips")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.managedObjectContext = container.viewContext
        
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.addLastCopied), name: Notification.Name("AddLastCopiedInWidget"), object: nil)
        
        if !self.defaults.bool(forKey: "launchedBefore") {
            // main app has never been launched - set some default settings and data
            container.setUpFirstLaunch()
        }
        else if !self.defaults.bool(forKey: "launched2.0") {
            // has launched before updating to version 2.0 - migrate old clips to the new model
            container.migrateModelV1To2()
            defaults.set(true, forKey: "launched2.0")
        }
        
        // fetch the root folder
        let request: NSFetchRequest = NSFetchRequest<Folder>(entityName: "Folder")
        request.predicate = NSPredicate(format: "superfolder == NIL")
        do {
            self.rootFolder = try self.managedObjectContext.fetch(request).first
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
        }
        
        self.loadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }*/
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.extensionContext!.widgetActiveDisplayMode == .expanded {
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
    
    private func loadData() {
        //DispatchQueue.global(qos: .utility).async {
            self.showLastCopied = self.defaults.bool(forKey: "showLastCopiedInWidget")
            if self.showLastCopied && self.pasteboardChangeCount != UIPasteboard.general.changeCount {
                self.pasteboardChangeCount = UIPasteboard.general.changeCount
                self.lastCopied = ClipboardManager.retrieveFromPasteboard()
            }
            
            self.numItems = self.defaults.integer(forKey: "numClipsInWidget")
            let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            fetchRequest.predicate = NSPredicate(format: "isFavorite == true")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true), NSSortDescriptor(key: "index", ascending: true)]
            do {
                self.clips = try self.managedObjectContext.fetch(fetchRequest)
            }
            catch let error as NSError {
                print("Couldn't fetch. \(error), \(error.userInfo)")
            }
            
            //DispatchQueue.main.async {
                self.tableView.reloadData()
            //}
        //}
    }
    
    @objc func addLastCopied() {
        if self.lastCopied.count > 0 {
            guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
                print("Couldn't find entity description.")
                return
            }
            
            // create new clip
            let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
            clip.title = nil
            clip.contents = self.lastCopied
            clip.index = 0
            clip.isFavorite = true
            
            self.clips.insert(clip, at: 0)
            
            // reassign indices
            for c in self.rootFolder.clipsArray {
                c.index += 1
            }
            clip.folder = self.rootFolder
            
            self.saveContext()
            self.tableView.reloadData()
        }
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    @IBAction func openAppButtonTapped(_ sender: UIButton) {
        self.extensionContext!.open(URL(string: "copybetter://")!, completionHandler: { (success) in
            if !success {
                print("Error opening app from Today extension")
            }
        })
    }
    
    // MARK: - Widget providing
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        self.loadData()
        completionHandler(.newData)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        let expanded: Bool = (activeDisplayMode == .expanded)
        let expandedHeight: CGFloat = CGFloat(self.numItems) * self.tableView.estimatedRowHeight + 38
        self.preferredContentSize = expanded ? CGSize(width: maxSize.width, height: expandedHeight) : maxSize
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let num = max(self.clips.count, 1) + (self.showLastCopied ? 1 : 0)
        if self.extensionContext!.widgetActiveDisplayMode == .compact {
            return min(num, 2)
        }
        else {
            return min(num, self.numItems)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && self.showLastCopied {
            let cell: WidgetClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! WidgetClipTableViewCell
            cell.setContents(self.lastCopied)
            return cell
        }
        else if self.clips.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "HelpCell", for: indexPath)
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
