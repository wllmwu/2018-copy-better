//
//  ClipboardManager.swift
//  Clipboard
//
//  Created by Bill Wu on 11/14/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit

class ClipboardManager: NSObject {

    private static var clipTitles: [String] = []
    private static var clipContents: [String] = []
    
    static func retrieveData() {
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

}
