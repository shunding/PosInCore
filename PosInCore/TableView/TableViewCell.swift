//
//  TableViewCell.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import UIKit

@objc public protocol TableViewChildViewControllerCell {
    var childViewController: UIViewController { get }
}

open class TableViewCell: UITableViewCell {
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        // this prevents the temporary unsatisfiable constraint state that the cell's contentView could
        // enter since it starts off 44pts tall
        self.contentView.autoresizingMask.insert(.flexibleHeight)
    }
    
    open func setModel(_ model: TableViewCellModel) {
        fatalError("\(type(of: self)): You must override \(#function)")
    }
    
    open dynamic class func reuseId() -> String {
        return NSStringFromClass(self)
    }
    
}
