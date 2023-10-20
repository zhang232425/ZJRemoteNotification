//
//  ZJRemoteNotification.swift
//  ZJRemoteNotification
//
//  Created by Jercan on 2023/10/20.
//

import UserNotifications

public final class ZJRemoteNotification: NSObject {
    
    public static let shared = ZJRemoteNotification()
    
    public private(set) var deviceToken: String?
    
    private var queue: DispatchQueue?
    
    private var delegates = [DelegateNode]()
    
    private var isActive = false {
        didSet { if isActive { postCacheNotifications() } }
    }
    
    public var badgeNumber: Int = 0 {
        didSet { UIApplication.shared.applicationIconBadgeNumber = badgeNumber }
    }
    
    private var caches: [CacheNotification]?
    
    private override init() {
        queue = .init(label: "as-remote-notification-queue-" + NSUUID().uuidString, target: queue)
    }
    
    deinit {
        removeAllDelegate()
    }
    
}

public extension ZJRemoteNotification {
    
    final func getAuthorizationStatus(callBack: ((Bool) -> Void)?) {
        
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().getNotificationSettings { (setting) in
                
                DispatchQueue.main.async {
                    
                    if setting.authorizationStatus == .authorized {
                        callBack?(true)
                    } else {
                        callBack?(false)
                    }
                    
                }
                
            }
            
        } else {
            
            let setting = UIApplication.shared.currentUserNotificationSettings
            
            if let types = setting?.types, types.contains([.badge, .sound, .alert]) {
                callBack?(true)
            }
            
            callBack?(false)
            
        }
        
    }
    
    final func registerRemoteNotification() {
    
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in }
            
        } else {
            
            let setting = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            
            UIApplication.shared.registerUserNotificationSettings(setting)
            
        }
        
        UIApplication.shared.registerForRemoteNotifications()
        
    }

    final func activate() {
        if !isActive { isActive = true }
    }
    
    final func addDelegate(_ delegate: ZJRemoteNotificationDelegate) {
        safe { delegates.append(.init(delegate: delegate)) }
    }
    
    final func removeDelegate(_ delegate: ZJRemoteNotificationDelegate) {
        
        safe {
            
            delegates.removeAll {
                
                if let aDelegate = $0.delegate, aDelegate.isEqual(delegate) {
                    return true
                }
                
                return false
                
            }
            
        }
        
    }
    
    final func removeAllDelegate() {
        safe { delegates.removeAll() }
    }
    
}

public extension ZJRemoteNotification {
    
    final func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    final func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                           fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        postNotification(userInfo as? [String: Any], isInside: application.applicationState == .active)
        
        completionHandler(.newData)
        
    }

    final func application(_ deviceToken: String) {
        self.deviceToken = deviceToken
    }
    
}

@available(iOS 10, *)
extension ZJRemoteNotification: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo as? [String: Any]
        
        postNotification(userInfo, isInside: true)
        
        completionHandler([])
        
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo as? [String: Any]
        
        postNotification(userInfo, isInside: false)
        
        completionHandler()
        
    }
    
}


private extension ZJRemoteNotification {

    final func postNotification(_ userInfo: [String: Any]?, isInside: Bool) {
        
        safe {
            
            if isActive {
                
                delegates.removeAll { ($0.delegate as? ZJRemoteNotificationDelegate) == nil }
                
                delegates.forEach {
                    
                    if let delegate = $0.delegate as? ZJRemoteNotificationDelegate {
                        
                        if isInside {
                            executeInMain { delegate.didReceiveNotificationInside(userInfo: userInfo) }
                        } else {
                            executeInMain { delegate.didReceiveNotificationOutside(userInfo: userInfo) }
                        }
                        
                    }
                    
                }
                
            } else {
                
                cacheNotification(userInfo, isInside: isInside)
                
            }
            
        }
        
    }
    
    final func postCacheNotifications() {
        if let notifications = caches, !notifications.isEmpty {
            notifications.forEach { postNotification($0.userInfo, isInside: $0.isInside) }
        }
        caches = nil
    }
    
    final func cacheNotification(_ userInfo: [String: Any]?, isInside: Bool) {
        if caches == nil { caches = [] }
        caches?.append(.init(userInfo: userInfo, isInside: isInside))
    }
    
    final func executeInMain(execute: @escaping () -> Void) {
        DispatchQueue.main.async(execute: execute)
    }
    
    final func safe(execute: () -> Void) {
        queue?.sync(execute: execute)
    }
    
}

private class DelegateNode {
    
    weak var delegate: AnyObject?
    
    init(delegate: AnyObject?) {
        self.delegate = delegate
    }
    
}

private struct CacheNotification {
    
    let userInfo: [String: Any]?
    
    let isInside: Bool
    
}
