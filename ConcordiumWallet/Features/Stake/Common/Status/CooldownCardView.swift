//
//  CooldownCardView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct CooldownCardView: View {
    private var cooldown: AccountCooldown
    
    init(cooldown: AccountCooldown) {
        self.cooldown = cooldown
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inactive Stake")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundColor(.white)
            
            Text("You don’t receive rewards from this part of stake now, this amount will be at disposal after cooldown period.")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundColor(Color.MineralBlue.blueish3.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(GTU(intValue: Int(cooldown.amount))?.displayValue() ?? "")
                    .font(.satoshi(size: 22, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("Cooldown time:")
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundColor(Color.MineralBlue.blueish3.opacity(0.5))
                Spacer()
                Text("\(calculateCooldownTime(from: cooldown.timestamp))")
                    .foregroundColor(.white)
                    .font(.satoshi(size: 12, weight: .regular))
                Text("days left")
                    .font(.satoshi(size: 12, weight: .regular))
                    .foregroundColor(Color.MineralBlue.blueish3.opacity(0.5))
            }
        }
        .padding()
        .background(.grey3.opacity(0.3))
        .cornerRadius(12)
        .padding(.top, 10)
    }
    
    func calculateCooldownTime(from timestamp: Int) -> Int {
        let millisecondsInADay: UInt64 = 1000 * 60 * 60 * 24
        let endDate = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        let daysToEndCooldown = Int((endDate.millisecondsSince1970 - Date.now.millisecondsSince1970) / millisecondsInADay)
        return daysToEndCooldown == 0 ? 1 : daysToEndCooldown
    }
}
