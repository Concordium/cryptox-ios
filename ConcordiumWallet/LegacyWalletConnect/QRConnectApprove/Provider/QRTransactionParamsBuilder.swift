//
//  QRTransactionParamsBuilder.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 03.11.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation
import SwiftUI


class QRTransactionParamsBuilder {
    
    enum ParamKeys {
        // key, default value
        case hex(String, String)
        case url(String,String)
    }
    
    func build(from model: Model.Transaction, index: String) -> String {
        let contractName = model.data.contract_name
        let contractMethod = model.data.contract_method
        let params = model.data.contract_params
        switch index {
        case "93" where contractName.contains("inventory") &&  contractMethod.contains("create") :
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc721/inventory/README.md
            return get(params, keys: [.hex("token_id", ""),
                                      .hex("value", "00"),
                                      .hex("royalties", ""),
                                      .url("url", "")])
            
        case "93" where contractName.contains("inventory") &&  contractMethod.contains("create") :
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc721/inventory/README.md
            return get(params, keys: [.hex("token_id", ""),
                                      .hex("value", "00"),
                                      .hex("royalties", ""),
                                      .url("url", "")])
            
        case "94" where contractName.contains("trader") &&  contractMethod.contains("create_and_sell"):
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc721/trader_fixed_price_with_fee/README.md
            return get(params, keys: [.hex("token_id", ""),
                                      .hex("royalties", "00"),
                                      .url("url",""),
                                      .hex("amount", "00")])
            
        case "94" where contractName.contains("trader") &&  contractMethod.contains("buy"):
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc721/trader_fixed_price_with_fee/README.md
            return get(params, keys: [.hex("token_id", "")])
            
        case "95" where contractName.contains("trader") &&  contractMethod.contains("create_and_sell"):
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc721/trader_auction/README.md
            return get(params, keys: [.hex("token_id", ""),
                                      .hex("royalties", "00"),
                                      .url("url",""),
                                      .hex("price", "00"),
                                      .hex("to_time", "00"),
                                      .hex("bid_additional_time", "")])
            
        case "95" where contractName.contains("trader") &&  contractMethod.contains("buy"):
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc721/trader_auction/README.md
            return get(params, keys: [.hex("token_id", "")])
            
        case "99":
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc1155/trader_auction/README.md
            return get(params, keys: [])
        case "96":
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc1155/inventory/README.md
            return get(params, keys: [])
        case "98":
            // https://gitlab.com/dragonfly-bit/concordium-smart-contract/-/blob/master/v2/erc1155/trader_fixed_price_with_fee/README.md
            return get(params, keys: [])
           
        default:
            break
        }
        
        return ""
    }
}



extension QRTransactionParamsBuilder {
    
    func get(_ params: [Model.Transaction.DataModel.ContractParams], keys: [ParamKeys]) -> String {
        
        var string: String = ""
        for key in keys {
            switch key {
            case .hex(let key, let def):
                string += getHex(params: params, key: key, def: def)
            case .url(let key, let def):
                string += getUrl(params: params, key: key, def: def)
            }
        }
        
        return string
    }
    
    func getHex(params: [Model.Transaction.DataModel.ContractParams], key: String, def: String) -> String {
        guard let value = params.filter({ $0.param_name == key }).first?.param_value else { return def }
        guard let origUint64 = Int(value) else { return def }
        return String(origUint64.byteSwapped, radix: 16).leftPadding(toLength: 16, withPad: "0")
    }
    
    func getUrl(params: [Model.Transaction.DataModel.ContractParams], key: String, def: String) -> String {
        guard let url = params.filter({ $0.param_name == key }).first?.param_value else { return def }
        return url.count.data.hexEncodedString() + Data(url.utf8).hexEncodedString()
    }
}
