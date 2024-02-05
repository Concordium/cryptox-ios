//
//  ConsentManager.swift
//  Mock
//
//  Created by Maxim Liashenko on 01.12.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation

import AdSupport
import AppTrackingTransparency

import Firebase


protocol ConsentManagerDelegate: AnyObject {
    func willPresentGDPRAlert()
}

class ConsentManager {
    
    public static var shared: ConsentManager = ConsentManager()
    
    private init () { }
    private let locationManager = LocationManager()
    weak var delegate: ConsentManagerDelegate?
    
    var isATTEnabled: Bool? {
        if #available(iOS 14, *) {
            let trackingStatus = ATTrackingManager.trackingAuthorizationStatus
            switch trackingStatus {
            case .authorized, .restricted:
                return true
            case .denied:
                return false
            case .notDetermined:
                return nil
            @unknown default:
                return nil
            }
        } else {
            return true
        }
    }
        
    private (set) var isAnalyticsStart: Bool = false
    
}


extension ConsentManager {
    
    func start() {
        DispatchQueue.main.async {
            FirebaseApp.configure()
        }
        isAnalyticsStart = true
    }
    
    // TODO: enable gdpr
    private func startAnalytics() {
       
        let isGDPRRegion = AppSettings.isGDPRRegion
        let isGDPREnabled = AppSettings.isGDPREnabled
        switch (isGDPRRegion, isGDPREnabled, isATTEnabled) {
        case (true, true, true), (false, _, true):
            DispatchQueue.main.async {
                FirebaseApp.configure()
            }
            //delegate = nil
            isAnalyticsStart = true
            
        default:
            failure()
        }
    }
    
    func failure() {
        isAnalyticsStart = false
    }
    
    func process() {
        processGDPR(isGDPRRegion: AppSettings.isGDPRRegion, isGDPREnabled: AppSettings.isGDPREnabled)
    }
    
    
    func processGDPR(isGDPRRegion: Bool?,  isGDPREnabled: Bool?) {
        
        switch (isGDPRRegion, isGDPREnabled) {
        case (nil, _):
            fetchRegion()
        case (true, nil):
            requestGDPR()
        case (true, false):
            failure()
        case (true, true) where isATTEnabled == nil:
            requestATTPermission()
        case (true, true) where isATTEnabled == true:
            start()
        case (false, _) where isATTEnabled == nil:
            requestATTPermission()
        case (false, _) where isATTEnabled == true:
            start()
        default:
            break
        }
    }
}


extension ConsentManager {
    
    private func fetchRegion() {       
        locationManager.fetchCountry { [weak self] result in
            AppSettings.isGDPRRegion = result
            self?.process()
        }
    }
    
    private func requestGDPR() {
        delegate?.willPresentGDPRAlert()
    }
    
    // PERMISSIONS FOR iOS 14
    private func requestATTPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                self?.process()
            }
        } else {
          process()
        }
    }
}
