//
//  Clip+CoreDataClass.swift
//  Clips
//
//  Created by Bill Wu on 11/17/18.
//  Copyright © 2018 William Wu. All rights reserved.
//
//

import Foundation
import CoreData
import Intents
import UIKit

@objc(Clip)
public class Clip: NSManagedObject {
    
    public var uriRepresentation: String {
        return self.objectID.uriRepresentation().absoluteString
    }
    
    public static func getClip(with uriString: String, context: NSManagedObjectContext) -> Clip? {
        guard let uri = URL(string: uriString), let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
            return nil
        }
        
        do {
            return try context.existingObject(with: objectID) as? Clip
        } catch let error as NSError {
            print("Couldn't fetch.  \(error), \(error.userInfo)")
            return nil
        }
    }
    
    public static func addDefaultClip1(entity: NSEntityDescription, context: NSManagedObjectContext, rootFolder: Folder) {
        let clip = Clip(entity: entity, insertInto: context)
        clip.title = AppStrings.DEFAULT_CLIP_TITLE_1
        clip.contents = ClipboardManager.itemFromPlaintext(AppStrings.DEFAULT_CLIP_CONTENTS_1)
        clip.folder = rootFolder
        clip.index = 0
    }
    
    public static func addDefaultClip2(entity: NSEntityDescription, context: NSManagedObjectContext, rootFolder: Folder) {
        let clip = Clip(entity: entity, insertInto: context)
        clip.title = AppStrings.DEFAULT_CLIP_TITLE_2
        let clip2Text = NSMutableAttributedString(string: "Cli", attributes: [.font : UIFont.boldSystemFont(ofSize: 17), .foregroundColor : UIColor.red])
        clip2Text.append(NSAttributedString(string: "pbo", attributes: [.font : UIFont.systemFont(ofSize: 17), .foregroundColor : UIColor.green]))
        clip2Text.append(NSAttributedString(string: "ard", attributes: [.font : UIFont.italicSystemFont(ofSize: 17), .foregroundColor : UIColor.blue]))
        clip.contents = ClipboardManager.itemFromAttributedString(clip2Text)
        clip.folder = rootFolder
        clip.index = 1
    }
    
    public static func getFavorites(context: NSManagedObjectContext, limit: Int?) -> [Clip]? {
        let request: NSFetchRequest = NSFetchRequest<Clip>(entityName: "Clip")
        request.predicate = NSPredicate(format: "isFavorite == true")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        if let lim = limit {
            request.fetchLimit = lim
        }
        
        do {
            return try context.fetch(request)
        }
        catch let error as NSError {
            print("Couldn't fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    public static func getRecentlyDeleted(context: NSManagedObjectContext) -> [Clip] {
        if let folder = Folder.getRecentlyDeletedFolder(context: context) {
            return folder.clipsArray
        }
        return []
    }
    
    public static func deleteClip(_ clip: Clip, context: NSManagedObjectContext) {
        guard let deletedFolder = Folder.getRecentlyDeletedFolder(context: context) else {
            print("No recently deleted folder")
            return
        }
        Clip.deleteClipHelper(clip, deletedFolder, context)
    }
    
    static func deleteClipHelper(_ clip: Clip, _ deletedFolder: Folder, _ context: NSManagedObjectContext) {
        clip.folder = deletedFolder
        clip.isFavorite = false
        clip.deleteDate = Date(timeIntervalSinceNow: 30 * 86400)
        Clip.deleteCopyInteractions(for: clip)
    }
    
    public static func restoreClip(_ clip: Clip, folder: Folder, context: NSManagedObjectContext) {
        clip.folder = folder
        clip.index = Int16(folder.clips?.count ?? 0)
        clip.deleteDate = nil
    }
    
}

extension Clip {
    
    public static func getIntentReference(for clip: Clip) -> ClipReference? {
        guard let clipTitle = clip.title else {
            return nil
        }
        if clipTitle.count == 0 {
            return nil
        }
        return ClipReference(identifier: clip.uriRepresentation, display: clipTitle)
    }
    
    public static func getReferencedClip(from intentReference: ClipReference, context: NSManagedObjectContext) -> Clip? {
        guard let uriString = intentReference.identifier else {
            return nil
        }
        return Clip.getClip(with: uriString, context: context)
    }
    
    public static func getCopyIntent(for clip: Clip) -> CopyClipIntent? {
        guard let clipReference = Clip.getIntentReference(for: clip) else {
            return nil
        }
        let intent = CopyClipIntent()
        intent.clip = clipReference
        return intent
    }
    
    public static func donateCopyInteraction(with clip: Clip, completion: ((Error?) -> Void)? = nil) {
        guard let intent = Clip.getCopyIntent(for: clip) else {
            return
        }
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.groupIdentifier = intent.clip!.identifier
        interaction.donate(completion: completion)
    }
    
    public static func deleteCopyInteractions(for clip: Clip, completion: ((Error?) -> Void)? = nil) {
        INInteraction.delete(with: clip.uriRepresentation, completion: completion)
    }
    
}
