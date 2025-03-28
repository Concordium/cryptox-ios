//
//  DecimalNumberTextField.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import BigInt

struct DecimalNumberTextField: View {
    @Binding private var decimalValue: BigDecimal
    @State private var textFieldText: String = ""
    
    @Binding var fraction: Int
    private var ticker: String?
    
    private let placeholder: String = "0"
    private var decimalNumberFormatter: DecimalNumberFormatter
    private var decimalSeparator: Character { decimalNumberFormatter.decimalSeparator }
    private var groupingSeparator: Character { decimalNumberFormatter.groupingSeparator }
    
    init(
        decimalValue: Binding<BigDecimal>,
        fraction: Binding<Int>,
        ticker: String? = nil
    ) {
        _fraction = fraction
        _decimalValue = decimalValue
        self.ticker = ticker
        self.decimalNumberFormatter = .init(maximumFractionDigits: fraction.wrappedValue)
        self._textFieldText = decimalValue.wrappedValue.value == .zero ? State(initialValue: "") :  State(initialValue: TokenFormatter().plainString(from: decimalValue.wrappedValue, decimalSeparator: "."))
    }
    
    private var textFieldProxyBinding: Binding<String> {
        Binding<String>(
            get: { decimalNumberFormatter.format(value: textFieldText) },
            set: { updateValues(with: $0) }
        )
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if textFieldText.isEmpty {
                HStack(spacing: 8) {
                    Text("0")
                        .font(.plexSans(size: 55, weight: .medium))
                        .dynamicTypeSize(.xSmall ... .xxLarge)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .modifier(RadialGradientForegroundStyleModifier())
                        .opacity(0.5)
                    if let ticker {
                        Text(ticker)
                            .font(.plexSans(size: 55, weight: .medium))
                            .dynamicTypeSize(.xSmall ... .xxLarge)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .modifier(RadialGradientForegroundStyleModifier())
                            .opacity(0.5)
                    }
                        
                    Spacer()
                }
            }
                TextField(placeholder, text: binding(for: $decimalValue))
                    .keyboardType(.decimalPad)
                    .font(.plexSans(size: 55, weight: .medium))
                    .dynamicTypeSize(.xSmall ... .xxLarge)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .opacity(1)
                    .foregroundColor(.clear)
                    .overlay(
                        RadialGradient(
                            colors:
                                [Color(red: 0.93, green: 0.85, blue: 0.75),
                                 Color(red: 0.64, green: 0.6, blue: 0.89),
                                 Color(red: 0.62, green: 0.95, blue: 0.92)]
                            ,
                            center: .topLeading,
                            startRadius: 50,
                            endRadius: 300
                        )
                        .allowsHitTesting(false)
                        .saturation(2)
                        .mask(alignment: .leading, {
                            HStack(spacing: 8) {
                                
                                Text(textFieldText.isEmpty ? " " : textFieldText)
                                    .font(.plexSans(size: 55, weight: .medium))
                                    .dynamicTypeSize(.xSmall ... .xxLarge)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                                    .allowsHitTesting(false)
                                
                                if let ticker, !textFieldText.isEmpty {
                                    Text(ticker)
                                        .font(.plexSans(size: 55, weight: .medium))
                                        .dynamicTypeSize(.xSmall ... .xxLarge)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                        .modifier(RadialGradientForegroundStyleModifier())
                                    Spacer()
                                }
                            }
                        })
                    )
                    .onChange(of: decimalValue) { newDecimalValue in
                        if !(newDecimalValue.value == 0) {
                            self.textFieldText = TokenFormatter().plainString(from: newDecimalValue, decimalSeparator: ".")
                        } else if newDecimalValue == .zero {
                            self.textFieldText = ""
                        }
                    }
        }
        .frame(height: 30)
        .onChange(of: fraction) { newValue in
            decimalNumberFormatter.update(maximumFractionDigits: newValue)
        }
    }
    
    private func binding(for value: Binding<BigDecimal>) -> Binding<String> {
        return Binding<String>(
            get: { self.textFieldText },
            set: { newValue in
                let formattedValue = self.formatString(newValue)
                
                self.textFieldText = decimalNumberFormatter.format(value: formattedValue)
                
                if formattedValue.isEmpty {
                    value.wrappedValue = BigDecimal.zero(value.wrappedValue.precision)
                }
                else if let token = TokenFormatter().number(from: formattedValue, precision: fraction, decimalSeparators: ".") {
                    value.wrappedValue = token
                    print(TokenFormatter().string(from: token))
                }
            }
        )
    }
    
    private func formatString(_ newValue: String) -> String {
        var numberString = newValue
        
        if numberString.last == "," {
            numberString.removeLast()
            numberString.append(".")
        }
        
        if let decimalIndex = numberString.firstIndex(of: decimalSeparator) {
            let fractionalPart = numberString[decimalIndex..<numberString.endIndex]
            let maximumFractionLength = fraction + 1
            if fractionalPart.count > maximumFractionLength {
                numberString = String(numberString[..<numberString.index(decimalIndex, offsetBy: maximumFractionLength)])
            }
        }
        
        // If user start enter number with `decimalSeparator` add zero before it
        if numberString == String(decimalSeparator) {
            numberString.insert("0", at: numberString.startIndex)
        }
        
        // If user double tap on zero, add `decimalSeparator` to continue enter number
        if numberString == "00" {
            numberString.insert(decimalSeparator, at: numberString.index(before: numberString.endIndex))
        }
        
        // If text already have `decimalSeparator` remove last one
        if numberString.last == decimalSeparator,
           numberString.prefix(numberString.count - 1).contains(decimalSeparator) {
            numberString.removeLast()
        }
        
        // Remove thousands separator, so we can convert this to BigInt
        if numberString.contains(groupingSeparator) {
            numberString = numberString.replacingOccurrences(of: "\(groupingSeparator)", with: "")
        }
        return numberString
    }
    
    private func updateValues(with newValue: String) {
        var numberString = formatString(newValue)

        // Format the string and reduce the tail
        numberString = decimalNumberFormatter.format(value: numberString)
        
        textFieldText = numberString
    }
}

