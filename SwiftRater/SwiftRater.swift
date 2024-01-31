//
//  SwiftRater.swift
//  SwiftRater
//
//  Created by Fujiki Takeshi on 2017/03/28.
//  Copyright © 2017年 com.takecian. All rights reserved.
//


import Foundation

@objc public enum SwiftRaterConditionsMetMode: Int {
    case all
    case any
}

@objc public class SwiftRater: NSObject {
    
    public enum ButtonIndex: Int {
        case cancel = 0
        case rate = 1
        case later = 2
        
        public var description: String {
            switch self {
            case .cancel:
                return "cancel"
                
            case .later:
                return "later"
                
            case .rate:
                return "rate"
            }
        }
    }
    
    @objc public let SwiftRaterErrorDomain = "Siren Error Domain"
    
    @objc public static var daysUntilPrompt: Int {
        get {
            return UsageDataManager.shared.daysUntilPrompt
        }
        set {
            UsageDataManager.shared.daysUntilPrompt = newValue
        }
    }
    @objc public static var usesUntilPrompt: Int {
        get {
            return UsageDataManager.shared.usesUntilPrompt
        }
        set {
            UsageDataManager.shared.usesUntilPrompt = newValue
        }
    }
    @objc public static var significantUsesUntilPrompt: Int {
        get {
            return UsageDataManager.shared.significantUsesUntilPrompt
        }
        set {
            UsageDataManager.shared.significantUsesUntilPrompt = newValue
        }
    }
    
    @objc public static var daysBeforeReminding: Int {
        get {
            return UsageDataManager.shared.daysBeforeReminding
        }
        set {
            UsageDataManager.shared.daysBeforeReminding = newValue
        }
    }
    @objc public static var debugMode: Bool {
        get {
            return UsageDataManager.shared.debugMode
        }
        set {
            UsageDataManager.shared.debugMode = newValue
        }
    }
    @objc public static var conditionsMetMode: SwiftRaterConditionsMetMode {
        get {
            return UsageDataManager.shared.conditionsMetMode
        }
        set {
            UsageDataManager.shared.conditionsMetMode = newValue
        }
    }
    
    @objc public static var shouldShowRequestNextSignificantEvent: Bool {
        get {
            return UsageDataManager.shared.shouldShowRequestNextSignificantEvent
        }
        set {
            UsageDataManager.shared.shouldShowRequestNextSignificantEvent = newValue
        }
    }
    
    @objc public static var useStoreKitIfAvailable: Bool = true
    
    @objc public static var showLaterButton: Bool = true
    
    @objc public static var countryCode: String?
    
    @objc public static var alertTitle: String?
    @objc public static var alertMessage: String?
    @objc public static var alertCancelTitle: String?
    @objc public static var alertRateTitle: String?
    @objc public static var alertRateLaterTitle: String?
    @objc public static var appName: String?
    
    @objc public static var showLog: Bool = false
    @objc public static var resetWhenAppUpdated: Bool = true
    
    @objc public static var shared = SwiftRater()
    
    @objc public static var isRateDone: Bool {
        return UsageDataManager.shared.isRateDone
    }
    
    @objc public static var appID: String?
    
    public var delegate: SwiftRaterDelegate?
    
    public static var alertPresenter: SwiftRaterAlertPresenter?
    
    
    private static var appVersion: String {
        get {
            return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "0.0.0"
        }
    }
    
    private var titleText: String {
        return SwiftRater.alertTitle ?? String.init(format: localize("Rate %@"), mainAppName)
    }
    
    private var messageText: String {
        return SwiftRater.alertMessage ?? String.init(format: localize("Rater.title"), mainAppName)
    }
    
    private var rateText: String {
        return SwiftRater.alertRateTitle ?? String.init(format: localize("Rate %@"), mainAppName)
    }
    
    private var cancelText: String {
        return SwiftRater.alertCancelTitle ?? String.init(format: localize("No, Thanks"), mainAppName)
    }
    
    private var laterText: String {
        return SwiftRater.alertRateLaterTitle ?? String.init(format: localize("Remind me later"), mainAppName)
    }
    
    private func localize(_ key: String) -> String {
        return NSLocalizedString(key, tableName: "SwiftRaterLocalization", bundle: Bundle.module, comment: "")
    }
    
