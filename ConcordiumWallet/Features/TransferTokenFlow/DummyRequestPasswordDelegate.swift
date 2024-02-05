//
//  DummyRequestPasswordDelegate.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 23.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import UIKit
import Combine

final class DummyRequestPasswordDelegate: RequestPasswordDelegate {
    func requestUserPassword(keychain: KeychainWrapperProtocol) -> AnyPublisher<String, Error> {
        let requestPasswordPresenter = RequestPasswordPresenter(keychain: keychain)
        var modalPasswordVCShown = false
        let topController = UIApplication.shared.topMostViewController()

        requestPasswordPresenter.performBiometricLogin(fallback: {
            self.show(requestPasswordPresenter)
            modalPasswordVCShown = true
        })

        let cleanup: (Result<String, Error>) -> Future<String, Error> = { result in
                    let future = Future<String, Error> { promise in
                        if modalPasswordVCShown {
                            topController?.presentedViewController?.dismiss(animated: true, completion: {
                                promise(result)
                            })
                        } else {
                            promise(result)
                        }
                    }
                    return future
                }

        return requestPasswordPresenter.passwordPublisher
                .flatMap { cleanup(.success($0)) }
                .catch { cleanup(.failure($0)) }
                .eraseToAnyPublisher()
    }
    
    private func  show(_ presenter: RequestPasswordPresenter) {
        let vc = EnterPasswordFactory.create(with: presenter)
        let nc = CXNavigationController()
        nc.modalPresentationStyle = .fullScreen
        nc.viewControllers = [vc]
        let topController = UIApplication.shared.topMostViewController()
        topController?.present(nc, animated: true)
    }
}
