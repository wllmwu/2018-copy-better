//
//  ShareViewController.swift
//  Clips Share
//
//  Created by William Wu on 1/7/19.
//  Copyright © 2019 William Wu. All rights reserved.
//

import UIKit
import Social
import CoreData
import MobileCoreServices
import ClipsKit

class ShareViewController: SLComposeServiceViewController, ShareConfigureViewControllerDelegate {
    
    private var clipTitle: String?
    private var clipContents: [String : Any] = [:]
    
    private var rootFolder: Folder!
    private var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let container = ClipsPersistentContainer(name: "Clips")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.managedObjectContext = container.viewContext
        
        if let rootFolder = Folder.getRootFolder(context: self.managedObjectContext) {
            self.rootFolder = rootFolder
        }
        
        if let content = self.extensionContext!.inputItems.first as? NSExtensionItem {
            let provider: NSItemProvider = content.attachments!.first!
            if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                if let attributedString = content.attributedContentText {
                    self.clipContents[kUTTypeHTML as String] = attributedString.attributedToHTML
                    self.clipContents[kUTTypePlainText as String] = attributedString.string
                }
            }
            else if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { url, error in
                    if let sharedURL = url as? URL {
                        self.clipContents[kUTTypeURL as String] = sharedURL
                        self.clipContents[kUTTypePlainText as String] = sharedURL.absoluteString
                    }
                }
            }
            else if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (image, error) in
                    if let url = image as? URL {
                        self.clipContents[kUTTypeImage as String] = try! Data(contentsOf: url)
                    }
                    else if let data = image as? Data {
                        self.clipContents[kUTTypeImage as String] = data
                    }
                }
            }
        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        self.saveClip(with: self.clipContents, title: self.clipTitle)
    
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
    
    private func saveClip(with contents: [String : Any], title: String?) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.managedObjectContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        // create new clip
        let clip = Clip(entity: entity, insertInto: self.managedObjectContext)
        clip.title = title
        clip.contents = contents
        clip.index = 0
        
        // reassign indices
        for c in self.rootFolder.clipsArray {
            c.index += 1
        }
        clip.folder = self.rootFolder
        
        self.saveContext()
    }
    
    private func saveContext() {
        do {
            try self.managedObjectContext.save()
            DefaultsManager.shouldRefreshAppContext = true
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Share configure view controller delegate
    
    func setTitle(_ title: String?) {
        self.clipTitle = title
        self.reloadConfigurationItems()
    }

}
