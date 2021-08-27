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
    
    public static func getIntentReference(for clip: Clip) -> ClipReference? {
        guard let clipTitle = clip.title else {
            return nil
        }
        return ClipReference(identifier: clip.objectID.uriRepresentation().absoluteString, display: clipTitle)
    }
    
    public static func createCopyIntent(with clip: Clip) -> CopyClipIntent? {
        guard let clipReference = Clip.getIntentReference(for: clip) else {
            return nil
        }
        let intent = CopyClipIntent()
        intent.clip = clipReference
        return intent
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
    
}
