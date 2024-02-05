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
    
    var body: some View {
        ZStack {
            Image("account_background").resizable()
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(account.identity?.nickname ?? "")
                                .foregroundColor(Color.deepBlue)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.leading)
                            Text(account.displayName)
                                .foregroundColor(Color.blackAditional)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.leading)
                        }
                        
                        HStack(alignment: .top) {
                            Text(GTU(intValue: account.totalForecastBalance).displayValue())
                                .foregroundColor(Color.deepBlue)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.leading)
                            Text("CCD")
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.ccdBackground)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                HStack {
                    Text("accounts.overview.atdisposal".localized)
                        .foregroundColor(Color.deepBlue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text(GTU(intValue: account.forecastAtDisposalBalance).displayValueWithCCDStroke())
                        .foregroundColor(Color.deepBlue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .background(Color.clear)
        }
        .frame(height: 160)
        .clipShape(RoundedCorner(radius: 24, corners: .allCorners))
    }
}


struct WCAccountCell_Previews: PreviewProvider {
    static var previews: some View {
        WCAccountCell(account: AccountEntity._rlmDefaultValue())
    }
}
