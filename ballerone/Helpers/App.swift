//
//  App.swift
//  ballerone
//
//  Created by LLOYD Briggs on 12/6/18.
//  Copyright © 2018 LLOYD Briggs. All rights reserved.
//

import ARKit

class App {
    indirect enum Ball {
        case notRegistered
        case registered(Ball)
    }

    public var ball: Ball = .notRegistered
}

class Ball {
    var instance: SCNNode

    init(instance: SCNNode) {
        self.instance = instance
    }
}
