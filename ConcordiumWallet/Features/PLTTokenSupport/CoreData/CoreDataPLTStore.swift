//
//  CoreDataPLTStore.swift
//  CryptoX
//
//  Created by Zhanna Komar on 15.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import CoreData
import Combine

final class CoreDataPLTStore {

    static let shared = CoreDataPLTStore()
    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "CryptoXDataModel")
        container.loadPersistentStores { _, error in
            if let error { fatalError("❌ \(error)") }
        }
    }

    func saveTokens(_ tokens: [AccountPLTToken], for accountAddress: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            CoreDataPLTStore.shared.container.performBackgroundTask { context in
                do {
                    try self.saveAccountTokens(tokens, accountAddress: accountAddress, context: context)
                    DispatchQueue.main.async {
                        promise(.success(()))
                    }
                } catch {
                    context.rollback()
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func saveAccountTokens(_ tokens: [AccountPLTToken], accountAddress: String, context: NSManagedObjectContext) throws {
        for model in tokens {
            try upsertPLTToken(model, accountAddress: accountAddress, context: context)
        }

        try context.save()
    }
    
    
    func savePLTTokens(_ tokens: [PLTToken], for accountAddress: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            self.container.performBackgroundTask { context in
                do {
                    for model in tokens {
                        let request: NSFetchRequest<PLTTokenEntity> = PLTTokenEntity.fetchRequest()
                        request.predicate = NSPredicate(format: "tokenId == %@ AND accountAddress == %@", model.tokenID, accountAddress)
                        request.fetchLimit = 1

                        let existing = try context.fetch(request).first

                        guard existing == nil else {
                            continue
                        }

                        let token = PLTTokenEntity(context: context)
                        token.accountAddress = accountAddress
                        token.tokenId = model.tokenID

                        let tokenState = TokenStateEntity(context: context)
                        tokenState.decimals = Int16(model.tokenState.decimals)
                        tokenState.tokenModuleRef = model.tokenState.tokenModuleRef

                        let totalSupply = TotalSupplyEntity(context: context)
                        totalSupply.decimals = Int16(model.tokenState.totalSupply.decimals)
                        totalSupply.value = model.tokenState.totalSupply.value
                        tokenState.totalSupply = totalSupply

                        let metadata = MetadataEntity(context: context)
                        metadata.url = model.tokenState.moduleState.metadata.url

                        let governance = GovernanceAccountEntity(context: context)
                        governance.address = model.tokenState.moduleState.governanceAccount.address
                        governance.type = model.tokenState.moduleState.governanceAccount.type

                        let moduleState = ModuleStateEntity(context: context)
                        moduleState.allowList = model.tokenState.moduleState.allowList
                        moduleState.burnable = model.tokenState.moduleState.burnable
                        moduleState.denyList = model.tokenState.moduleState.denyList
                        moduleState.mintable = model.tokenState.moduleState.mintable
                        moduleState.name = model.tokenState.moduleState.name
                        moduleState.metadata = metadata
                        moduleState.governanceAccount = governance

                        tokenState.moduleState = moduleState
                        token.tokenState = tokenState
                    }

                    try context.save()
                    DispatchQueue.main.async {
                        promise(.success(()))
                    }
                } catch {
                    context.rollback()
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func upsertPLTToken(_ model: AccountPLTToken, accountAddress: String, context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<AccountPLTTokenEntity> = AccountPLTTokenEntity.fetchRequest()
        request.predicate = NSPredicate(format: "token.tokenId == %@ AND accountAddress == %@", model.token.tokenID, accountAddress)
        request.fetchLimit = 1

        let existing = try context.fetch(request).first

        let pltToken = existing ?? AccountPLTTokenEntity(context: context)

        if existing == nil {
            // Only create new if needed
            let token = PLTTokenEntity(context: context)
            token.tokenId = model.token.tokenID
            token.accountAddress = accountAddress

            let tokenState = TokenStateEntity(context: context)
            tokenState.decimals = Int16(model.token.tokenState.decimals)
            tokenState.tokenModuleRef = model.token.tokenState.tokenModuleRef

            let totalSupply = TotalSupplyEntity(context: context)
            totalSupply.decimals = Int16(model.token.tokenState.totalSupply.decimals)
            totalSupply.value = model.token.tokenState.totalSupply.value
            tokenState.totalSupply = totalSupply

            let metadata = MetadataEntity(context: context)
            metadata.url = model.token.tokenState.moduleState.metadata.url

            let governance = GovernanceAccountEntity(context: context)
            governance.address = model.token.tokenState.moduleState.governanceAccount.address
            governance.type = model.token.tokenState.moduleState.governanceAccount.type

            let moduleState = ModuleStateEntity(context: context)
            moduleState.allowList = model.token.tokenState.moduleState.allowList
            moduleState.burnable = model.token.tokenState.moduleState.burnable
            moduleState.denyList = model.token.tokenState.moduleState.denyList
            moduleState.mintable = model.token.tokenState.moduleState.mintable
            moduleState.name = model.token.tokenState.moduleState.name
            moduleState.metadata = metadata
            moduleState.governanceAccount = governance

            tokenState.moduleState = moduleState
            token.tokenState = tokenState

            pltToken.token = token
        }

        // Always update account state
        let balance = TokenBalanceEntity(context: context)
        balance.decimals = Int16(model.tokenAccountState.balance.decimals)
        balance.value = model.tokenAccountState.balance.value

        let state = StateEntity(context: context)
        state.denyList = model.tokenAccountState.state.denyList ?? false

        let accountState = TokenAccountStateEntity(context: context)
        accountState.balance = balance
        accountState.state = state

        pltToken.tokenAccountState = accountState
        pltToken.accountAddress = accountAddress
    }
    
    func fetchPLTTokens(for accountAddress: String) throws -> [PLTTokenEntity] {
        let request: NSFetchRequest<PLTTokenEntity> = PLTTokenEntity.fetchRequest()
        request.predicate = NSPredicate(format: "accountAddress == %@", accountAddress)
        return try CoreDataPLTStore.shared.container.viewContext.fetch(request)
    }
    
    func fetchAccountPLTTokens(for accountAddress: String) throws -> [AccountPLTTokenEntity] {
        let request: NSFetchRequest<AccountPLTTokenEntity> = AccountPLTTokenEntity.fetchRequest()
        request.predicate = NSPredicate(format: "accountAddress == %@", accountAddress)
        return try CoreDataPLTStore.shared.container.viewContext.fetch(request)
    }
    
    func subscribePLTTokensUpdate(for address: String) -> AnyPublisher<[AccountPLTTokenEntity], Never> {
        let request: NSFetchRequest<AccountPLTTokenEntity> = AccountPLTTokenEntity.fetchRequest()
        request.predicate = NSPredicate(format: "accountAddress == %@", address)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \AccountPLTTokenEntity.token.tokenId, ascending: true)
        ]

        let context = CoreDataPLTStore.shared.container.viewContext

        return FetchedResultsPublisher<AccountPLTTokenEntity>(fetchRequest: request, context: context)
            .eraseToAnyPublisher()
    }
    
    func deleteToken(tokenId: String, accountAddress: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                let request: NSFetchRequest<PLTTokenEntity> = PLTTokenEntity.fetchRequest()
                request.predicate = NSPredicate(format: "tokenId == %@ AND accountAddress == %@", tokenId, accountAddress)
                request.fetchLimit = 1

                do {
                    if let tokenEntity = try context.fetch(request).first {
                        context.delete(tokenEntity)
                        try context.save()
                    }
                    continuation.resume()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func isPLTTokenSaved(tokenId: String, for address: String) -> Bool {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<PLTTokenEntity> = PLTTokenEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tokenId == %@ AND accountAddress == %@", tokenId, address)
        fetchRequest.fetchLimit = 1

        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            logger.errorLog("Failed to check token: \(error.localizedDescription)")
            return false
        }
    }
}

final class FetchedResultsPublisher<ResultType: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate, Publisher {
    typealias Output = [ResultType]
    typealias Failure = Never

    private let controller: NSFetchedResultsController<ResultType>
    private var subscriber: AnySubscriber<[ResultType], Never>?

    init(fetchRequest: NSFetchRequest<ResultType>, context: NSManagedObjectContext) {
        self.controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init()
        self.controller.delegate = self
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, [ResultType] == S.Input {
        self.subscriber = AnySubscriber(subscriber)

        do {
            try controller.performFetch()
            subscriber.receive(subscription: Subscriptions.empty)
            _ = self.subscriber?.receive(controller.fetchedObjects ?? [])
        } catch {
            print("❌ Failed to fetch: \(error)")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        _ = subscriber?.receive(self.controller.fetchedObjects ?? [])
    }
}
