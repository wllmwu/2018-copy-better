//
//  Clip+CoreDataProperties.swift
//  Clipboard
//
//  Created by Bill Wu on 11/17/18.
//  Copyright © 2018 William Wu. All rights reserved.
//
//

import Foundation
import CoreData


extension Clip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Clip> {
        return NSFetchRequest<Clip>(entityName: "Clip")
    }

    @NSManaged public var contents: [String : Any]
    @NSManaged public var index: Int16
    @NSManaged public var title: String?

}
