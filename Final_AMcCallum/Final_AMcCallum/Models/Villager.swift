//
//  Villager.swift
//  Final_AMcCallum
//
//  Created by Ashley Mccallum on 2022-10-21.
//

import Foundation

struct VillagerModel: Codable {
    var id: String
    var url: String
    var name: String
    var image_url: String
    var species: String
    var personality: String
    var gender: String
    var birthday_month: String
    var birthday_day: String
    var sign: String
    var nh_details: NHDetails
}

struct NHDetails: Codable {
    var icon_url: String
    var quote: String
    var catchphrase: String
    var hobby: String
    var house_exterior_url: String
}

struct Results: Codable {
    var results: [VillagerModel]
}

enum Section {
    case main
}
