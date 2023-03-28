//
//  Game+CoreDataProperties.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-11-11.
//
//

import Foundation
import CoreData


extension Game {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game")
    }

    @NSManaged public var mode: String
    @NSManaged public var score: Int64

}

extension Game : Identifiable {

}
