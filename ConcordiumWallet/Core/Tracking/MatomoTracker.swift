//
//  MatomoTracker.swift
//  CryptoX
//
//  Created by Max on 18.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import MatomoTracker

extension MatomoTracker {
    static let shared: MatomoTracker = {
        let queue = UserDefaultsQueue(UserDefaults.standard, autoSave: true)
        let dispatcher = URLSessionDispatcher(baseURL: URL(string: AppConstants.MatomoTracker.baseUrl)!)
        let matomoTracker = MatomoTracker(siteId: AppConstants.MatomoTracker.siteId, queue: queue, dispatcher: dispatcher)
        matomoTracker.logger = DefaultLogger(minLevel: .verbose)
        matomoTracker.migrateFromFourPointFourSharedInstance()
        return matomoTracker
    }()
    
    private func migrateFromFourPointFourSharedInstance() {
        guard !UserDefaults.standard.bool(forKey: AppConstants.MatomoTracker.migratedFromFourPointFourSharedInstance) else { return }
        copyFromOldSharedInstance()
        UserDefaults.standard.set(true, forKey: AppConstants.MatomoTracker.migratedFromFourPointFourSharedInstance)
    }
}

protocol Track {
    static func track(view: [String])
    
    /// `trackContentInteraction` used to track user interaction with UI elements
    /// - Parameters:
    ///   - name: View name where interaction was initiated
    ///   - interaction: Interaction Type. predefined actions list
    ///   - piece: Interaction description: eg "Copy to clipboard"
    ///   - target: optinal value for target action
    static func trackContentInteraction(name: String, interaction: Tracker.InteractionType, piece: String?, target: String?)
}

struct Tracker: Track {
    enum InteractionType: String {
        case clicked, checked, entered
    }
    // Convenience method override, to avoid `import MatomoTracker` everywhere
    static func track(view: [String]) {
        MatomoTracker.shared.track(view: view)
    }
    
    // Convenience method override, to avoid `import MatomoTracker` everywhere
    static func trackContentInteraction(name: String, interaction: Tracker.InteractionType, piece: String? = nil, target: String? = nil) {
        MatomoTracker.shared.trackContentInteraction(name: name, interaction: interaction.rawValue, piece: piece, target: target)
    }
}
