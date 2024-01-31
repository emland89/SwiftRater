//
//  SwiftRaterDelegate.swift
//  SwiftRater
//
//  Created by Emil Landron on 1/31/24.
//  Copyright © 2024 com.takecian. All rights reserved.
//

import Foundation

public protocol SwiftRaterDelegate: AnyObject {

    func swiftRaterRequestAlertPresented(_ rater: SwiftRater)
    func swiftRater(_ rater: SwiftRater, requestActionSelected button: SwiftRater.ButtonIndex)
}
