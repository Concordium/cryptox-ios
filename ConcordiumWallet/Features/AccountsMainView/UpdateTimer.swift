//
//  UpdateTimer.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.07.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import UIKit
import Combine

class UpdateTimer: ObservableObject {
    var tick: AnyPublisher<Void, Never> { tickSubject.eraseToAnyPublisher() }
    var repeatTime: TimeInterval = 10 //seconds
    
    private var timer: Timer
    private let tickSubject = PassthroughSubject<Void, Never>()
    
    init(repeatTime: TimeInterval = 10) {
        self.repeatTime = repeatTime
        self.timer = Timer()
        
        NotificationCenter.default
            .addObserver(self, selector: #selector(start), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default
            .addObserver(self, selector: #selector(stop), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: repeatTime, repeats: true) { [weak self]  _ in
            guard let self = self else { return }
            self.tickSubject.send(())
        }
    }
    
    @objc
    func stop() {
        timer.invalidate()
    }
    
    @objc
    func pause() {
        timer.invalidate()
    }
}
