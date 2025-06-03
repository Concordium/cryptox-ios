//
//  AddMemoViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Combine

class AddMemoViewModel: ObservableObject {
    @Published var memo: Memo?
    @Published var enableAddMemoToTransferButton = true
    @Published var invalidMemoSizeError = false
    @Published var shakeTextView = false
    private var cancellables = [AnyCancellable]()

    init() {
        $memo
            .compactMap { $0 }
            .map { !ValidationProvider.validate(.memoSize($0)) }
            .assign(to: \.invalidMemoSizeError, on: self)
            .store(in: &cancellables)
        
        $memo
            .withPrevious()
            .map {
                guard
                    let previous = $0.previous,
                    let current = $0.current,
                    !ValidationProvider.validate(.memoSize(current))
                else {
                    return false
                }
                
                return current.size >= (previous?.size ?? 0)
            }
            .assign(to: \.shakeTextView, on: self)
            .store(in: &cancellables)
                
        $memo
            .compactMap { $0 }
            .map { ValidationProvider.validate(.memoSize($0)) }
            .assign(to: \.enableAddMemoToTransferButton, on: self)
            .store(in: &cancellables)
        }

    
    func updateMemo(_ text: String) {
        memo = Memo(text)
    }
    
    func removeMemo() {
        memo = nil
        invalidMemoSizeError = false
    }
}
