//
//  CommonTypes.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 16/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation

/**
*  Functor's fmap
*/
infix operator <^> { associativity left } //

public func <^><A, B>(f: (A) -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .none
    }
}

/**
*  Applicative's apply operator
*/
infix operator <*> { associativity left }

public func <*><A, B>(f: ((A) -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .none
}

