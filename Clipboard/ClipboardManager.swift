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
        let plaintext: String = str.string
        print("Copied to pasteboard: \"\(plaintext)\"")
        
        UIPasteboard.general.items = [
            [ kUTTypeRTF as String : rtfData, kUTTypePlainText as String : plaintext ]
        ]
    }

}
