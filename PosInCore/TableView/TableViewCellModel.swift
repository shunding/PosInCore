//
//  TableViewCellModel.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation

public protocol TableViewCellModel {
    
}

public struct  TableViewCellInvalidModel: TableViewCellModel {
    public init() {
    }
}

public struct TableViewCellTextModel: TableViewCellModel {
    public let title: String
    public let leftMargin: integer_t
    
    public init(title: String, leftMargin: integer_t = 20) {
        self.title = title
        self.leftMargin = leftMargin
    }
}

public struct TableViewCellAttendEventModel: TableViewCellModel {
    public let attendEvent: Bool
    public let title: String
    public let action: AnyObject?
    
    public init(title: String, attendEvent: Bool, action: AnyObject? = nil) {
        self.title = title
        self.attendEvent = attendEvent
        self.action = action
    }
}

public struct TableViewCellImageTextModel: TableViewCellModel {
    public let title: String
    public let image: String
    public let action: AnyObject?
    public let disabled: Bool?
    
    public init(title: String, imageName: String, action: AnyObject? = nil, disabled: Bool = false) {
        self.title = title
        image = imageName
        self.action = action
        self.disabled = disabled
    }
}

public struct TableViewCellURLTextModel: TableViewCellModel {
    public let title: String
    public let url: URL?
    
    public init(title: String, url: URL?) {
        self.title = title
        self.url = url
    }
}

public struct TableViewCellURLModel: TableViewCellModel {
    public let url: URL?
    public let height: integer_t
    public let placeholderString: String
    
    public init(url: URL?, height: integer_t = 100, placeholderString: String = "") {
        self.url = url
        self.height = height
        self.placeholderString = placeholderString
    }
}
