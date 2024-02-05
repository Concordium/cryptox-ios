//
//  ImportTokenView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 26.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum ImportTokenError {
    case tokeSaveFailed
}


@MainActor
final class ImportTokenViewModel: ObservableObject {
    @Published var tokens: [CIS2Token] = []
    @Published var selectedToken: CIS2Token?
    @Published var error: ImportTokenError?
    
    private let storageManager: StorageManagerProtocol
    private let address: String
    
    init(storageManager: StorageManagerProtocol, address: String) {
        self.storageManager = storageManager
        self.address = address
        
        logger.debugLog("savedTokens: -- \(self.storageManager.getAccountSavedCIS2Tokens(address))")
    }
    
    func search(name: String) async {
        do {
            guard let index = Int(name) else { return }
            tokens = try await CIS2TokenService.getCIS2Tokens(for: index)
        } catch {
            logger.errorLog(error.localizedDescription)
        }
    }
    
    func saveToken(_ token: CIS2Token?) {
        guard let token = token else { return }
        guard !storageManager.getAccountSavedCIS2Tokens(address).contains(token) else { return }
        
        do {
            try storageManager.storeCIS2Token(token: token, address: address)
        } catch {
            logger.errorLog(error.localizedDescription)
        }
    }
}

struct ImportTokenView: View {
    @StateObject var viewModel: ImportTokenViewModel
    
    @State private var searchText: String = ""
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                List(viewModel.tokens, id: \.tokenId) { token in
                    Button {
                        viewModel.selectedToken = token
                    } label: {
                        TokenView(token: token, isSelected: viewModel.selectedToken == token)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .searchable(text: $searchText)
                .keyboardType(.numberPad)
                .onChange(of: searchText) { value in
                    Task {
                        if !value.isEmpty &&  value.count > 3 {
                            await viewModel.search(name: value)
                        } else {
                            viewModel.tokens.removeAll()
                        }
                    }
                }
                .padding(.top, 16)
                
                HStack(spacing: 20) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.vertical, 11)
                            .background(Color.clear)
                            .overlay(
                                Capsule(style: .circular)
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                    
                    Button {
                        viewModel.saveToken(viewModel.selectedToken)
                        dismiss()
                    } label: {
                        Text("Import")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black)
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.vertical, 11)
                            .background(viewModel.selectedToken == nil ? .white.opacity(0.7) : .white)
                            .clipShape(Capsule())
                    }
                    .disabled(viewModel.selectedToken == nil)
                }
                .padding(.top, 25)
                .padding(.bottom, 24)
                .padding(.horizontal, 20)
            }
            .navigationTitle("nft.import.title")
        }
    }}

struct TokenView: View {
    let token: CIS2Token
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if let url = token.metadata.thumbnail?.url {
                CryptoImage(url: url.toURL, size: .medium)
                    .clipped()
            }
            Text(token.metadata.name ?? "")
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium))
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .overlay {
            if isSelected {
                RoundedCorner(radius: 24, corners: .allCorners)
                    .stroke(Color.blackAditional, lineWidth: 1)
            }
        }
        .overlay(alignment: .trailing) {
            if isSelected {
                selectionOverlay
            }
        }
    }
    
    
    private var selectionOverlay: some View {
        Image("icon_selection")
            .padding(.trailing, 12)
    }
}

import SDWebImageSwiftUI
import SDWebImageSVGCoder

/// https://stackoverflow.com/questions/74427783/download-svg-image-in-ios-swift
class CustomSVGDecoder: NSObject, SDImageCoder {
    
    let fallbackDecoder: SDImageCoder?
    
    init(fallbackDecoder: SDImageCoder?) {
        self.fallbackDecoder =  fallbackDecoder
    }
    
    static var regex: NSRegularExpression = {
        let pattern = "<image.*xlink:href=\"data:image\\/(png|jpg);base64,(.*)\"\\/>"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        return regex
    }()
    
    func canDecode(from data: Data?) -> Bool {
        guard let data = data, let string = String(data: data, encoding: .utf8) else { return false }
        guard Self.regex.firstMatch(in: string, range: NSRange(location: 0, length: string.utf16.count)) == nil else {
            return true //It self should decode
        }
        guard let fallbackDecoder = fallbackDecoder else {
            return false
        }
        return fallbackDecoder.canDecode(from: data)
    }
    
    func decodedImage(with data: Data?, options: [SDImageCoderOption : Any]? = nil) -> UIImage? {
        guard let data = data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        guard let match = Self.regex.firstMatch(in: string, range: NSRange(location: 0, length: string.utf16.count)) else {
            return fallbackDecoder?.decodedImage(with: data, options: options)
        }
        guard let rawBase64DataRange = Range(match.range(at: 2), in: string) else {
            return fallbackDecoder?.decodedImage(with: data, options: options)
        }
        let rawBase64Data = String(string[rawBase64DataRange])
        guard let imageData = Data(base64Encoded: Data(rawBase64Data.utf8), options: .ignoreUnknownCharacters) else {
            return fallbackDecoder?.decodedImage(with: data, options: options)
        }
        return UIImage(data: imageData)
    }
    
    //You might need to implement these methods, I didn't check their meaning yet
    func canEncode(to format: SDImageFormat) -> Bool {
        return true
    }
    
    func encodedData(with image: UIImage?, format: SDImageFormat, options: [SDImageCoderOption : Any]? = nil) -> Data? {
        return nil
    }
}
