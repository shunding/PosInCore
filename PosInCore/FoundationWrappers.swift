//
//  FoundationWrappers.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 16/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation

/**
Objective-C synchronised

- parameter lock:    lock object
- parameter closure: closure
*/
public func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

/**
GCD dispatch after wrapper

- parameter delay:   delay in seconds
- parameter queue:   dispatch queue
- parameter closure: block
*/
public func dispatch_delay(_ delay:Double, queue:DispatchQueue, closure:@escaping ()->()) {
    queue.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

/**
GCD dispatch after wrapper. Using main queue

- parameter delay:   delay in seconds
- parameter closure: block
*/
public func dispatch_delay(_ delay:Double, closure:@escaping ()->()) {
    dispatch_delay(delay, queue: DispatchQueue.main, closure: closure)
}


extension Array {
    /**
    Safe index subscript
    
    - parameter safe: index
    
    - returns: optional object
    */
    internal subscript (safe index: Int) -> Element? {
        return self.indices ~= index
            ? self[index]
            : nil
    }
}

public  extension NSDictionary {
    /**
    Returns json representation
    
    - returns: JSON string
    */
    public func jsonString() -> String {
        let invalidJSON = ""
        guard JSONSerialization.isValidJSONObject(self) == true else {
            return invalidJSON
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions())
            return (NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? ?? invalidJSON) as String
        } catch {
            return invalidJSON
        }
    }
    
}

extension Dictionary {
    mutating func update(_ other: Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

public extension UIView {
    /**
    Add subview to the reciever and install constraints to fill parent size
    
    - parameter contentView: subview
    */
    public func addSubViewOnEntireSize(_ contentView: UIView) {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let views = [ "contentView": contentView ]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        setNeedsLayout()        
    }
}
