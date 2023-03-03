//
//  RealmManager.swift
//  myStrores
//
//  Created by Skuli on 13.02.2023.
//

import Foundation
import RealmSwift

// объявим глобальную переменную realm с экземляром Realm
//let realm = try! Realm()


class RealmManager {
    
    static let realm = try! Realm()
    
    static func write(_ entity: Object) {
        try! realm.write {
            realm.add(entity)
        }
    }
    
    // Сработало только такое описание функции, не совсем понял почему
    static func delete<Element: ObjectBase>(_ objects: Results<Element>) {
        try! realm.write {
            realm.delete(objects)
        }
    }
    
    // Функция получает продажи за период
    // dateEnd и storeName не обязательные параметры
    func getSalesForPeriod(dateStart: Date, dateEnd: Date? = nil, storeName: String? = nil) -> (summ: Double, rows: Results<Sales>) {
        
        let realm = try! Realm()
        
        let sales = realm.objects(Sales.self)
        
        // Выберем строки за период
        var rowsPerPeriod = sales.where {
            if storeName == nil && dateEnd == nil {
                return ($0.date > dateStart)
            } else if dateEnd != nil && storeName == nil {
                return ($0.date > dateStart) && ($0.date <= dateEnd)
            } else if dateEnd == nil && storeName != nil {
                return ($0.date > dateStart) && ($0.storeName == storeName)
            } else {
                return ($0.date > dateStart) && ($0.date <= dateEnd) && ($0.storeName == storeName)
            }
        }
        
        // Просуммируем продажи
        var summ = 0.00
        for row in rowsPerPeriod {
            summ += row.ammount ?? 0.00
        }
        
        //rowsPerPeriod = rowsPerPeriod.sorted(byKeyPath: "date, storeName")
        rowsPerPeriod = rowsPerPeriod.sorted(by: [SortDescriptor(keyPath: "date"),
                                                  SortDescriptor(keyPath: "storeName")])
        
        return (summ, rowsPerPeriod)
    }
}
