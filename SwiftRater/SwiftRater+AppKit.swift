//
//  File.swift
//  
//
//  Created by Emil Landron on 2/22/24.
//

#if os(macOS)
import AppKit
import StoreKit

struct MacAlertPresenter: SwiftRaterAlertPresenter {
    
    public func present(_ alert: SwiftRaterAlert) {
        
        let nsAlert = NSAlert()
        nsAlert.messageText = alert.title
        nsAlert.informativeText = alert.message
        nsAlert.alertStyle = .warning
        nsAlert.addButton(withTitle: alert.rateAction.title)
        
        if let later = alert.laterAction {
            nsAlert.addButton(withTitle: later.title)
        }
        
        nsAlert.addButton(withTitle: alert.cancelAction.title)
        
        
        let result = nsAlert.runModal()
        
        switch result {
        case .alertFirstButtonReturn:
            alert.rateAction.handler()
            
        case .alertSecondButtonReturn:
            alert.laterAction?.handler()
            
        case .alertThirdButtonReturn:
            alert.cancelAction.handler()
            
        default:
            break
        }
    }
    
    public func requestReview() {
        SKStoreReviewController.requestReview()
    }
}

#endif
