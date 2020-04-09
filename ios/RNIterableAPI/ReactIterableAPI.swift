//
//  Created by Tapash Majumder on 3/19/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

import IterableSDK

@objc(ReactIterableAPI)
class ReactIterableAPI: RCTEventEmitter {
    @objc static override func moduleName() -> String! {
        return "RNIterableAPI"
    }
    
    override var methodQueue: DispatchQueue! {
        _methodQueue
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        false
    }
    
    enum EventName: String, CaseIterable {
        case handleUrlCalled
        case handleCustomActionCalled
        case handleInAppCalled
    }

    override func supportedEvents() -> [String]! {
        var result = [String]()
        EventName.allCases.forEach {
            result.append($0.rawValue)
        }
        return result
    }
    
    override func startObserving() {
        ITBInfo()
        shouldEmit = true
    }
    
    override func stopObserving() {
        ITBInfo()
        shouldEmit = false
    }
    
    @objc(initializeWithApiKey:config:)
    func initialize(apiKey: String, config configDict: [AnyHashable: Any]) {
        ITBInfo()
        let launchOptions = createLaunchOptions()
        let iterableConfig = IterableConfig.from(dict: configDict)
        if let urlDelegatePresent = configDict["urlDelegatePresent"] as? Bool, urlDelegatePresent == true {
            iterableConfig.urlDelegate = self
        }
        if let customActionDelegatePresent = configDict["customActionDelegatePresent"] as? Bool, customActionDelegatePresent == true {
            iterableConfig.customActionDelegate = self
        }
        if let inAppDelegatePresent = configDict["inAppDelegatePresent"] as? Bool, inAppDelegatePresent == true {
            iterableConfig.inAppDelegate = self
        }
        
        DispatchQueue.main.async {
            IterableAPI.initialize(apiKey: apiKey, launchOptions: launchOptions, config: iterableConfig)
        }
    }

    @objc(setEmail:)
    func set(email: String?) {
        ITBInfo()
        IterableAPI.email = email
    }
    
