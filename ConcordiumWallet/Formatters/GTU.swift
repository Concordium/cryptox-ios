//
// Created by Concordium on 21/04/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation

struct Asset {
    let digits: Int
}

struct GTU: Codable {
    static let conversionFactor: Int = 1000000
    static let maximumFractionDigits: Int = 6
    
    /// Useful for comparing against 0
    static let zero: GTU = GTU(intValue: 0)
    static let max: GTU = GTU(intValue: .max)
    static let groupingSeparator = ","
    static let decimalSeparator = "."
    private(set) var intValue: Int

    init(displayValue: String) {
        if displayValue.count == 0 {
            intValue = 0
            return
        }
        
        let displayValue = displayValue.replacingOccurrences(of: GTU.groupingSeparator, with: "")

        let wholePart = displayValue.unsignedWholePart
        let fractionalPart = displayValue.fractionalPart(precision: GTU.maximumFractionDigits)
        let isNegative = displayValue.isNegative
        intValue = GTU.wholeAndFractionalValueToInt(wholeValue: wholePart, fractionalValue: fractionalPart, isNegative: isNegative)
    }

    init(intValue: Int) {
        self.intValue = intValue
    }

    init?(intValue: Int?) {
        guard let intValue = intValue else { return nil }
        self.intValue = intValue
    }
    
    // GTU is encoded as a string containing the int value
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        let stringValue = try container.decode(String.self)
        
        guard let intValue = Int(stringValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(stringValue) is not a valid GTU amount")
        }
        
