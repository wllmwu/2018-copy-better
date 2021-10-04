//
//  NSAttributedString+HTML.swift
//  ClipsKit
//
//  Created by Bill Wu on 10/3/21.
//  Copyright © 2021 William Wu. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {
    public var attributedToHTML: String? {
        do {
            let htmlData = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
            return String.init(data: htmlData, encoding: .utf8)
        }
        catch {
            print("Error converting NSAttributedString to HTML string: \(error)")
            return nil
        }
    }
}
