//
//  DataTransforms.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 28/08/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation
import ObjectMapper

open class ListTransform<ItemTransform: TransformType>: TransformType {
    public typealias Object = [ItemTransform.Object]
    public typealias JSON = [ItemTransform.JSON]
    
    public init(itemTransform: ItemTransform) {
        self.itemTransform =  itemTransform
    }
    
    let itemTransform: ItemTransform
    
    open func transformFromJSON(_ value: Any?) -> Object? {
        if let values = value as? [AnyObject] {
            return values.reduce(Object()) { result, item in
                if let v = itemTransform.transformFromJSON(item) {
                    return result + [v]
                }
                return result
            }
        }
        return nil
    }
    
    open func transformToJSON(_ value: Object?) -> JSON? {
        if let values = value {
            return values.reduce( JSON() ) { result, item in
                if let v = itemTransform.transformToJSON(item) {
                    return result + [v]
                }
                return result
            }
        }
        return nil
    }
}

open class RelativeURLTransform: TransformType {
    public init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    open func transformFromJSON(_ value: Any?) -> URL? {
        if let URLString = value as? String {
            return URL(string: URLString, relativeTo: baseURL)
        }
        return nil
    }
    
    open func transformToJSON(_ value: URL?) -> String? {
        if let URL = value,
            let components = URLComponents(url: URL, resolvingAgainstBaseURL: true) {
                let result = components.url(relativeTo: baseURL)?.relativePath
                print(result)
                return result
                
        }
        return nil
    }
    
    fileprivate let baseURL: URL
}

