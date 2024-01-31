//
//  SwiftRaterAlert.swift
//  SwiftRater
//
//  Created by Emil Landron on 1/31/24.
//  Copyright © 2024 com.takecian. All rights reserved.
//

import Foundation
import StoreKit

public protocol SwiftRaterAlertPresenter {
    
    func present(_ alert: SwiftRaterAlert)
    func requestReview()
}

public struct SwiftRaterAlert: Identifiable {
    
    public struct Action {
        public let title: String
        public let handler: () -> Void
    }
    
    public let id = UUID()
    
    public let title: String
    public let message: String
    
    public let rateAction: Action
    public let cancelAction: Action
    public let laterAction: Action?
}
