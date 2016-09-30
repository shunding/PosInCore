//
//  TableView.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import UIKit

open class TableView: UITableView {
    
    public override init(frame: CGRect, style: UITableViewStyle) {
        state = .loading
        super.init(frame: frame, style: style)
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        state = .loading
        super.init(coder: aDecoder)
        configure()
    }
    
    open var refreshHeaderView: TableRefreshHeaderView? {
        set {
            if let oldRefreshHeaderView = refreshHeader {
                oldRefreshHeaderView.removeFromSuperview()
            }
            if let newRefreshHeaderView = newValue {
                addSubview(newRefreshHeaderView)
                sendSubview(toBack: newRefreshHeaderView)
                showsVerticalScrollIndicator = true
                newRefreshHeaderView.scrollView = self
            }
            refreshHeader = newValue
        }
        get {
            return refreshHeader
        }
    }
    
    open var state: State {
        willSet {
            var refreshState: TableRefreshHeaderView.State = .normal
            if state == .refreshing {
                refreshState = .refreshing
            } else if let refreshHeader = refreshHeaderView , refreshHeader.refreshState == .refreshing {
                refreshState = .closing
            }
            refreshHeader?.refreshState = refreshState
        }
    }
    
    public enum State {
        case loading // Initial loading state. Pull to refresh header will not show.
        case loaded /// Normal state. Nothing is currently loading.
        case refreshing /// Refreshing after a pull-to-refresh. The refreshHeaderView will be showing.
        case errored /// Network request errored.
    }
    
    fileprivate func configure() {
        // Make sure you set estimated row height, or UITableViewAutomaticDimension won't work.
        estimatedRowHeight = 44.0
    }
    
    fileprivate var refreshHeader: TableRefreshHeaderView?
    
    //MARK: RefreshHeaderView
    open override func layoutSubviews() {
        super.layoutSubviews()
    
    // Put self.refreshHeaderView above the origin of self.frame. We set self.refreshHeaderView.frame.size to be equal to self.frame.size to gurantee that you won't be able to see beyond the top of the header view.
    // self.refreshHeaderView should draw it's content at the bottom of its frame.
        refreshHeader?.frame = CGRect(x: 0, y: -bounds.height, width: bounds.size.width, height: bounds.size.height)
    }
  
}
