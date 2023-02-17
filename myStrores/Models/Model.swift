//
//  Model.swift
//  myStrores
//
//  Created by Skuli on 08.02.2023.
//

import Foundation

// MARK: - Welcome
struct Tables: Codable {
    let tableName: String
    let fromStoreName: String
    let dateStart: Date
    let dateEnd: Date
    let cashAtBox: Double
    let rows: [Row]
}

// MARK: - Row
struct Row: Codable {
    let storeName: String
    let date: Date
    let art, name, size: String
    let qty: Int
    let price: Double
    let autoDisc, manDisc, bonusDisc: Double
    let ammount: Double
}

struct Res: Codable {
    let href: String
}