    private var mainAppName: String {
        if let name = SwiftRater.appName {
            return name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        } else if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return name
        } else {
            return "App"
        }
    }
    
    private override init() {
        super.init()
    }
    
    @objc public static func appLaunched() {
        if SwiftRater.resetWhenAppUpdated && SwiftRater.appVersion != UsageDataManager.shared.trackingVersion {
            UsageDataManager.shared.reset()
            UsageDataManager.shared.trackingVersion = SwiftRater.appVersion
        }
        
        SwiftRater.shared.perform()
    }
    
    @objc public static func incrementSignificantUsageCount() {
        UsageDataManager.shared.incrementSignificantUseCount()
    }
    
    @discardableResult
    @objc public static func check() -> Bool {
        guard UsageDataManager.shared.ratingConditionsHaveBeenMet || shouldShowRequestNextSignificantEvent else {
            return false
        }
        
        SwiftRater.shared.showRatingAlert(force: false)
        shouldShowRequestNextSignificantEvent = false
        return true
    }
    
    @objc public static func rateApp() {
        NSLog("[SwiftRater] Trying to show review request dialog.")
        SwiftRater.shared.showRatingAlert(force: true)
        
        UsageDataManager.shared.isRateDone = true
    }
    
    @objc public static func reset() {
        UsageDataManager.shared.reset()
    }
    
    private func perform() {
        if SwiftRater.appName != nil {
            incrementUsageCount()
        } else {
            // If not set, get appID and version from itunes
            do {
                let url = try iTunesURLFromString()
                let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
                URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                    self.processResults(withData: data, response: response, error: error)
                }).resume()
            } catch let error {
                postError(.malformedURL, underlyingError: error)
            }
        }
    }
    
    private func processResults(withData data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            self.postError(.appStoreDataRetrievalFailure, underlyingError: error)
        } else {
            guard let data = data else {
                self.postError(.appStoreDataRetrievalFailure, underlyingError: nil)
                return
            }
            
            do {
                let jsonData = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                guard let appData = jsonData as? [String: Any] else {
                    self.postError(.appStoreJSONParsingFailure, underlyingError: nil)
                    return
                }
                
                DispatchQueue.main.async {
                    // Print iTunesLookup results from appData
                    //                    self.printMessage(message: "JSON results: \(appData)")
                    
                    // Process Results (e.g., extract current version that is available on the AppStore)
                    self.processVersionCheck(withResults: appData)
                }
                
            } catch let error {
                self.postError(.appStoreDataRetrievalFailure, underlyingError: error)
            }
        }
    }
    
    private func processVersionCheck(withResults results: [String: Any]) {
        defer {
            incrementUsageCount()
        }
        guard let allResults = results["results"] as? [[String: Any]] else {
            self.postError(.appStoreDataRetrievalFailure, underlyingError: nil)
            return
        }
        
        /// App not in App Store
        guard !allResults.isEmpty else {
            postError(.appStoreDataRetrievalFailure, underlyingError: nil)
            return
        }
        
        guard let appID = allResults.first?["trackId"] as? Int else {
            postError(.appStoreAppIDFailure, underlyingError: nil)
            return
        }
        
        SwiftRater.appID = String(appID)
    }
    
    private func iTunesURLFromString() throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        if let countryCode = SwiftRater.countryCode {
            components.path = "/\(countryCode)/lookup"
        } else {
            components.path = "/lookup"
        }
        
        let items: [URLQueryItem] = [URLQueryItem(name: "bundleId", value: Bundle.bundleID())]
        
        components.queryItems = items
        
        guard let url = components.url, !url.absoluteString.isEmpty else {
            throw SwiftRaterError.malformedURL
        }
        
        return url
    }
    
    private func postError(_ code: SwiftRaterErrorCode, underlyingError: Error?) {
        let description: String
        
        switch code {
        case .malformedURL:
            description = "The iTunes URL is malformed. Please leave an issue on http://github.com/ArtSabintsev/Siren with as many details as possible."
       
        case .appStoreDataRetrievalFailure:
            description = "Error retrieving App Store data as an error was returned."
       
        case .appStoreJSONParsingFailure:
            description = "Error parsing App Store JSON data."
      
        case .appStoreAppIDFailure:
            description = "Error retrieving trackId as results.first does not contain a 'trackId' key."
        }
        
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: description]
        
        if let underlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        
        let error = NSError(domain: SwiftRaterErrorDomain, code: code.rawValue, userInfo: userInfo)
        printMessage(message: error.localizedDescription)
    }
    
    private func printMessage(message: String) {
        if SwiftRater.showLog {
            print("[SwiftRater] \(message)")
        }
    }
    
    private func incrementUsageCount() {
        UsageDataManager.shared.incrementUseCount()
    }
    
    private func incrementSignificantUseCount() {
        UsageDataManager.shared.incrementSignificantUseCount()
    }
    
    private func showRatingAlert(force: Bool) {
        
        let rateAction = SwiftRaterAlert.Action(title: rateText, handler: { [unowned self] in
            alertPresenter?.requestReview()
            UsageDataManager.shared.isRateDone = true
            delegate?.swiftRater(self, requestActionSelected: .rate)
        })
        
        let cancelAction = SwiftRaterAlert.Action(title: cancelText, handler: { [unowned self] in
            UsageDataManager.shared.isRateDone = true
            self.delegate?.swiftRater(self, requestActionSelected: .cancel)
        })
        
        var laterAction: SwiftRaterAlert.Action?
        
        if SwiftRater.showLaterButton {
            laterAction = SwiftRaterAlert.Action(title: laterText, handler: { [unowned self] in
                UsageDataManager.shared.saveReminderRequestDate()
                self.delegate?.swiftRater(self, requestActionSelected: .later)
            })
        }
        
        let alert = SwiftRaterAlert(
            title: titleText,
            message: messageText,
            rateAction: rateAction,
            cancelAction: cancelAction,
            laterAction: laterAction
        )
        
        alertPresenter?.present(alert)
        delegate?.swiftRaterRequestAlertPresented(self)
    }
    
#if os(iOS)
    
    private var alertPresenter: SwiftRaterAlertPresenter? {
        Self.alertPresenter ?? iOSAlertPresenter()
    }
    
#elseif os(visionOS)
    
    private var alertPresenter: SwiftRaterAlertPresenter? {
        Self.alertPresenter
    }
    
#elseif os(macOS)
    
    private var alertPresenter: SwiftRaterAlertPresenter? {
        Self.alertPresenter ?? MacAlertPresenter()
    }
    
#endif
}
