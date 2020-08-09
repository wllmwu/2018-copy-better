//
//  TodayViewController.swift
//  Clips Widget
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
    private var allClips: [Clip] = []
    private var numClips: Int = 5
    
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
            self.defaults.set(true, forKey: "showLastCopiedInMain")
            self.defaults.set(true, forKey: "showLastCopiedInWidget")
            self.defaults.set(5, forKey: "numClipsInWidget")
            
            self.addDefaultData()
            self.defaults.set(true, forKey: "widgetNeedsUpdate")
            
            self.defaults.set(true, forKey: "launchedBefore")
        }
        else {
            self.showLastCopied = self.defaults.bool(forKey: "showLastCopiedInWidget")
            self.numClips = self.defaults.integer(forKey: "numClipsInWidget")
            
            let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            do {
                let new: [Clip] = try self.managedObjectContext.fetch(fetchRequest)
                self.allClips = new
                self.getClips()
                self.defaults.set(false, forKey: "widgetNeedsUpdate")
                self.tableView.reloadData()
            }
            catch let error as NSError {
                print("Couldn't fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
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
    
    private func addDefaultData() {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        Clip.addDefaultClip1(entity: entity, context: self.managedObjectContext)
        Clip.addDefaultClip2(entity: entity, context: self.managedObjectContext)
        
        do {
            try self.managedObjectContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    private func loadData() {
        DispatchQueue.global(qos: .utility).async {
            var shouldReload: Bool = false
            self.showLastCopied = self.defaults.bool(forKey: "showLastCopiedInWidget")
            if self.showLastCopied && self.pasteboardChangeCount != UIPasteboard.general.changeCount {
                self.pasteboardChangeCount = UIPasteboard.general.changeCount
                self.lastCopied = ClipboardManager.retrieveFromPasteboard()
                shouldReload = true
            }
            
            self.numClips = self.defaults.integer(forKey: "numClipsInWidget")
            if self.defaults.bool(forKey: "widgetNeedsUpdate") {
                let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                do {
                    let new: [Clip] = try self.managedObjectContext.fetch(fetchRequest)
                    self.allClips = new
                    self.getClips()
                    self.defaults.set(false, forKey: "widgetNeedsUpdate")
                    shouldReload = true
                }
                catch let error as NSError {
                    print("Couldn't fetch. \(error), \(error.userInfo)")
                }
            }
            
            DispatchQueue.main.async {
                if shouldReload {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func getClips() {
        self.clips = Array(self.allClips.prefix(self.numClips))
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
            self.allClips.insert(clip, at: 0)
            
            // reassign indices
            for i in 1..<self.allClips.count {
                self.allClips[i].index += 1
            }
            self.getClips()
            
            self.saveContext()
            self.tableView.reloadData()
        }
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
            self.orderUpdates()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    private func orderUpdates() {
        self.defaults.set(true, forKey: "mainNeedsUpdate")
        self.defaults.set(true, forKey: "keyboardNeedsUpdate")
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
        let expanded: Bool = (activeDisplayMode == .expanded)
        let expandedHeight: CGFloat = CGFloat(self.numClips + (self.showLastCopied ? 1 : 0)) * self.tableView.estimatedRowHeight + 38
        self.preferredContentSize = expanded ? CGSize(width: maxSize.width, height: expandedHeight) : maxSize
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.extensionContext!.widgetActiveDisplayMode == .compact {
            if self.showLastCopied {
                return 1 + ((self.clips.count > 0) ? 1 : 0)
            }
            else if self.clips.count >= 2 {
                return 2
            }
            else {
                return self.clips.count
            }
        }
        return self.clips.count + (self.showLastCopied ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && self.showLastCopied {
            let cell: WidgetClipTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LastCopiedCell", for: indexPath) as! WidgetClipTableViewCell
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