        self.init(intValue: intValue)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        try container.encode(String(intValue))
    }
    
    func displayValueWithCCDStroke() -> String {
        let minimumFractionDigits = 2

        var str = GTU.intValueToUnsignedIntString(intValue,
                                                  minimumFractionDigits: minimumFractionDigits,
                                                  maxFractionDigits: GTU.maximumFractionDigits)
        
        // Unicode for "Latin Capital Letter G with Stroke" = U+01E4
        if intValue < 0 {
            str = "- \(str) CCD"
        } else {
            str = "\(str) CCD"
        }
        return str
    }

    func displayValueWithGStroke() -> String {
        let minimumFractionDigits = 2

        var str = GTU.intValueToUnsignedIntString(intValue,
                                                  minimumFractionDigits: minimumFractionDigits,
                                                  maxFractionDigits: GTU.maximumFractionDigits)
        
        // Unicode for "Latin Capital Letter G with Stroke" = U+01E4
        if intValue < 0 {
            str = "-Ͼ\(str)"
        } else {
            str = "Ͼ\(str)"
        }
        return str
    }

    func displayValue() -> String {
        let minimumFractionDigits = 2
        var stringValue = GTU.intValueToUnsignedIntString(intValue,
                                                          minimumFractionDigits: minimumFractionDigits,
                                                          maxFractionDigits: GTU.maximumFractionDigits)
        if intValue < 0 {
            stringValue = "-\(stringValue)"
        }
        return stringValue
    }
    
    func displayValueWithTwoNumbersAfterDecimalPoint() -> String {
        let minimumFractionDigits = 2
        var stringValue = GTU.intValueToUnsignedIntString(intValue,
                                                          minimumFractionDigits: minimumFractionDigits,
                                                          maxFractionDigits: GTU.maximumFractionDigits)
        if intValue < 0 {
            stringValue = "- \(stringValue)"
        }
        
        // Split the input into the whole part and fractional part
        let components = stringValue.split(separator: ".", maxSplits: 1)
        guard components.count == 2 else {
            // No fractional part, return as is
            return stringValue
        }
        
        let wholePart = components[0]
        var fractionalPart = components[1]
        
        // Remove trailing values while respecting `minimumFractionDigits`
        while fractionalPart.count > minimumFractionDigits {
            fractionalPart.removeLast()
        }
        
        // Return the adjusted string
        return fractionalPart.isEmpty ? String(wholePart) : "\(wholePart).\(fractionalPart)"
    }
    
    static func isValid(displayValue: String) -> Bool {
        let displayValue = displayValue.replacingOccurrences(of: groupingSeparator, with: "")
        return displayValue.unsignedWholePart <= (Int.max - 999999)/1000000 && displayValue.matches(regex: "^[0-9]*[\\.,]?[0-9]{0,6}$")
    }

    private static func wholeAndFractionalValueToInt(wholeValue: Int, fractionalValue: Int, isNegative: Bool) -> Int {
        return (wholeValue * conversionFactor + fractionalValue) * (isNegative ? -1 : 1)
    }

    private static func intValueToUnsignedIntString(_ value: Int, minimumFractionDigits: Int, maxFractionDigits: Int) -> String {
        let absValue = abs(value)
        let wholeValueString = String(absValue / conversionFactor)
        var fractionVal = String(absValue % conversionFactor)
        
        // make it 6 digits
        let appendedZeros = String(conversionFactor).count - 1 - fractionVal.count
        if appendedZeros > 0 {
            for _ in 0..<appendedZeros {
                fractionVal = "0" + fractionVal
            }
        }
        
        // remove trailing zeros
        let length = min(fractionVal.count, maximumFractionDigits)
        var removed = false
        for i in stride(from: 0, to: -length + minimumFractionDigits, by: -1) {
            if fractionVal[fractionVal.index(fractionVal.endIndex, offsetBy: i - 1)] != "0" {
                fractionVal = String(fractionVal[..<fractionVal.index(fractionVal.endIndex, offsetBy: i)])
                removed = true
                break
            }
        }
        if !removed {
            fractionVal = String(fractionVal[..<fractionVal.index(fractionVal.endIndex, offsetBy: -length + minimumFractionDigits)])
        }
        
        return groups(string: wholeValueString, size: 3).joined(separator: groupingSeparator) + decimalSeparator + fractionVal
    }
    
    /// Splits base-10 integer String into groups of `size` characters, starting from the end of string.
    ///
    /// For example:
    ///
    ///     groups(string: "1000", size: 3) // ["1", "000"]
    ///     groups(string: "1000", size: 2) // ["10", "00"]
    ///     groups(string: "1", size: 3) // ["1"]
    ///
    /// - Parameters:
    ///   - string: A string to split
    ///   - size: maximum size of the group
    /// - Returns: Groups of characters. The first item's length might be less than `size`.
    private static func groups(string: String, size: Int) -> [String] {
        if string.count <= size { return [string] }
        // example result: [0, 3, 6, 9, 10]
        let groupBoundaries = stride(from: 0, to: string.count, by: size) + [string.count]
        // example result: [(9..<10), (6..<9), (3..<6), (0..<3)]
        let ranges = (0..<groupBoundaries.count - 1).map { groupBoundaries[$0]..<groupBoundaries[$0 + 1] }.reversed()
        // ranges used as offsets from the end of the string to get substrings:
        // example result: ["1", "000", "000", "000"]
        let groups = ranges.map { range -> String in
            let lowerIndex = string.index(string.endIndex, offsetBy: -range.upperBound)
            let upperIndex = string.index(string.endIndex, offsetBy: -range.lowerBound)
            return String(string[lowerIndex..<upperIndex])
        }
        return groups
    }
}

extension GTU: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(intValue)
    }

    public static func == (lhs: GTU, rhs: GTU) -> Bool {
        lhs.intValue == rhs.intValue
    }
}

extension GTU: Comparable {
    static func < (lhs: GTU, rhs: GTU) -> Bool {
        lhs.intValue < rhs.intValue
    }
}

extension GTU: Numeric {
    var magnitude: UInt {
        intValue.magnitude
    }
    
    init?<T>(exactly source: T) where T: BinaryInteger {
        self.init(intValue: Int(exactly: source))
    }
    
    init(integerLiteral value: IntegerLiteralType) {
        self.init(intValue: value)
    }
    
    static func + (lhs: GTU, rhs: GTU) -> GTU {
        return GTU(intValue: lhs.intValue + rhs.intValue)
    }
    
    static func * (lhs: GTU, rhs: GTU) -> GTU {
        return GTU(intValue: lhs.intValue * rhs.intValue)
    }
    
    static func *= (lhs: inout GTU, rhs: GTU) {
        lhs.intValue *= rhs.intValue
    }
    
    static func - (lhs: GTU, rhs: GTU) -> GTU {
        return GTU(intValue: lhs.intValue - rhs.intValue)
    }
}
