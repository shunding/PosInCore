//
//  TableRefreshHeaderView.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import UIKit

/// //! Abstract class used for refresh header views.  TableView will call those methods automatically. Add a target for the UIControlEventValueChanged event to refresh the table view.

open class TableRefreshHeaderView: UIControl {

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    open var refreshState: State  {
        get {
            return currentState
        }
        set {
            setRefreshState(newValue, animated: true)
        }
    }
    
    open var pullAmountToRefresh: CGFloat {
        fatalError("Abstract method – subclasses must implement \(#function).")
    }
    
    fileprivate(set) open var currentPullAmount: CGFloat = 0
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let bottomPadding: CGFloat = 2
        return CGSize(width: size.width, height: pullAmountToRefresh - bottomPadding)
    }
    
    open func setRefreshState(_ state: State, animated: Bool = true) {
        currentState = state
        let animations: () -> Void = {
            if let scrollView = self.scrollView {
                var contentInset = scrollView.contentInset
                contentInset.top = (state == .refreshing) ? self.pullAmountToRefresh : 0
                scrollView.contentInset = contentInset
            }
        }
        let completion: (Bool) -> Void = { _ in
            if self.refreshState == .closing {
                self.setRefreshState(.normal)
            }
        }
        
        if (animated) {
            UIView.animate(withDuration: 0.2, animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
    
    internal(set) open weak var scrollView: UIScrollView?
    
    
    /*
    //! The scroll view that this refresh header is at the top of.
    @property (weak, nonatomic) UIScrollView *scrollView;
    
    //! Called from scrollViewDidScroll: to update the refresh header
    - (void)containingScrollViewDidScroll:(UIScrollView *)scrollView;
    
    //! Called from scrollViewDidEndDragging: to potentially start the refresh
    - (void)containingScrollViewDidEndDragging:(UIScrollView *)scrollView;
    
    */
    
    fileprivate func configure() {
        autoresizingMask = UIViewAutoresizing.flexibleWidth
        clipsToBounds = true
        refreshState = .normal
    }
    
    fileprivate var currentState: State = .normal
    
    public enum State {
        case normal // No refresh is currently happening. The user might have pulled the header down a bit, but not enough to trigger a refresh.
        case readyToRefresh // The user has pulled down the header far enough to trigger a refresh, but has not released yet.
        case refreshing // Refreshing, either after the user pulled to refresh or a refresh was started programmatically.
        case closing // The refresh has just finished and the refresh header is in the process of closing.
    }
}

//MARK: ScrollViewDelegate
extension TableRefreshHeaderView  {
    
    /**
    Called from scrollViewDidScroll: to update the refresh header
    
    - parameter scrollView: scroll view
    */
    internal func containingScrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            // If we were ready to refresh but then dragged back up, cancel the Ready to Refresh state.
            if refreshState == .readyToRefresh && scrollView.contentOffset.y > -pullAmountToRefresh && scrollView.contentOffset.y < 0 {
                setRefreshState(.normal)
                // If we've dragged far enough, put us in the Ready to Refresh state
            } else if refreshState == .normal && scrollView.contentOffset.y <= -pullAmountToRefresh {
                setRefreshState(.readyToRefresh)
            }
        }
        currentPullAmount = max(0, -scrollView.contentOffset.y)
    }
    
    /**
    Called from scrollViewDidEndDragging: to potentially start the refresh
    
    - parameter scrollView: scroll view
    */
    internal func containingScrollViewDidEndDragging(_ scrollView: UIScrollView) {
        // Trigger the action if it was pulled far enough.
        if scrollView.contentOffset.y <= -pullAmountToRefresh && refreshState != .refreshing {
            sendActions(for: UIControlEvents.valueChanged)
        } else {
            currentPullAmount = 0
        }
    }
}
