//
//  ClipboardManager.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
//import CoreData
import MobileCoreServices

class ClipboardManager: NSObject {
    
//    private static var clips: [NSManagedObject] = []
    
//    private static var clipTitles: [String] = []
//    private static var clipContents: [String] = []
    /*
    static func retrieveClips() {
        let url: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.williamwu.clipboard")
        if let groupUrl = url {
            let fileUrl = groupUrl.appendingPathComponent("Clipboard.plist")
            if FileManager.default.fileExists(atPath: fileUrl.path) { // file has already been created
                //
            }
            else { // need to create the file
                //
            }
        }
    }
    
    private static func saveClip(title: String, contents: NSAttributedString, index: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        let entity: NSEntityDescription = NSEntityDescription.entity(forEntityName: "Clip", in: managedContext)!
        let clip: NSManagedObject = NSManagedObject(entity: entity, insertInto: managedContext)
        
        clip.setValue(title, forKey: "title")
        clip.setValue(contents, forKey: "contents")
        clip.setValue(index, forKey: "index")
        
        do {
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    static func addClip(withTitle title: String, contents: NSAttributedString, index: Int) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        let entity: NSEntityDescription = NSEntityDescription.entity(forEntityName: "Clip", in: managedContext)!
        let clip: NSManagedObject = NSManagedObject(entity: entity, insertInto: managedContext)
        
        clip.setValue(title, forKey: "title")
        clip.setValue(contents, forKey: "contents")
        clip.setValue(index, forKey: "index")
        
        do {
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save (adding). \(error), \(error.userInfo)")
        }
    }
    
    static func deleteClip(_ clip: NSManagedObject) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext: NSManagedObjectContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(clip)
        
        do {
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save (deleting). \(error), \(error.userInfo)")
        }
    }
    
    static func moveClip(_ clip: NSManagedObject, )
    */
    static func retrieveFromPasteboard() -> NSAttributedString {
        let pasteboard: UIPasteboard = UIPasteboard.general
        // look for RTF first
        if pasteboard.contains(pasteboardTypes: [kUTTypeRTF as String], inItemSet: nil) {
            if let data = pasteboard.data(forPasteboardType: kUTTypeRTF as String, inItemSet: nil)?.first as? Data {
                let attributedString = try! NSAttributedString(data: data, options: [:], documentAttributes: nil)
                print("Found RTF (string: \"\(attributedString.string)\")")
                return attributedString
            }
        }
        // look for plaintext next
        else if pasteboard.contains(pasteboardTypes: [kUTTypePlainText as String], inItemSet: nil) {
            let string = pasteboard.values(forPasteboardType: kUTTypePlainText as String, inItemSet: nil)?.first! as! String
            print("Found plaintext: \"\(string)\"")
            return NSAttributedString(string: string)
        }
        print("Neither RTF nor plaintext found in pasteboard")
        return NSAttributedString()
    }
    
    static func copyToPasteboard(attributedString str: NSAttributedString) {
        let range: NSRange = NSMakeRange(0, str.length)
        let rtfData: Data = try! str.data(from: range, documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf])
        let plainText: String = str.string
        
        UIPasteboard.general.items = [
            [ kUTTypeRTF as String : rtfData, kUTTypePlainText as String : plainText ]
        ]
        /*UIPasteboard.general.setItems([
            [ kUTTypeRTF as String : rtfData, kUTTypePlainText as String : plainText ]
            ], options: [:])*/
    }

}
