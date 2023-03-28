//
//  List+CoreDataProperties.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-11-04.
//
//

import Foundation
import CoreData


extension List {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<List> {
        return NSFetchRequest<List>(entityName: "List")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var villagers: NSSet

}

// MARK: Generated accessors for villagers
extension List {

    @objc(addVillagersObject:)
    @NSManaged public func addToVillagers(_ value: Villager)

    @objc(removeVillagersObject:)
    @NSManaged public func removeFromVillagers(_ value: Villager)

    @objc(addVillagers:)
    @NSManaged public func addToVillagers(_ values: NSSet)

    @objc(removeVillagers:)
    @NSManaged public func removeFromVillagers(_ values: NSSet)

}

extension List : Identifiable {

}
