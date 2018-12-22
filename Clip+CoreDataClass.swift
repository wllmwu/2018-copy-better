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
    
    static func addDefaultClip1(entity: NSEntityDescription, context: NSManagedObjectContext) {
        let clip = Clip(entity: entity, insertInto: context)
        clip.title = NSLocalizedString("Shrug", comment: "default clip title 1")
        clip.contents = ClipboardManager.itemForPlaintext("\u{00af}\\_(\u{30c4})_/\u{00af}")
        clip.index = 0
    }
    
    static func addDefaultClip2(entity: NSEntityDescription, context: NSManagedObjectContext) {
        let clip = Clip(entity: entity, insertInto: context)
        clip.title = NSLocalizedString("Example", comment: "default clip title 2")
        let clip2Text: NSMutableAttributedString = NSMutableAttributedString(string: "Cli", attributes: [.font : UIFont.boldSystemFont(ofSize: 17), .foregroundColor : UIColor.red])
        clip2Text.append(NSAttributedString(string: "pbo", attributes: [.font : UIFont.systemFont(ofSize: 17), .foregroundColor : UIColor.green]))
        clip2Text.append(NSAttributedString(string: "ard", attributes: [.font : UIFont.italicSystemFont(ofSize: 17), .foregroundColor : UIColor.blue]))
        clip.contents = ClipboardManager.itemForAttributedString(clip2Text)
        clip.index = 1
    }
    
}