class DecimalNumberFormatter {
    public var maximumFractionDigits: Int { numberFormatter.maximumFractionDigits }
    public var decimalSeparator: Character { Character(numberFormatter.decimalSeparator) }
    public var groupingSeparator: Character { Character(numberFormatter.groupingSeparator) }
    
    private let numberFormatter: NumberFormatter
    
    init(
        numberFormatter: NumberFormatter = NumberFormatter(),
        maximumFractionDigits: Int
    ) {
        self.numberFormatter = numberFormatter
        
        numberFormatter.roundingMode = .down
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0 // Just for case
        numberFormatter.maximumFractionDigits = maximumFractionDigits
        numberFormatter.groupingSeparator = ","
        numberFormatter.decimalSeparator = "."
    }
    
    func update(maximumFractionDigits: Int) {
        numberFormatter.maximumFractionDigits = maximumFractionDigits
    }
    
    // MARK: - Formatted
    
    public func format(value: String) -> String {
        // Exclude unnecessary logic
        guard !value.isEmpty else {
            return ""
        }
        
        // If string contains decimalSeparator will format it separately
        if value.contains(decimalSeparator) {
            return formatIntegerAndFractionSeparately(string: value)
        }
        
        return formatInteger(value: value)
    }
    
    public func format(value: Decimal) -> String {
        return format(value: mapToString(decimal: value))
    }
    
    // MARK: - Mapping
    
    public func mapToString(decimal: Decimal) -> String {
        let stringNumber = (decimal as NSDecimalNumber).stringValue
        return stringNumber.replacingOccurrences(of: ".", with: String(decimalSeparator))
    }
    
    public func mapToDecimal(string: String) -> Decimal? {
        if string.isEmpty {
            return nil
        }
        
        // Convert formatted string to correct decimal number
        let formattedValue = string
            .replacingOccurrences(of: String(groupingSeparator), with: "")
            .replacingOccurrences(of: String(decimalSeparator), with: ".")
        
        // We can't use here the NumberFormatter because it work with the NSNumber
        // And NSNumber is working wrong with ten zeros and one after decimalSeparator
        // Eg. NumberFormatter.number(from: "0.00000000001") will return "0.000000000009999999999999999"
        // Like is NSNumber(floatLiteral: 0.00000000001) will return "0.000000000009999999999999999"
        if let value = Decimal(string: formattedValue) {
            return value
        }
        
        assertionFailure("String isn't a correct Number")
        return .zero
    }
}

// MARK: - Private

private extension DecimalNumberFormatter {
    func formatIntegerAndFractionSeparately(string: String) -> String {
        guard let commaIndex = string.firstIndex(of: decimalSeparator) else {
            return string
        }
        
        let beforeComma = String(string[string.startIndex ..< commaIndex])
        var afterComma = string[commaIndex ..< string.endIndex]
        
        // Check to maximumFractionDigits and reduce if needed
        let maximumWithComma = maximumFractionDigits + 1
        if afterComma.count > maximumWithComma {
            let lastAcceptableIndex = afterComma.index(afterComma.startIndex, offsetBy: maximumFractionDigits)
            afterComma = afterComma[afterComma.startIndex ... lastAcceptableIndex]
        }
        
        return format(value: beforeComma) + afterComma
    }
    
    /// In this case the NumberFormatter works fine ONLY with integer values
    /// We can't trust it because it reduces fractions to 13 characters
    private func formatInteger(value: String) -> String {
        assert(!value.contains(decimalSeparator))
        
        if let decimal = mapToDecimal(string: value) {
            return numberFormatter.string(from: decimal as NSDecimalNumber) ?? ""
        }
        
        return value
    }
}
