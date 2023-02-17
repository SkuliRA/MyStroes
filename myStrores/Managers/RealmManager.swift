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
}
