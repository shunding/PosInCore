//
//  NetworkActivityIndicatorManager.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 16/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation

class NetworkActivityIndicatorManager: NSObject {
    fileprivate var activityCount: Int = 0
    fileprivate var activityIndicatorVisibilityTimer: Timer?
    
    var isNetworkActivityIndicatorVisible: Bool {
        return activityCount > 0
    }
    
    func increment() {
        objc_sync_enter(self)
        activityCount += 1
        objc_sync_exit(self)
        
        DispatchQueue.main.async {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    func decrement() {
        objc_sync_enter(self)
        activityCount = max(activityCount - 1, 0)
        objc_sync_exit(self)
        
        DispatchQueue.main.async {
            self.updateNetworkActivityIndicatorVisibilityDelayed()
        }
    }
    
    fileprivate func updateNetworkActivityIndicatorVisibilityDelayed() {
        // Delay hiding of activity indicator for a short interval, to avoid flickering
        if (isNetworkActivityIndicatorVisible) {
            DispatchQueue.main.async {
                self.updateNetworkActivityIndicatorVisibility()
            }
        } else {
            activityIndicatorVisibilityTimer?.invalidate()
            activityIndicatorVisibilityTimer = Timer(timeInterval: 0.2, target: self, selector: #selector(NetworkActivityIndicatorManager.updateNetworkActivityIndicatorVisibility), userInfo: nil, repeats: false)
            activityIndicatorVisibilityTimer!.tolerance = 0.2
            RunLoop.main.add(activityIndicatorVisibilityTimer!, forMode: RunLoopMode.commonModes)
        }
    }
    
    func updateNetworkActivityIndicatorVisibility() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = isNetworkActivityIndicatorVisible
    }
}
