//
//  StakeService.swift
//  Mock
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation
import Combine

protocol StakeServiceProtocol {
    func getBakerPool(bakerId: Int) -> AnyPublisher<BakerPoolResponse, Error>
    func getPassiveDelegation() -> AnyPublisher<PassiveDelegation, Error>
    func getChainParameters() -> AnyPublisher<ChainParametersResponse, Error>
    func generateBakerKeys() -> Result<GeneratedBakerKeys, Error>
}

class StakeService: StakeServiceProtocol {
    let networkManager: NetworkManagerProtocol
    let mobileWallet: MobileWalletProtocol
    
    init(networkManager: NetworkManagerProtocol, mobileWallet: MobileWalletProtocol) {
        self.networkManager = networkManager
        self.mobileWallet = mobileWallet
    }
    
    func getPassiveDelegation() -> AnyPublisher<PassiveDelegation, Error> {
        let request = ResourceRequest(url: ApiConstants.passiveDelegation)
        
        return networkManager.load(request)
    }
    
    func getChainParameters() -> AnyPublisher<ChainParametersResponse, Error> {
        let request = ResourceRequest(url: ApiConstants.chainParameters)
        return networkManager.load(request)
    }
    
    func getBakerPool(bakerId: Int) -> AnyPublisher<BakerPoolResponse, Error> {
        let request = ResourceRequest(url: ApiConstants.bakerPool.appendingPathComponent("\(bakerId)"))
        return networkManager.load(request)
    }
    
    func generateBakerKeys() -> Result<GeneratedBakerKeys, Error> {
        return mobileWallet.generateBakerKeys()
    }
}
