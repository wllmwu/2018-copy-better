//
//  Folder+CoreDataClass.swift
//  Clips
//
//  Created by Bill Wu on 8/12/20.
//  Copyright © 2020 William Wu. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Folder)
public class Folder: NSManagedObject {
    
    /**
     A computed property that converts this folder's `subfolders` attribute into a `[Folder]` array, sorted by the `index` attribute.
     */
    public var subfoldersArray: [Folder] {
        let set = self.subfolders as? Set<Folder> ?? []
        return set.sorted(by: {
            $0.index < $1.index
        })
    }
    
    /**
     A computed property that converts this folder's `clips` attribute into a `[Clip]` array, sorted by the `index` attribute.
     */
    public var clipsArray: [Clip] {
        let set = self.clips as? Set<Clip> ?? []
        return set.sorted(by: {
            $0.index < $1.index
        })
    }
    
    public static func getRootFolder(context: NSManagedObjectContext) -> Folder? {
        let request = NSFetchRequest<Folder>(entityName: "Folder")
        request.predicate = NSPredicate(format: "(superfolder == NIL) AND (name LIKE 'root')")
        do {
            return try context.fetch(request).first
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    public static func getRecentlyDeletedFolder(context: NSManagedObjectContext) -> Folder? {
        let request = NSFetchRequest<Folder>(entityName: "Folder")
        request.predicate = NSPredicate(format: "(superfolder == NIL) AND (name LIKE 'deleted')")
        do {
            return try context.fetch(request).first
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    public static func deleteFolder(_ folder: Folder, context: NSManagedObjectContext) {
        guard let deletedFolder = Folder.getRecentlyDeletedFolder(context: context) else {
            print("No recently deleted folder")
            return
        }
        Folder.deleteFolderHelper(folder, deletedFolder, context)
    }
    
    private static func deleteFolderHelper(_ folder: Folder, _ deletedFolder: Folder, _ context: NSManagedObjectContext) {
        for clip in folder.clipsArray {
            Clip.deleteClipHelper(clip, deletedFolder, context)
        }
        for subfolder in folder.subfoldersArray {
            Folder.deleteFolderHelper(subfolder, deletedFolder, context)
        }
        context.delete(folder)
    }
    
}
