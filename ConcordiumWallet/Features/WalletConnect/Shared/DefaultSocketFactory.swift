//
//  DefaultSocketFactory.swift
//  Mock
//
//  Created by Maksym Rachytskyy on 18.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation
import Starscream
import Web3Wallet

extension WebSocket: WebSocketConnecting { }

struct DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return WebSocket(url: url)
    }
}
