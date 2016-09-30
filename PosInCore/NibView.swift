//
//  NibView.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 20/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import UIKit

open class NibView: UIView {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        loadContentView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        loadContentView()
    }
    
    
    open var nibName: String {
        return NSStringFromClass(type(of: self))
    }
    
    fileprivate func loadContentView() {
        let bundle = Bundle(for: type(of: self))
        bundle.loadNibNamed(nibName, owner: self, options: nil)
        if let contentView = contentView {
            addSubViewOnEntireSize(contentView)
        }
    }
    
    @IBOutlet fileprivate var contentView: UIView!

}
