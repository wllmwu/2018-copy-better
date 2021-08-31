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
    
    public static func addDefaultClip1(entity: NSEntityDescription, context: NSManagedObjectContext, rootFolder: Folder) {
        let clip = Clip(entity: entity, insertInto: context)
        clip.title = AppStrings.DEFAULT_CLIP_TITLE_1
        clip.contents = ClipboardManager.itemFromPlaintext("\u{00af}\\_(\u{30c4})_/\u{00af}")
        clip.folder = rootFolder
        clip.index = 0
    }
    
    public static func addDefaultClip2(entity: NSEntityDescription, context: NSManagedObjectContext, rootFolder: Folder) {
        let clip = Clip(entity: entity, insertInto: context)
        clip.title = AppStrings.DEFAULT_CLIP_TITLE_2
        let clip2Text: NSMutableAttributedString = NSMutableAttributedString(string: "Cli", attributes: [.font : UIFont.boldSystemFont(ofSize: 17), .foregroundColor : UIColor.red])
        clip2Text.append(NSAttributedString(string: "pbo", attributes: [.font : UIFont.systemFont(ofSize: 17), .foregroundColor : UIColor.green]))
        clip2Text.append(NSAttributedString(string: "ard", attributes: [.font : UIFont.italicSystemFont(ofSize: 17), .foregroundColor : UIColor.blue]))
        clip.contents = ClipboardManager.itemFromAttributedString(clip2Text)
        clip.folder = rootFolder
        clip.index = 1
    }
    
}

extension Clip {
    
    private var uriRepresentation: String {
        return self.objectID.uriRepresentation().absoluteString
    }
    
    public static func getIntentReference(for clip: Clip) -> ClipReference? {
        guard let clipTitle = clip.title else {
            return nil
        }
        return ClipReference(identifier: clip.uriRepresentation, display: clipTitle)
    }
    
    public static func getReferencedClip(from intentReference: ClipReference, context: NSManagedObjectContext) -> Clip? {
        guard let uriString = intentReference.identifier, let uri = URL(string: uriString), let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
            return nil
        }
        
        do {
            return try context.existingObject(with: objectID) as? Clip
        } catch let error as NSError {
            print("Couldn't fetch.  \(error), \(error.userInfo)")
            return nil
        }
    }
    
    public static func donateCopyInteraction(with clip: Clip, completion: ((Error?) -> Void)? = nil) {
        guard let clipReference = Clip.getIntentReference(for: clip) else {
            return
        }
        
        let intent = CopyClipIntent()
        intent.clip = clipReference
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.groupIdentifier = clipReference.identifier
        
        interaction.donate(completion: completion)
    }
    
    public static func deleteCopyInteractions(for clip: Clip, completion: ((Error?) -> Void)? = nil) {
        INInteraction.delete(with: clip.uriRepresentation, completion: completion)
    }
    
}
