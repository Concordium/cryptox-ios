//
//  IdentityCreateWebView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 04.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import WebKit

struct IdentityCreateWebView: UIViewRepresentable {
    let request: URLRequest
    
    var onCallback: (String) -> Void
    var onError: (Error) -> Void
    
    private var webView: WKWebView?
    
    private static var configuration: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        return config
    }
    
    init(request: URLRequest, onCallback: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.onCallback = onCallback
        self.onError = onError
        self.webView = WKWebView(frame: .zero, configuration: Self.configuration)
        self.request = request
    }
  
    func makeUIView(context: Context) -> WKWebView {
        return webView!
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.navigationDelegate = context.coordinator
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator.init(self, onCallback: onCallback, onError: onError)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: IdentityCreateWebView
        
        var onCallback: (String) -> Void
        var onError: (Error) -> Void
        
        init(_ parent: IdentityCreateWebView, onCallback: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
            self.parent = parent
            self.onCallback = onCallback
            self.onError = onError
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString, url.hasPrefix(ApiConstants.notabeneCallback) {
                self.onCallback(url)
            }
            decisionHandler(WKNavigationActionPolicy.allow)
        }

        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !error.isAttemptedToLoadCallbackError {
                self.onError(error)
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if !error.isAttemptedToLoadCallbackError {
                self.onError(error)
            }
        }
    }
}

private extension Error {
    var isAttemptedToLoadCallbackError: Bool {
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain
        && nsError.code == NSURLErrorUnsupportedURL
        && (failingURL?.absoluteString.hasPrefix(ApiConstants.notabeneCallback) ?? false)
    }
    
    private var failingURL: URL? {
        return (self as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL
    }
}
