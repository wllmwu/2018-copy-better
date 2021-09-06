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
        request.predicate = NSPredicate(format: "superfolder == NIL")
        do {
            return try context.fetch(request).first
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
}
