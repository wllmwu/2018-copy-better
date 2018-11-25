//
//  UILabel+AsyncAttributedText.swift
//  Clipboard
//
//  Created by Bill Wu on 11/24/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func setAttributedTextAsync(_ attributedString: NSAttributedString) {
        DispatchQueue.global(qos: .utility).async {
            let string: NSMutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            string.removeAttribute(.font, range: NSMakeRange(0, string.length))
            
            DispatchQueue.main.async {
                self.attributedText = string
            }
        }
    }
}
