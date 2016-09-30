//
//  KVObserver.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 17/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation


public final class KVObserver<T>: NSObject {
    
    /// Observe closure - observer, old value, new value
    public typealias ObserverClosure = (KVObserver, T?, T?) -> Void
    
    fileprivate(set) public var subject: AnyObject?
    fileprivate(set) public var keyPath: String
    fileprivate(set) public var block: ObserverClosure
    
    public init(subject: AnyObject, keyPath: String, closure: @escaping ObserverClosure) {
        self.subject = subject
        self.keyPath = keyPath
        block = closure
        super.init()
        subject.addObserver(self, forKeyPath: keyPath, options: [.new, .old], context: &KVObserverContext)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &KVObserverContext else {
            return
        } // NSObject does not implement observeValueForKeyPath
        

        let oldValue = change?[NSKeyValueChangeKey.oldKey] as? T
        let newValue = change?[NSKeyValueChangeKey.newKey] as? T
        block(self, oldValue, newValue)
    }
    
    func stopObservation() {
        subject?.removeObserver(self, forKeyPath: keyPath, context: &KVObserverContext)
        subject = nil
    }
    
    deinit {
        stopObservation()
    }
    
    fileprivate var KVObserverContext = 0
}

