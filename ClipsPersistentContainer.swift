//
//  ClipsPersistentContainer.swift
//  Clips
//
//  Created by Bill Wu on 12/1/18.
//  Copyright © 2018 William Wu. All rights reserved.
//

import UIKit
import CoreData

class ClipsPersistentContainer: NSPersistentContainer {
    
    override class func defaultDirectoryURL() -> URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.williamwu.clips")!
    }
    
}
