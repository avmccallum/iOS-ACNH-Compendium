//
//  Villager+CoreDataProperties.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-11-07.
//
//

import Foundation
import CoreData


extension Villager {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Villager> {
        return NSFetchRequest<Villager>(entityName: "Villager")
    }

    @NSManaged public var api_id: String
    @NSManaged public var birthDay: Int64
    @NSManaged public var birthdaySaved: Bool
    @NSManaged public var birthMonth: String
    @NSManaged public var catchphrase: String
    @NSManaged public var gender: String
    @NSManaged public var hobby: String
    @NSManaged public var houseImgURI: String
    @NSManaged public var iconURI: String
    @NSManaged public var imgURI: String
    @NSManaged public var name: String
    @NSManaged public var personality: String
    @NSManaged public var quote: String
    @NSManaged public var sign: String
    @NSManaged public var species: String
    @NSManaged public var url: String
    @NSManaged public var lists: NSSet

}

// MARK: Generated accessors for lists
extension Villager {

    @objc(addListsObject:)
    @NSManaged public func addToLists(_ value: List)

    @objc(removeListsObject:)
    @NSManaged public func removeFromLists(_ value: List)

    @objc(addLists:)
    @NSManaged public func addToLists(_ values: NSSet)

    @objc(removeLists:)
    @NSManaged public func removeFromLists(_ values: NSSet)

}

extension Villager : Identifiable {

}
