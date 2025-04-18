//
//  WarningDisplayer.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation
import Combine

enum Warning {
    case backup
    case identityPending(identity: IdentityDataType)
    
    func identifier() -> String {
        switch self {
        case .backup:
            return "backup"
        case .identityPending(let identity):
            return "identity" + (identity.hashedIpStatusUrl ?? "")
        }
    }
}

extension Warning: Equatable {
    static func == (lhs: Warning, rhs: Warning) -> Bool {
        switch (lhs, rhs) {
        case (.backup, backup):
//            return true
            return false
                return false
        case (.identityPending(let lhs), .identityPending(let rhs)):
            return (lhs.hashedIpStatusUrl == rhs.hashedIpStatusUrl)
        default:
            return false
        }
    }
}
extension Warning: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier())
    }
}

struct WarningViewModel {
    enum Priority {
//        case warning
        case info
    }

    var imageName: String
    var text: String
    var dismissable: Bool
    var priority: Priority

    init(warning: Warning) {
        switch warning {

//        case .backup:
//            imageName = "warning_backup"
//            text = "accounts.backupwarning.text".localized
//            dismissable = false
//            priority = .warning
        case .identityPending(let identity):
            imageName = "warning_identity"
            text = String(format: "accounts.identitywarning.text".localized, identity.nickname)
            dismissable = true
            priority = .info
        default:
            imageName = ""
            text = ""
            dismissable = false
            priority = .info
        }
    }
}

protocol WarningDisplayerDelegate: AnyObject {
    func performAction(for warning: Warning)
}

class WarningDisplayer {

    @Published var shownWarningDisplay: WarningViewModel?

    @Published private var warnings: Set<Warning> = []
    private var shownWarning: Warning?
    private var cancellables: [AnyCancellable] = []

    weak var delegate: WarningDisplayerDelegate? {
        didSet {
            $warnings.sink { [weak self] warnings in
                guard let self = self else { return }
                let firstWarning = warnings.sorted { lhs, rhs in
                    switch (lhs, rhs) {
                    case (_, .backup):
//                        return true
                        return false
                    case (.identityPending(let lhs), .identityPending(let rhs)):
                        let lhs = lhs.hashedIpStatusUrl ?? ""
                        let rhs = rhs.hashedIpStatusUrl ?? ""
                        return lhs < rhs
                    default:
                        return false
                    }
                }.first
                if let warning = firstWarning {
                    self.shownWarningDisplay = WarningViewModel(warning: warning)
                    self.shownWarning = warning
                } else {
                    self.shownWarningDisplay = nil
                    self.shownWarning = nil
                }
            }.store(in: &cancellables)
        }
    }

    init() {
    }

    func addWarning(_ warning: Warning) {
        let dismissedIds = AppSettings.dismissedWarningIds
        if !dismissedIds.contains(warning.identifier()) {
            warnings.insert(warning)
        }
    }

    func dismissedWarning() {
        if let shownWarning = self.shownWarning {
            var dismissedIds = AppSettings.dismissedWarningIds
            dismissedIds.append(shownWarning.identifier())
            AppSettings.dismissedWarningIds = dismissedIds
            warnings.remove(shownWarning)
        }
    }

    func pressedWarning() {
        if let shownWarning = shownWarning {
            self.delegate?.performAction(for: shownWarning)
        }
    }

    func clearIdentityWarnings() {
        warnings = warnings.filter {
            if case .identityPending = $0 {
                return false
            } else {
                return true
            }
        }
    }

    func clearBackupWarnings() {
        warnings = warnings.filter {
            if case .backup = $0 {
                return false
            } else {
                return true
            }
        }
    }

}
