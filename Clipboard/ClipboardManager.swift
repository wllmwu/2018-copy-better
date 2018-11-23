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
    
    /* pasteboard representations todo:
     * rtf
     * html
     * plaintext
     */
    
    static func retrieveFromPasteboard() -> [String : Any] {
        let pasteboard: UIPasteboard = UIPasteboard.general
        print("Pasteboard items: \(pasteboard.items)")
        if let item = pasteboard.items.first {
            return item
        }
        return [:]
    }
    
    static func copyToPasteboard(item: [String : Any]) {
        UIPasteboard.general.items = [item]
    }
    
    static func textFromRtf(inItem item: [String : Any]) -> NSAttributedString? {
        if let rtfData = item[kUTTypeRTF as String] as? Data {
            do {
                let rtf: NSAttributedString = try NSAttributedString(data: rtfData, options: [.documentType : NSAttributedString.DocumentType.rtf], documentAttributes: nil)
                return rtf
            }
            catch let error as NSError {
                print("Found RTF data, but couldn't convert to NSAttributedString. \(error), \(error.userInfo)")
            }
        }
        return nil
    }
    
    static func textFromHtml(inItem item: [String : Any]) -> NSAttributedString? {
        if let htmlData = item[kUTTypeHTML as String] as? Data {
            do {
                let html: NSAttributedString = try NSAttributedString(data: htmlData, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                return html
            }
            catch let error as NSError {
                print("Found HTML data, but couldn't convert to NSAttributedString. \(error), \(error.userInfo)")
            }
        }
        return nil
    }
    
    static func textFromPlaintext(inItem item: [String : Any]) -> String? {
        if let plaintext = item[kUTTypePlainText as String] as? String {
            return plaintext
        }
        return nil
    }

}
