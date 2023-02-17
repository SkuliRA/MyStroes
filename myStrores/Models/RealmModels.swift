//
//  Sales.swift
//  myStrores
//
//  Created by Skuli on 10.02.2023.
//

import Foundation
import RealmSwift

class Sales: Object {
   
    @Persisted var storeName: String?
    @Persisted var date: Date?
    @Persisted var art: String?
    @Persisted var name: String?
    @Persisted var size: String?
    @Persisted var price: Double?
    @Persisted var qty: Int?
    @Persisted var autoDisc: Double?
    @Persisted var manDisc: Double?
    @Persisted var bonusDisc: Double?
    @Persisted var ammount: Double?
    
}

class CashInBox: Object {
   
    @Persisted var storeName: String?
    @Persisted var ammount: Double?

    
}
