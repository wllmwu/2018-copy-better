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
    
    /* Pasteboard representations, in order of display preference:
     * rtf
     * html
     * plaintext (utf8, utf16, none)
     * image (png, jpg, gif, tif, bmp)
     */
    
    // MARK: - Interface with system pasteboard
    
    static func retrieveFromPasteboard() -> [String : Any] {
        let pasteboard: UIPasteboard = UIPasteboard.general
        print("Pasteboard items: \(pasteboard.items)")
        if let item = pasteboard.items.first {
            var newItem: [String : Any] = [:]
            if let rtf = item[kUTTypeRTF as String] {
                newItem[kUTTypeRTF as String] = rtf
            }
            if let html = item[kUTTypeHTML as String] {
                newItem[kUTTypeHTML as String] = html
            }
            if let utf8Plaintext = item[kUTTypeUTF8PlainText as String] {
                newItem[kUTTypeUTF8PlainText as String] = utf8Plaintext
            }
            if let utf16Plaintext = item[kUTTypeUTF16PlainText as String] {
                newItem[kUTTypeUTF16PlainText as String] = utf16Plaintext
            }
            if let plaintext = item[kUTTypePlainText as String] {
                newItem[kUTTypePlainText as String] = plaintext
            }
            if let png = item[kUTTypePNG as String] {
                newItem[kUTTypePNG as String] = png
            }
            if let jpg = item[kUTTypeJPEG as String] {
                newItem[kUTTypeJPEG as String] = jpg
            }
            if let gif = item[kUTTypeGIF as String] {
                newItem[kUTTypeGIF as String] = gif
            }
            if let tif = item[kUTTypeTIFF as String] {
                newItem[kUTTypeTIFF as String] = tif
            }
            if let bmp = item[kUTTypeBMP as String] {
                newItem[kUTTypeBMP as String] = bmp
            }
            return newItem
        }
        return [:]
    }
    
    static func copyToPasteboard(item: [String : Any]) {
        var itemVar: [String : Any] = item
        if let png = itemVar[kUTTypePNG as String] as? UIImage {
            if let pngData = UIImagePNGRepresentation(png) {
                itemVar[kUTTypePNG as String] = pngData
            }
        }
        if let jpg = itemVar[kUTTypeJPEG as String] as? UIImage {
            if let jpgData = UIImageJPEGRepresentation(jpg, 1) {
                itemVar[kUTTypeJPEG as String] = jpgData
            }
        }
        UIPasteboard.general.items = [itemVar]
    }
    
    // MARK: - Interpreters for data representations in pasteboard items
    
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
        if let htmlString = item[kUTTypeHTML as String] as? String {
            if let html = htmlString.htmlToAttributed {
                return html
            }
        }
        return nil
    }
    
    static func textFromPlaintext(inItem item: [String : Any]) -> String? {
        if let utf8Plaintext = item[kUTTypeUTF8PlainText as String] as? String {
            return utf8Plaintext
        }
        else if let utf16Plaintext = item[kUTTypeUTF16PlainText as String] as? String {
            return utf16Plaintext
        }
        else if let plaintext = item[kUTTypePlainText as String] as? String {
            return plaintext
        }
        return nil
    }
    
    /*static func imageExists(inItem item: [String : Any]) -> Bool {
        if let _ = item[kUTTypePNG as String] as? UIImage {
            return true
        }
        else if let _ = item[kUTTypeJPEG as String] as? UIImage {
            return true
        }
        else if let _ = item[kUTTypeGIF as String] as? UIImage {
            return true
        }
        else if let _ = item[kUTTypeTIFF as String] as? UIImage {
            return true
        }
        else if let _ = item[kUTTypeBMP as String] as? UIImage {
            return true
        }
        return false
    }*/
    
    /*static func imageFromImage(inItem item: [String : Any]) -> UIImage? {
        var image: UIImage?
        if let png = item[kUTTypePNG as String] as? UIImage {
            image = png
        }
        else if let jpg = item[kUTTypeJPEG as String] as? UIImage {
            image = jpg
        }
        else if let gif = item[kUTTypeGIF as String] as? UIImage {
            image = gif
        }
        else if let tif = item[kUTTypeTIFF as String] as? UIImage {
            image = tif
        }
        else if let bmp = item[kUTTypeBMP as String] as? UIImage {
            image = bmp
        }
        return image
    }*/
    
    static func imageFromImage(inItem item: [String : Any], maxImageWidth: CGFloat?, maxImageHeight: CGFloat?) -> UIImage? {
        var image: UIImage
        if let png = item[kUTTypePNG as String] as? UIImage {
            image = png
        }
        else if let jpg = item[kUTTypeJPEG as String] as? UIImage {
            image = jpg
        }
        else if let gif = item[kUTTypeGIF as String] as? UIImage {
            image = gif
        }
        else if let tif = item[kUTTypeTIFF as String] as? UIImage {
            image = tif
        }
        else if let bmp = item[kUTTypeBMP as String] as? UIImage {
            image = bmp
        }
        else {
            return nil
        }
        
        let size: CGSize = image.size
        var scaleFactor: CGFloat?
        if let maxWidth = maxImageWidth {
            if size.width > maxWidth {
                // scale image down to fit width
                scaleFactor = maxWidth / size.width
                
            }
        }
        else if let maxHeight = maxImageHeight {
            if size.height > maxHeight {
                // scale image down to fit height
                scaleFactor = maxHeight / size.height
            }
        }
        
        if let scale = scaleFactor {
            let newSize: CGSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = newImage
            }
            UIGraphicsEndImageContext()
        }
        
        return image
    }
    
    static func textFromImage(_ image: UIImage) -> NSAttributedString {
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = image
        return NSAttributedString(attachment: attachment)
    }
    
    /*static func scaleImage(_ originalImage: UIImage, maxImageWidth: CGFloat?, maxImageHeight: CGFloat?) -> UIImage {
        let size: CGSize = originalImage.size
        var scaleFactor: CGFloat?
        if let maxWidth = maxImageWidth {
            if size.width > maxWidth {
                // scale image down to fit width
                scaleFactor = maxWidth / size.width
                
            }
        }
        else if let maxHeight = maxImageHeight {
            if size.height > maxHeight {
                // scale image down to fit height
                scaleFactor = maxHeight / size.height
            }
        }
        
        var image = originalImage
        if let scale = scaleFactor {
            let newSize: CGSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = newImage
            }
            UIGraphicsEndImageContext()
        }
        return image
    }*/
    
    /*static func prepareTextFromImage(_ originalImage: UIImage, maxImageWidth: CGFloat?, maxImageHeight: CGFloat?) -> NSAttributedString {
        let size: CGSize = originalImage.size
        var scaleFactor: CGFloat?
        if let maxWidth = maxImageWidth {
            if size.width > maxWidth {
                // scale image down to fit width
                scaleFactor = maxWidth / size.width
                
            }
        }
        else if let maxHeight = maxImageHeight {
            if size.height > maxHeight {
                // scale image down to fit height
                scaleFactor = maxHeight / size.height
            }
        }
        
        var image = originalImage
        if let scale = scaleFactor {
            let newSize: CGSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = newImage
            }
            UIGraphicsEndImageContext()
        }
        
        let textAttachment: NSTextAttachment = NSTextAttachment()
        textAttachment.image = image
        return NSAttributedString(attachment: textAttachment)
    }*/
    
    /*static func textFromImage(inItem item: [String : Any], maxImageWidth: CGFloat?, maxImageHeight: CGFloat?) -> NSAttributedString? {
        var image: UIImage
        if let png = item[kUTTypePNG as String] as? UIImage {
            image = png
        }
        else if let jpg = item[kUTTypeJPEG as String] as? UIImage {
            image = jpg
        }
        else if let gif = item[kUTTypeGIF as String] as? UIImage {
            image = gif
        }
        else if let tif = item[kUTTypeTIFF as String] as? UIImage {
            image = tif
        }
        else if let bmp = item[kUTTypeBMP as String] as? UIImage {
            image = bmp
        }
        else {
            return nil
        }
        
        /*let size: CGSize = image.size
        var scaleFactor: CGFloat?
        if let maxWidth = maxImageWidth {
            if size.width > maxWidth {
                // scale image down to fit width
                scaleFactor = maxWidth / size.width
                
            }
        }
        else if let maxHeight = maxImageHeight {
            if size.height > maxHeight {
                // scale image down to fit height
                scaleFactor = maxHeight / size.height
            }
        }
        
        if let scale = scaleFactor {
            let newSize: CGSize = CGSize(width: size.width * scale, height: size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                image = newImage
            }
            UIGraphicsEndImageContext()
        }*/
        
        let textAttachment: NSTextAttachment = NSTextAttachment()
        textAttachment.image = image
        return NSAttributedString(attachment: textAttachment)
    }*/

}