    @objc(getEmail:rejecter:)
    func getEmail(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.email)
    }

    @objc(setUserId:)
    func set(userId: String?) {
        ITBInfo()
        IterableAPI.userId = userId
    }
    
    @objc(getUserId:rejecter:)
    func getUserId(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.userId)
    }
    
    @objc(setUrlHandled:)
    func set(urlHandled: Bool) {
        ITBInfo()
        self.urlHandled = urlHandled
        urlDelegateSemaphore.signal()
    }

    @objc(setInAppShowResponse:)
    func set(inAppShowResponse number: NSNumber) {
        ITBInfo()
        self.inAppShowResponse = InAppShowResponse.from(number: number)
        inAppDelegateSemapohore.signal()
    }

    @objc(disableDeviceForCurrentUser)
    func disableDeviceForCurrentUser() {
        ITBInfo()
        IterableAPI.disableDeviceForCurrentUser()
    }
    
    @objc(disableDeviceForAllUsers)
    func disableDeviceForAllUsers() {
        ITBInfo()
        IterableAPI.disableDeviceForAllUsers()
    }

    @objc(getLastPushPayload:rejecter:)
    func getLastPushPayload(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.lastPushPayload)
    }

    @objc(getAttributionInfo:rejecter:)
    func getAttributionInfo(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.attributionInfo.map(SerializationUtil.encodableToDictionary))
    }

    @objc(setAttributionInfo:)
    func set(attributionInfo dict: [AnyHashable: Any]?) {
        ITBInfo()
        guard let dict = dict else {
            IterableAPI.attributionInfo = nil
            return
        }

        IterableAPI.attributionInfo = SerializationUtil.dictionaryToDecodable(dict: dict)
    }
    
    @objc(trackPushOpenWithPayload:dataFields:)
    func trackPushOpen(payload: [AnyHashable: Any], dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(pushOpen: payload, dataFields: dataFields)
    }

    @objc(trackPushOpenWithCampaignId:templateId:messageId:appAlreadyRunning:dataFields:)
    func trackPushOpen(campaignId: NSNumber,
                       templateId: NSNumber?,
                       messageId: String?,
                       appAlreadyRunning: Bool,
                       dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(pushOpen: campaignId,
                          templateId: templateId,
                          messageId: messageId,
                          appAlreadyRunning: appAlreadyRunning,
                          dataFields: dataFields)
    }
    
    @objc(trackPurchase:items:dataFields:)
    func trackPurchase(total: NSNumber,
                       items: [[AnyHashable: Any]],
                       dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(purchase: total,
                          items: items.compactMap(CommerceItem.from(dict:)),
                          dataFields: dataFields)
    }
    
    @objc(trackInAppOpen:location:)
    func trackInAppOpen(messageId: String,
                        location locationNumber: NSNumber) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }
        IterableAPI.track(inAppOpen: message, location: InAppLocation.from(number: locationNumber))
    }

    @objc(trackInAppClick:location:clickedUrl:)
    func trackInAppClick(messageId: String,
                         location locationNumber: NSNumber,
                         clickedUrl: String) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }
        IterableAPI.track(inAppClick: message, location: InAppLocation.from(number: locationNumber), clickedUrl: clickedUrl)
    }

    @objc(trackInAppClose:location:source:clickedUrl:)
    func trackInAppClose(messageId: String,
                         location locationNumber: NSNumber,
                         source sourceNumber: NSNumber,
                         clickedUrl: String) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }
        if let inAppCloseSource = InAppCloseSource.from(number: sourceNumber) {
            IterableAPI.track(inAppClose: message,
                              location: InAppLocation.from(number: locationNumber),
                              source: inAppCloseSource,
                              clickedUrl: clickedUrl)
        } else {
            IterableAPI.track(inAppClose: message,
                              location: InAppLocation.from(number: locationNumber),
                              clickedUrl: clickedUrl)
        }
    }

    @objc(inAppConsume:location:source:)
    func inAppConsume(messageId: String,
                      location locationNumber: NSNumber,
                      source sourceNumber: NSNumber) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }
        if let inAppDeleteSource = InAppDeleteSource.from(number: sourceNumber) {
            IterableAPI.inAppConsume(message: message,
                              location: InAppLocation.from(number: locationNumber),
                              source: inAppDeleteSource)
        } else {
            IterableAPI.inAppConsume(message: message,
                              location: InAppLocation.from(number: locationNumber))
        }
    }

    @objc(trackEvent:dataFields:)
    func trackEvent(name: String, dataFields: [AnyHashable: Any]?) {
        ITBInfo()
        IterableAPI.track(event: name, dataFields: dataFields)
    }

    @objc(updateUser:mergeNestedObjects:)
    func updateUser(dataFields: [AnyHashable: Any], mergeNestedObjects: Bool) {
        ITBInfo()
        IterableAPI.updateUser(dataFields, mergeNestedObjects: mergeNestedObjects)
    }

    @objc(updateEmail:)
    func updateEmail(email: String) {
        ITBInfo()
        IterableAPI.updateEmail(email, onSuccess: nil, onFailure: nil)
    }
    
    @objc(handleUniversalLink:resolver:rejecter:)
    func handleUniversalLink(link: String, resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.handle(universalLink: URL(string: link)!))
    }
    
    // MARK: InApp Manager methods
    @objc(getInAppMessages:rejecter:)
    func getInAppMessages(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.inAppManager.getMessages().map{ $0.toDict() })
    }

    @objc(getInboxMessages:rejecter:)
    func getInboxMessages(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.inAppManager.getInboxMessages().map{ $0.toDict() })
    }

    @objc(getUnreadInboxMessagesCount:rejecter:)
    func getUnreadInboxMessagesCount(resolver: RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        resolver(IterableAPI.inAppManager.getUnreadInboxMessagesCount())
    }

    @objc(showMessage:consume:resolver:rejecter:)
    func show(messageId: String, consume: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: RCTPromiseRejectBlock) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }

        IterableAPI.inAppManager.show(message: message, consume: consume) { (url) in
            resolver(url.map({$0.absoluteString}))
        }
    }

    @objc(removeMessage:location:source:)
    func remove(messageId: String, location locationNumber: NSNumber, source sourceNumber: NSNumber) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }
        
        if let inAppDeleteSource = InAppDeleteSource.from(number: sourceNumber) {
            IterableAPI.inAppManager.remove(message: message,
                                            location: InAppLocation.from(number: locationNumber),
                                            source: inAppDeleteSource)
        } else {
            IterableAPI.inAppManager.remove(message: message,
                                            location: InAppLocation.from(number: locationNumber))
        }
    }
    
    @objc(setReadForMessage:read:)
    func setRead(for messageId: String, read: Bool) {
        ITBInfo()
        guard let message = IterableAPI.inAppManager.getMessage(withId: messageId) else {
            ITBError("Could not find message with id: \(messageId)")
            return
        }
        IterableAPI.inAppManager.set(read: read, forMessage: message)
    }

    // MARK: Private
    private var shouldEmit = false
    private let _methodQueue = DispatchQueue(label: String(describing: ReactIterableAPI.self))
    
    // Handling url delegate
    private var urlHandled = false
    private var urlDelegateSemaphore = DispatchSemaphore(value: 0)
    
    // Handling in-app delegate
    private var inAppShowResponse = InAppShowResponse.show
    private var inAppDelegateSemapohore = DispatchSemaphore(value: 0)
    
    private func createLaunchOptions() -> [UIApplication.LaunchOptionsKey: Any]? {
        guard let bridge = bridge else {
            return nil
        }

        return ReactIterableAPI.createLaunchOptions(bridgeLaunchOptions: bridge.launchOptions)
    }
    
    private static func createLaunchOptions(bridgeLaunchOptions: [AnyHashable: Any]?) -> [UIApplication.LaunchOptionsKey: Any]? {
        guard let bridgeLaunchOptions = bridgeLaunchOptions,
            let remoteNotification = bridgeLaunchOptions[UIApplication.LaunchOptionsKey.remoteNotification.rawValue] else {
            return nil
        }
        
        var result = [UIApplication.LaunchOptionsKey: Any]()
        result[UIApplication.LaunchOptionsKey.remoteNotification] = remoteNotification
        return result
    }
}

