//
//  Date+Ent.swift
//  CryptoX
//
//  Created by Max on 07.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

extension Date {
    static func initWithFormat(with dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: dateString)
    }
    
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}
