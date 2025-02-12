//
//  SceneViewController.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 19.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI

class ClearSceneViewController<Content: View>: UIHostingController<Content> {
    init(content: Content) {
        super.init(rootView: content)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SceneViewController<Content: View>: UIHostingController<Content> {

    var onAppear: (() -> Void)?
    
    init(content: Content) {
        super.init(rootView: content)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onAppear?()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
