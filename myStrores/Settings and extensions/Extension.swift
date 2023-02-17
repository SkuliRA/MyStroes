//
//  Extansion.swift
//  myStrores
//
//  Created by Skuli on 11.02.2023.
//

import Foundation

struct Indicators {
    var nameIndicator: String
    var firstIndicator: String
    var secondIndicator: String
    
    init(nameIndicator: String, firstIndicator: String, secondIndicator: String) {
        self.nameIndicator = nameIndicator
        self.firstIndicator = firstIndicator
        self.secondIndicator = secondIndicator
    }
}

// Дата учитывается в универсальном формате UTC
extension Date {
    
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
}

extension Double {
    
    func formatWithSpace() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        
        guard let str = formatter.string(from: self as NSNumber) else { return "" }
        
        return str
    }
    
}
