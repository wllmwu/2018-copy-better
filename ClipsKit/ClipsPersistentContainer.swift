//
//  ClipsPersistentContainer.swift
//  Clips
//
//  Created by Bill Wu on 12/1/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

public class ClipsPersistentContainer: NSPersistentContainer {
    
    public override class func defaultDirectoryURL() -> URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.williamwu.clips")!
    }
    
    /**
     Initializes default settings and data for the app group. Should be called only once ever, on the app's first launch.
     */
    public func setUpFirstLaunch() {
        if let root = self.createRootFolder() {
            self.addDefaultData(rootFolder: root)
        }
    }
    
    /**
     Creates the root folder that should contain all other folders and clips. Should only ever be called once.
     */
    private func createRootFolder() -> Folder? {
        guard let folderEntity = NSEntityDescription.entity(forEntityName: "Folder", in: self.viewContext) else {
            print("Couldn't find folder entity description.")
            return nil
        }
        
        // check if root folder already exists
        if let _ = Folder.getRootFolder(context: self.viewContext) {
            return nil
        }
        
        let folder: Folder = Folder(entity: folderEntity, insertInto: self.viewContext)
        folder.name = "root"
        folder.index = 0
        return folder
    }
    
    /**
     Inserts the two default clips into the managed object context of this container. Should only ever be called once.
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
    public func migrateModelV1To2() {
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
