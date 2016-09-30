//
//  TableViewSectionHeaderFooterLabelView.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import UIKit

open class TableViewSectionHeaderFooterLabelView : TableViewSectionHeaderFooterView {
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        installLabel()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        installLabel()
    }
    
    fileprivate func installLabel() {
        label = UILabel()
        label.numberOfLines = 0
        contentLayoutGuideView.addSubViewOnEntireSize(label)
    }

    fileprivate(set) open var label: UILabel!
    
    open var text: String? {
        set {
            label.text = newValue
        }
        get {
            return label.text
        }
    }
    
}
