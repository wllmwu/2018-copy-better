//
//  String+HTML.swift
//  Clips
//
//  Created by Bill Wu on 11/23/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import Foundation
import UIKit

extension String {
    var htmlToAttributed: NSAttributedString? {
        do {
            // default style: 17pt system font
            let stringWithDefaultCss = "<style>html * {font-size:17pt !important;font-family:-apple-system, Helvetica !important;}</style>\(self)"
            guard let data = stringWithDefaultCss.data(using: String.Encoding.utf8) else {
                return nil
            }
            return try NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html, .characterEncoding : String.Encoding.utf8.rawValue], documentAttributes: nil)
        }
        catch {
            print("Error converting HTML string to NSAttributedString: \(error)")
            return nil
        }
    }
}
