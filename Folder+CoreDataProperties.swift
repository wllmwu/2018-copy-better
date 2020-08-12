//
//  Folder+CoreDataProperties.swift
//  Clips
//
//  Created by Bill Wu on 8/12/20.
//  Copyright © 2020 William Wu. All rights reserved.
//
//

import Foundation
import CoreData


extension Folder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }

    @NSManaged public var id: Int32
    @NSManaged public var index: Int16
    @NSManaged public var name: String?
    @NSManaged public var clips: NSSet?
    @NSManaged public var subfolders: NSSet?
    @NSManaged public var superfolder: Folder?

}

// MARK: Generated accessors for clips
extension Folder {

    @objc(addClipsObject:)
    @NSManaged public func addToClips(_ value: Clip)

    @objc(removeClipsObject:)
    @NSManaged public func removeFromClips(_ value: Clip)

    @objc(addClips:)
    @NSManaged public func addToClips(_ values: NSSet)

    @objc(removeClips:)
    @NSManaged public func removeFromClips(_ values: NSSet)

}

// MARK: Generated accessors for subfolders
extension Folder {

    @objc(addSubfoldersObject:)
    @NSManaged public func addToSubfolders(_ value: Folder)

    @objc(removeSubfoldersObject:)
    @NSManaged public func removeFromSubfolders(_ value: Folder)

    @objc(addSubfolders:)
    @NSManaged public func addToSubfolders(_ values: NSSet)

    @objc(removeSubfolders:)
    @NSManaged public func removeFromSubfolders(_ values: NSSet)

}
