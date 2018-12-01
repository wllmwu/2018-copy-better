//
//  ClipboardPersistentContainer.swift
//  Clipboard
//
//  Created by Bill Wu on 12/1/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class ClipboardPersistentContainer: NSPersistentContainer {
    
    override class func defaultDirectoryURL() -> URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.williamwu.clipboard")!
    }
    
}
