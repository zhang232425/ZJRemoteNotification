//
//  ZJRemoteNotificationDelegate.swift
//  ZJRemoteNotification
//
//  Created by Jercan on 2023/10/20.
//

import Foundation

public protocol ZJRemoteNotificationDelegate: class {
    
    func didReceiveNotificationInside(userInfo: [String: Any]?)
    
    func didReceiveNotificationOutside(userInfo: [String: Any]?)
    
}

public extension ZJRemoteNotificationDelegate {
    
    func didReceiveNotificationInside(userInfo: [String: Any]?) {}
    
    func didReceiveNotificationOutside(userInfo: [String: Any]?) {}
    
}
