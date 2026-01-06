//
//  WCAccountCell.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 19.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI

struct WCAccountCell: View {
    var account: AccountEntity
    var shouldShowBalance: Bool = false
    
    var body: some View {
        ZStack {
            Image("account_background").resizable()
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(account.name ?? "")
                                .foregroundColor(.blackMain)
                                .font(.system(size: 16, weight: .bold))
                                .multilineTextAlignment(.leading)
                            Text(account.displayName)
                                .foregroundColor(.deepBlue)
                                .font(.system(size: 16, weight: .regular))
                                .multilineTextAlignment(.leading)
                        }
                        if let identity = account.identity?.nickname {
                            Text(identity)
                                .font(.satoshi(size: 16, weight: .regular))
                                .foregroundColor(.blackMain)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                if shouldShowBalance {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance: \(balanceDisplayValue(account.forecastBalance)) CCD")
                            .font(.satoshi(size: 16, weight: .bold))
                            .foregroundStyle(.blackMain)
                        Text("At Disposal: \(balanceDisplayValue(account.atDisposalBalance)) CCD")
                            .font(.satoshi(size: 16, weight: .regular))
                            .foregroundStyle(.blackMain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .background(Color.clear)
        }
        .clipShape(RoundedCorner(radius: 24, corners: .allCorners))
    }
    
    func balanceDisplayValue(_ balance: Int?) -> String {
        let gtuValue = GTU(intValue: balance)
        return gtuValue?.displayValueWithTwoNumbersAfterDecimalPoint() ?? "0.00"
    }
}


struct WCAccountCell_Previews: PreviewProvider {
    static var previews: some View {
        WCAccountCell(account: AccountEntity._rlmDefaultValue())
    }
}
