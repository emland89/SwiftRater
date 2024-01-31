//
//  SwiftRater+UIKit.swift
//  SwiftRater
//
//  Created by Emil Landron on 1/31/24.
//  Copyright © 2024 com.takecian. All rights reserved.
//

#if os(iOS)
import UIKit
import StoreKit


struct iOSAlertPresenter: SwiftRaterAlertPresenter {
    
    private var viewController: UIViewController? {
        UIApplication.shared.keyWindow?.rootViewController
    }
    
    func present(_ alert: SwiftRaterAlert) {
        viewController?.present(alert)
    }
    
    func requestReview() {
        viewController?.requestReview()
    }
    
}

extension UIViewController: SwiftRaterAlertPresenter {
    
    public func present(_ alert: SwiftRaterAlert) {
        
        let alertController = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)

        let rateAction = UIAlertAction(title: alert.rateAction.title, style: .default) { _ in
            alert.rateAction.handler()
        }
        
        alertController.addAction(rateAction)

        if let laterAction = alert.laterAction {
            let laterAction =  UIAlertAction(title: laterAction.title, style: .default) { _ in
                alert.rateAction.handler()
            }
            
            alertController.addAction(laterAction)
        }
        
        let cancelAction = UIAlertAction(title: alert.cancelAction.title, style: .cancel) { _ in
            alert.cancelAction.handler()
        }
        
        alertController.addAction(cancelAction)

        alertController.preferredAction = rateAction
        
    }
    
    public func requestReview() {
        
        if let windowScene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

#endif
