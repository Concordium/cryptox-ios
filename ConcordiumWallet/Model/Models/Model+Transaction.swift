//
//  Model+Transaction.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.11.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation


extension Model {
    
    struct Transaction: Codable {
        
        struct DataModel: Codable {
            
            struct ContractAddress: Codable {
                let address: String
                let index: String
                let sub_index: String
            }
            
            struct ContractParams: Codable {
                let param_name: String
                let param_type: String
                let param_value: String
            }
            
            let amount: String
            let contract_address: ContractAddress
            let contract_method: String
            let contract_name: String
            let contract_params: [ContractParams]
            let contract_title: String?
            let expiry: String
            let from: String
            let nonce: String
            let serialized_params: String
            let nrg_limit: Int
        }
        
        let data: DataModel
        let message_type: String
    }
}


extension Model.Transaction.DataModel.ContractAddress {
    
    private enum CodingKeys: String, CodingKey {
        case address
        case index
        case sub_index
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        address = try container.decode(String.self, forKey: .address)
        index = try container.decode(String.self, forKey: .index)
        sub_index = try container.decode(String.self, forKey: .sub_index)
    }
}


extension Model.Transaction.DataModel.ContractParams {
    
    private enum CodingKeys: String, CodingKey {
        case param_name
        case param_type
        case param_value
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        param_name = try container.decode(String.self, forKey: .param_name)
        param_type = try container.decode(String.self, forKey: .param_type)
        param_value = try container.decode(String.self, forKey: .param_value)
    }
}



extension Model.Transaction.DataModel {
    
    private enum CodingKeys: String, CodingKey {
        case amount
        case contract_address
        case contract_method
        case contract_name
        case contract_params
        case contract_title
        case expiry
        case from
        case nonce
        case serialized_params
        case nrg_limit
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        amount = try container.decode(String.self, forKey: .amount)
        contract_address = try container.decode(Model.Transaction.DataModel.ContractAddress.self, forKey: .contract_address)
        contract_method = try container.decode(String.self, forKey: .contract_method)
        contract_name = try container.decode(String.self, forKey: .contract_name)
        contract_params = try container.decode([Model.Transaction.DataModel.ContractParams].self, forKey: .contract_params)
        contract_title = try container.decodeIfPresent(String?.self, forKey: .contract_title) ?? nil

        expiry = try container.decode(String.self, forKey: .expiry)
        from = try container.decode(String.self, forKey: .from)
        nonce = try container.decode(String.self, forKey: .nonce)
        serialized_params = try container.decode(String.self, forKey: .serialized_params)
        let _nrg_limit: String? = try container.decodeIfPresent(String.self, forKey: .nrg_limit)
        nrg_limit = Int(_nrg_limit ?? "100501") ?? 100501
    }
}


extension Model.Transaction {
    
    private enum CodingKeys: String, CodingKey {
        case data
        case message_type
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        data = try container.decode(Model.Transaction.DataModel.self, forKey: .data)
        message_type = try container.decode(String.self, forKey: .message_type)
    }
}
