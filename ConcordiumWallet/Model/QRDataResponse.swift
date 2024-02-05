//
//  QRDataResponse.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

struct QRDataResponse: Codable {
    var site: SiteData
    var ws_conn: String
}

struct SiteData: Codable {
    var title: String
    var description: String
    var icon_link: String
}
