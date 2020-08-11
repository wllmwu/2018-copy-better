//
//  ClipsPersistentContainer.swift
//  Clips
//
//  Created by Bill Wu on 12/1/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class ClipsPersistentContainer: NSPersistentContainer {
    
    override class func defaultDirectoryURL() -> URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.williamwu.clips")!
    }
    
    /**
     Initializes default settings and data for the app group. Should be called only once ever, on the app's first launch.
     */
    func setUpFirstLaunch() {
        let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
        defaults.set(true, forKey: "showLastCopiedInMain")
        defaults.set(true, forKey: "showLastCopiedInWidget")
        defaults.set(5, forKey: "numClipsInWidget")
        
        self.addDefaultData()
        defaults.set(2, forKey: "nextClipID")
        defaults.set(0, forKey: "nextFolderID")
        defaults.set(true, forKey: "widgetNeedsUpdate")
        
        defaults.set(true, forKey: "launchedBefore")
        defaults.set(true, forKey: "launched2.0")
    }
    
    /**
     Inserts the two default clips into the managed object context of this container.
     */
    private func addDefaultData() {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.viewContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        Clip.addDefaultClip1(entity: entity, context: self.viewContext)
        Clip.addDefaultClip2(entity: entity, context: self.viewContext)
        
        do {
            try self.viewContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    /**
     Migrates the existing clip records from version 1 to version 2 of the Core Data model (adding `id` and `folderID` attributes, assuming that the model itself has already been migrated automatically). Existing clips will have `id` equal to their current index in the list, and will have `folderID` -1. Also sets the next available ID numbers in the user defaults.
     */
    func migrateModelV1To2() {
        let defaults: UserDefaults = UserDefaults.init(suiteName: "group.com.williamwu.clips")!
        let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        do {
            let clips: [Clip] = try self.viewContext.fetch(fetchRequest)
            for i in 0..<clips.count {
                let clip: Clip = clips[i]
                clip.id = Int32(i)
                clip.folderID = -1
            }
            try self.viewContext.save()
            defaults.set(clips.count, forKey: "nextClipID")
            defaults.set(0, forKey: "nextFolderID")
        }
        catch let error as NSError {
            print("Couldn't fetch/save. \(error), \(error.userInfo)")
        }
    }
    
}