extension ReactIterableAPI: IterableURLDelegate {
    func handle(iterableURL url: URL, inContext context: IterableActionContext) -> Bool {
        ITBInfo()
        guard shouldEmit == true else {
            return false
        }

        let contextDict = ReactIterableAPI.contextToDictionary(context: context)
        sendEvent(withName: EventName.handleUrlCalled.rawValue, body: ["url": url.absoluteString, "context": contextDict])
        let timeoutResult = urlDelegateSemaphore.wait(timeout: .now() + 2.0)

        if timeoutResult == .success {
            ITBInfo("urlHandled: \(urlHandled)")
            return urlHandled
        } else {
            ITBInfo("timed out")
            return false
        }
    }

    private static func contextToDictionary(context: IterableActionContext) -> [AnyHashable: Any] {
        var result = [AnyHashable: Any]()
        let actionDict = actionToDictionary(action: context.action)
        result["action"] = actionDict
        result["source"] = context.source.rawValue
        return result
    }
    
    private static func actionToDictionary(action: IterableAction) -> [AnyHashable: Any] {
        var actionDict = [AnyHashable: Any]()
        actionDict["type"] = action.type
        if let data = action.data {
            actionDict["data"] = data
        }
        if let userInput = action.userInput {
            actionDict["userInput"] = userInput
        }
        return actionDict
    }
}

extension ReactIterableAPI: IterableCustomActionDelegate {
    func handle(iterableCustomAction action: IterableAction, inContext context: IterableActionContext) -> Bool {
        ITBInfo()
        let actionDict = ReactIterableAPI.actionToDictionary(action: action)
        let contextDict = ReactIterableAPI.contextToDictionary(context: context)
        sendEvent(withName: EventName.handleCustomActionCalled.rawValue, body: ["action": actionDict, "context": contextDict])
        return true
    }
}

extension ReactIterableAPI: IterableInAppDelegate {
    func onNew(message: IterableInAppMessage) -> InAppShowResponse {
        ITBInfo()
        guard shouldEmit == true else {
            return .show
        }
        
        let messageDict = message.toDict()
        sendEvent(withName: EventName.handleInAppCalled.rawValue, body: messageDict)
        let timeoutResult = inAppDelegateSemapohore.wait(timeout: .now() + 2.0)

        if timeoutResult == .success {
            ITBInfo("inAppShowResponse: \(inAppShowResponse == .show)")
            return inAppShowResponse
        } else {
            ITBInfo("timed out")
            return .show
        }
    }
}

