//
//  AnalyticsPermissionController.swift
//  Mock
//
//  Created by Maxim Liashenko on 01.12.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

class AnalyticsPermissionController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func didTapApply() {
        AppSettings.isGDPREnabled = true

        dismiss(animated: true) {
            ConsentManager.shared.process()
        }
    }
    
    @IBAction func didTapCancel() {
        AppSettings.isGDPREnabled = false
        dismiss(animated: true) {
            
            ConsentManager.shared.process()
        }
    }
}
