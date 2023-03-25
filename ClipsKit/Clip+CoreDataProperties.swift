//
//  Clip+CoreDataProperties.swift
//  Clips
//
//  Created by William Wu on 8/12/20.
//  Copyright © 2020 William Wu. All rights reserved.
//
//

import Foundation
import CoreData


extension Clip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Clip> {
        return NSFetchRequest<Clip>(entityName: "Clip")
    }

    @NSManaged public var contents: [String : Any]
    @NSManaged public var isFavorite: Bool
    @NSManaged public var index: Int16
    @NSManaged public var title: String?
    @NSManaged public var deleteDate: Date?
    @NSManaged public var folder: Folder?

}
