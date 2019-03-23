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
     * rtfd
     * rtf
     * html
     * plaintext (utf8, utf16, none)
     * image (png, jpg, gif, tif, bmp)
     */
    
    // MARK: - Interface with system pasteboard
    
    /**
     Retrieves the first item of the general pasteboard as an item dictionary.
     */
    static func retrieveFromPasteboard() -> [String : Any] {
        let pasteboard: UIPasteboard = UIPasteboard.general
        if let item = pasteboard.items.first {
            var newItem: [String : Any] = [:]
            if let rtfd = item[kUTTypeRTFD as String] {
                newItem[kUTTypeRTFD as String] = rtfd
            }
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
    
    /**
     Replaces the general pasteboard's current items with the given item dictionary.
     */
    static func copyToPasteboard(item: [String : Any]) {
        var itemVar: [String : Any] = item
        itemVar.removeValue(forKey: kUTTypeRTFD as String)
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
    
    /**
     Looks for data represented by the type identifier kUTTypeRTFD in the given item dictionary, and attempts to convert it to an NSAttributedString.
     */
    static func attributedStringFromRtfd(inItem item: [String : Any]) -> NSAttributedString? {
        return ClipboardManager.attributedStringFromRtfd(data: item[kUTTypeRTFD as String] as? Data)
    }
    
    /**
     Attempts to convert the given Data to an NSAttributedString with the document type RTFD.
     */
    static func attributedStringFromRtfd(data: Data?) -> NSAttributedString? {
        if let rtfdData = data {
            do {
                return try NSAttributedString(data: rtfdData, options: [.documentType : NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
            }
            catch let error as NSError {
                print("Found RTFD data, but couldn't convert to NSAttributedString. \(error), \(error.userInfo)")
            }
        }
        return nil
    }
    
    /**
     Looks for data represented by the type identifier kUTTypeRTF in the given item dictionary, and attempts to convert it to an NSAttributedString.
     */
    static func attributedStringFromRtf(inItem item: [String : Any]) -> NSAttributedString? {
        return ClipboardManager.attributedStringFromRtf(data: item[kUTTypeRTF as String] as? Data)
    }
    
    /**
     Attempts to convert the given Data to an NSAttributedString with the document type RTF.
     */
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
    
    /**
     Looks for data represented by the type identifier kUTTypeHTML in the given item dictionary, and attempts to convert it to an NSAttributedString.
     */
    static func attributedStringFromHtml(inItem item: [String : Any]) -> NSAttributedString? {
        return ClipboardManager.attributedStringFromHtml(string: item[kUTTypeHTML as String] as? String)
    }
    
    /**
     Attempts to convert the given String to an NSAttributedString by interpreting the String as HTML text.
     */
    static func attributedStringFromHtml(string: String?) -> NSAttributedString? {
        if let htmlString = string {
            if let html = htmlString.htmlToAttributed {
                return html
            }
        }
        return nil
    }
    
    /**
     Looks for data represented by the type identifiers kUTTypeUTF8PlainText, kUTTypeUTF16PlainText, or kUTTypePlainText in the given item dictionary, and attempts to convert it to a String.
     */
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
    
    /**
     Attempts to convert the given object to a String by interpreting it as UTF8-encoded text.
     */
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
    
    /**
     Attempts to convert the given object to a String by interpreting it as UTF16-encoded text.
     */
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
    
    /**
     Looks for data represented by the type identifiers kUTTypeImage, kUTTypePNG, kUTTypeJPEG, kUTTypeGIF, kUTTypeTIFF, or kUTTypeBMP in the given item dictionary, and attempts to convert it to a UIImage. The returned image is scaled to the given maximum width and/or maximum height, if their value is not 0 and not greater than the original width and/or height.
     - Parameter maxWidth: The maximum point width of the returned image. If this value is 0, the image will not be scaled to fit a maximum width.
     - Parameter maxHeight: The maximum point height of the returned image. If this value is 0, the image will not be scaled to fit a maximum height.
     */
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
    
    /**
     Attempts to convert the given object to a UIImage by interpreting it as a UIImage, Data, or a URL.
     */
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
    
    /**
     Scales an image down to the given maximum width and/or maximum height, if their value is not 0 and not greater than the original width and/or height.
     - Parameter maxWidth: The maximum point width of the returned image. If this value is 0, the image will not be scaled to fit a maximum width.
     - Parameter maxHeight: The maximum point height of the returned image. If this value is 0, the image will not be scaled to fit a maximum height.
     */
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
    
    /**
     Creates an NSAttributedString consisting of one attachment containing the given image.
     */
    static func attributedStringWithImage(_ image: UIImage) -> NSAttributedString {
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = image
        return NSAttributedString(attachment: attachment)
    }
    
    /**
     Creates a pasteboard item dictionary from the given NSAttributedString. The item will include whichever data representations possible with the type identifiers kUTTypeRTFD, kUTTypeRTF, kUTTypeHTML, kUTTypeUTF8PlainText, kUTTypeUTF16PlainText, and kUTTypePlainText.
     */
    static func itemFromAttributedString(_ string: NSAttributedString) -> [String : Any] {
        if string.length == 0 { return [:] }
        
        var item: [String : Any] = [:]
        do {
            if string.containsAttachments(in: NSMakeRange(0, string.length)) {
                let rtfdData: Data = try string.data(from: NSMakeRange(0, string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtfd])
                item[kUTTypeRTFD as String] = rtfdData
            }
        }
        catch let error as NSError {
            print("Error when creating pasteboard item RTFD representation from attributed string: \(error), \(error.userInfo)")
        }
        do {
            let rtfData: Data = try string.data(from: NSMakeRange(0, string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf])
            item[kUTTypeRTF as String] = rtfData
        }
        catch let error as NSError {
            print("Error when creating pasteboard item RTF representation from attributed string: \(error), \(error.userInfo)")
        }
        do {
            let htmlData: Data = try string.data(from: NSMakeRange(0, string.length), documentAttributes: [.documentType : NSAttributedString.DocumentType.html])
            item[kUTTypeHTML as String] = htmlData
        }
        catch let error as NSError {
            print("Error when creating pasteboard item HTML representation from attributed string: \(error), \(error.userInfo)")
        }
        item[kUTTypeUTF8PlainText as String] = string.string.data(using: .utf8)
        item[kUTTypeUTF16PlainText as String] = string.string.data(using: .utf16)
        item[kUTTypePlainText as String] = string.string
        return item
    }
    
    /**
     Creates a pasteboard item from the given String. If the String has length greater than 0, the item will include a data representation with the type identifier kUTTypePlainText.
     */
    static func itemFromPlaintext(_ string: String) -> [String : Any] {
        if string.count == 0 { return [:] }
        return [kUTTypePlainText as String : string]
    }
    
    /**
     Looks for text contained in the given item dictionary, as plaintext, RTFD, RTF, or HTML.
     */
    static func stringFromItem(_ item: [String : Any]) -> String? {
        if let plaintext = ClipboardManager.stringFromPlaintext(inItem: item) {
            return plaintext
        }
        else if let rtfd = ClipboardManager.attributedStringFromRtfd(inItem: item) {
            return rtfd.string
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
