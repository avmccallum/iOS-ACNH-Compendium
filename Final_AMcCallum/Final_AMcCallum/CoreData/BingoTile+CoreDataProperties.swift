//
//  BingoTile+CoreDataProperties.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-11-11.
//
//

import Foundation
import CoreData


extension BingoTile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BingoTile> {
        return NSFetchRequest<BingoTile>(entityName: "BingoTile")
    }

    @NSManaged public var iconURI: String
    @NSManaged public var id: UUID
    @NSManaged public var isPlayed: Bool
    @NSManaged public var name: String
    @NSManaged public var tileValue: Int64

}

extension BingoTile : Identifiable {

}
