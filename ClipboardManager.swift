//
//  ClipboardManager.swift
//  Clips
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
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
            if let pngData = png.pngData() {
                itemVar[kUTTypePNG as String] = pngData
            }
        }
        if let jpg = itemVar[kUTTypeJPEG as String] as? UIImage {
            if let jpgData = jpg.jpegData(compressionQuality: 1) {
                itemVar[kUTTypeJPEG as String] = jpgData
            }
        }
        UIPasteboard.general.items = [itemVar]
    }
    
    // MARK: - Interpreters for data representations in pasteboard items
    
    static func attributedStringFromRtf(inItem item: [String : Any]) -> NSAttributedString? {
        return ClipboardManager.attributedStringFromRtf(data: item[kUTTypeRTF as String] as? Data)
    }
    
    static func attributedStringFromRtf(data: Data?) -> NSAttributedString? {
        if let rtfData = data {
            do {
                return try NSAttributedString(data: rtfData, options: [.documentType : NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            }
            catch let error as NSError {
                print("Found RTF data, but couldn't convert to NSAttributedString. \(error), \(error.userInfo)")
            }
        }
        return nil
    }
    
    static func attributedStringFromHtml(inItem item: [String : Any]) -> NSAttributedString? {
        return ClipboardManager.attributedStringFromHtml(string: item[kUTTypeHTML as String] as? String)
    }
    
    static func attributedStringFromHtml(string: String?) -> NSAttributedString? {
        if let htmlString = string {
            if let html = htmlString.htmlToAttributed {
                return html
            }
        }
        return nil
    }
    
    static func stringFromPlaintext(inItem item: [String : Any]) -> String? {
        if let utf8Plaintext = item[kUTTypeUTF8PlainText as String] {
            return ClipboardManager.stringFromPlaintext(utf8Plaintext: utf8Plaintext)
        }
        else if let utf16Plaintext = item[kUTTypeUTF16PlainText as String] {
            return ClipboardManager.stringFromPlaintext(utf16Plaintext: utf16Plaintext)
        }
        else if let plaintext = item[kUTTypePlainText as String] as? String {
            return plaintext
        }
        return nil
    }
    
    static func stringFromPlaintext(utf8Plaintext: Any) -> String? {
        if let string = utf8Plaintext as? String {
            return string
        }
        else if let stringData = utf8Plaintext as? Data {
            // will substitute characters it can't decode with the replacement character
            return String(decoding: stringData, as: UTF8.self)
        }
        return nil
    }
    
    static func stringFromPlaintext(utf16Plaintext: Any) -> String? {
        if let string = utf16Plaintext as? String {
            return string
        }
        else if let stringData = utf16Plaintext as? Data {
            // will return nil if it can't decode - String(decoding:as:) doesn't work
            return String(data: stringData, encoding: .utf16)
        }
        return nil
    }
    
    static func imageFromImage(inItem item: [String : Any], maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage? {
        var image: UIImage?
        if let img = item[kUTTypeImage as String] {
            image = getUIImage(from: img)
        }
        else if let png = item[kUTTypePNG as String] {
            image = getUIImage(from: png)
        }
        else if let jpg = item[kUTTypeJPEG as String] {
            image = getUIImage(from: jpg)
        }
        else if let gif = item[kUTTypeGIF as String] {
            image = getUIImage(from: gif)
        }
        else if let tif = item[kUTTypeTIFF as String] {
            image = getUIImage(from: tif)
        }
        else if let bmp = item[kUTTypeBMP as String] {
            image = getUIImage(from: bmp)
        }
        else {
            return nil
        }
        
        if let _ = image {
            return resizeImage(image!, maxWidth: maxWidth, maxHeight: maxHeight)
        }
        return nil
    }
    
    private static func getUIImage(from thing: Any) -> UIImage? {
        if let image = thing as? UIImage {
            return image
        }
        else if let data = thing as? Data {
            return UIImage(data: data)
        }
        else if let url = thing as? URL {
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }
        return nil
    }
    
    static func resizeImage(_ originalImage: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        var image: UIImage = originalImage
        let size: CGSize = image.size
        var scaleFactor: CGFloat?
        if maxWidth > 0 && size.width > maxWidth && (maxHeight == 0 || maxWidth < maxHeight) {
            // scale image down to fit width
            scaleFactor = maxWidth / size.width
        }
        else if maxHeight > 0 && size.height > maxHeight {
            // scale image down to fit height
            scaleFactor = maxHeight / size.height
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
    
    static func attributedStringWithImage(_ image: UIImage) -> NSAttributedString {
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = image
        return NSAttributedString(attachment: attachment)
    }
    
    static func itemFromAttributedString(_ string: NSAttributedString) -> [String : Any] {
        if string.length == 0 { return [:] }
        
        var item: [String : Any] = [:]
        do {
            let rtfData: Data = try string.data(from: NSMakeRange(0, string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf])
            item[kUTTypeRTF as String] = rtfData
            let htmlData: Data = try string.data(from: NSMakeRange(0, string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.html])
            item[kUTTypeHTML as String] = htmlData
        }
        catch let error as NSError {
            print("Error when creating pasteboard item from attributed string: \(error), \(error.userInfo)")
        }
        item[kUTTypeUTF8PlainText as String] = string.string.data(using: .utf8)
        item[kUTTypeUTF16PlainText as String] = string.string.data(using: .utf16)
        item[kUTTypePlainText as String] = string.string
        return item
    }
    
    static func itemFromPlaintext(_ string: String) -> [String : Any] {
        if string.count == 0 { return [:] }
        return [kUTTypePlainText as String : string]
    }
    
    static func stringFromItem(_ item: [String : Any]) -> String? {
        if let plaintext = ClipboardManager.stringFromPlaintext(inItem: item) {
            return plaintext
        }
        else if let rtf = ClipboardManager.attributedStringFromRtf(inItem: item) {
            return rtf.string
        }
        else if let html = ClipboardManager.attributedStringFromHtml(inItem: item) {
            return html.string
        }
        return nil
    }

}
