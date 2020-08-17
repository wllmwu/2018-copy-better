//
//  ShareViewController.swift
//  Clips Share
//
//  Created by Bill Wu on 1/7/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit
import Social
import CoreData
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController, ShareConfigureViewControllerDelegate {
    
    private var clipTitle: String?
    private var clipContentsText: NSAttributedString?
    private var clipContentsImageData: Data?
    
    private var allClips: [Clip] = []
    private var managedObjectContext: NSManagedObjectContext!
    private var defaults: UserDefaults = UserDefaults(suiteName: "group.com.williamwu.clips")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let container = ClipsPersistentContainer(name: "Clips")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.managedObjectContext = container.viewContext
        
        let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        do {
            self.allClips = try self.managedObjectContext.fetch(fetchRequest)
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
        }
        
        if let content = self.extensionContext!.inputItems.first as? NSExtensionItem {
            let provider: NSItemProvider = content.attachments!.first!
            if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                if let text = content.attributedContentText {
                    self.clipContentsText = text
                }
            }
            if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (image, error) in
                    OperationQueue.main.addOperation {
                        if let url = image as? URL {
                            self.clipContentsImageData = try! Data(contentsOf: url)
                        }
                        else if let data = image as? Data {
                            self.clipContentsImageData = data
                        }
                    }
                }
            }
        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        if self.contentText.count > 0 {
            self.clipContentsText = NSAttributedString(string: self.contentText)
        }
        else {
            self.clipContentsText = nil
        }
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        var item: [String : Any] = [:]
        if let imageData = self.clipContentsImageData {
            item = [kUTTypeImage as String : imageData]
        }
        else if let text = self.clipContentsText {
            item = ClipboardManager.itemFromAttributedString(text)
        }
        
        if item.count > 0 {
            self.saveClip(withItem: item)
        }
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        if let titleConfig = SLComposeSheetConfigurationItem() {
            titleConfig.title = AppStrings.TITLE_CONFIG_TITLE
            titleConfig.value = self.clipTitle ?? ""
            titleConfig.tapHandler = {
                let viewController = ShareConfigureViewController()
                viewController.delegate = self
                viewController.titleToSet = titleConfig.value
                self.pushConfigurationViewController(viewController)
            }
            return [titleConfig]
        }
        return []
    }
    
    // MARK: - Private instance methods
    
    private func saveClip(withItem item: [String : Any]) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = self.clipTitle
        clip.contents = item
        clip.index = 0
        self.allClips.insert(clip, at: 0)
        
        // reassign indices
        for i in 1..<self.allClips.count {
            self.allClips[i].index += 1
        }
        
        self.saveContext()
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
        self.defaults.set(true, forKey: "widgetNeedsUpdate")
        self.defaults.set(true, forKey: "keyboardNeedsUpdate")
    }
    
    // MARK: - Share configure view controller delegate
    
    func setTitle(_ title: String?) {
        self.clipTitle = title
        self.reloadConfigurationItems()
    }

}
