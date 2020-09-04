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
        
        if let root = self.createRootFolder() {
            self.addDefaultData(rootFolder: root)
        }
        defaults.set(true, forKey: "widgetNeedsUpdate")
        
        defaults.set(true, forKey: "launchedBefore")
        defaults.set(true, forKey: "launched2.0")
    }
    
    /**
     Creates the root folder that should contain all other folders and clips.
     */
    private func createRootFolder() -> Folder? {
        guard let folderEntity = NSEntityDescription.entity(forEntityName: "Folder", in: self.viewContext) else {
            print("Couldn't find folder entity description.")
            return nil
        }
        let folder: Folder = Folder(entity: folderEntity, insertInto: self.viewContext)
        folder.name = "root"
        folder.index = 0
        return folder
    }
    
    /**
     Inserts the two default clips into the managed object context of this container.
     */
    private func addDefaultData(rootFolder: Folder) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Clip", in: self.viewContext) else {
            print("Couldn't find entity description.")
            return
        }
        
        Clip.addDefaultClip1(entity: entity, context: self.viewContext, rootFolder: rootFolder)
        Clip.addDefaultClip2(entity: entity, context: self.viewContext, rootFolder: rootFolder)
        
        do {
            try self.viewContext.save()
        }
        catch let error as NSError {
            print("Couldn't save. \(error), \(error.userInfo)")
        }
    }
    
    /**
     Migrates the existing clip records from version 1 to version 2 of the Core Data model (creates the root folder and moves existing clips inside it).
     */
    func migrateModelV1To2() {
        if let root = self.createRootFolder() {
            // assign all existing clips to be contained in the root folder
            let fetchRequest: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
            do {
                let clips: [Clip] = try self.viewContext.fetch(fetchRequest)
                for clip in clips {
                    clip.folder = root
                }
                try self.viewContext.save()
            }
            catch let error as NSError {
                print("Couldn't fetch/save. \(error), \(error.userInfo)")
            }
        }
    }
    
}
