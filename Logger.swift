//
//  Logger.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.07.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import OSLog

let logger: Logger = Logger.statistics

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// Logs the view cycles like a view that appeared.
    static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")
    
    /// All logs related to tracking and analytics.
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}

///
/// Logger.viewCycle.notice("Notice example")
/// Logger.viewCycle.info("Info example")
/// Logger.viewCycle.debug("Debug example")
/// Logger.viewCycle.trace("Notice example")
/// Logger.viewCycle.warning("Warning example")
/// Logger.viewCycle.error("Error example")
/// Logger.viewCycle.fault("Fault example")
/// Logger.viewCycle.critical("Critical example")
///
extension Logger {
    /// Logger.viewCycle.debug("Debug example")
    func debugLog(_ msg: String) {
        Logger.viewCycle.debug("🐞 \(msg)")
    }
    
    /// Logger.viewCycle.warning("Warning example")
    func warningLog(_ msg: String) {
        Logger.viewCycle.warning("🚨 \(msg)")
    }
    
    /// Logger.viewCycle.error("Error example")
    func errorLog(_ msg: String) {
        Logger.viewCycle.error("🚧 \(msg)")
    }
    
    /// Logger.viewCycle.critical("Error example")
    func criticalLog(_ msg: String) {
        Logger.viewCycle.critical("☠️ \(msg)")
    }
}
