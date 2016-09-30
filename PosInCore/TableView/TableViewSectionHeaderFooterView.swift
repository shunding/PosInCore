//
//  TableViewSectionHeaderFooterView.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import UIKit

open class TableViewSectionHeaderFooterView: UITableViewHeaderFooterView {
    
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        installContentLayoutGuide()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        installContentLayoutGuide()
    }
    
    /// Position of this header/footer in the table view
    internal(set) open var position: Position = .undefined {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    /**
    You should add subviews to this view, and pin those views to it using Auto Layout constraints.
    
    This view is inset by contentLayoutGuideInsets + _systemContentLayoutGuideInsets. contentLayoutGuideInsets can be overridden by subclasses.
    */
    fileprivate(set) open var contentLayoutGuideView: UIView! = nil
    fileprivate var contentLayoutGuideWidthConstraint: NSLayoutConstraint! = nil
    fileprivate var contentLayoutGuideConstraints: [NSLayoutConstraint] = []
    
    fileprivate func installContentLayoutGuide(){
        contentLayoutGuideView = UIView()
        contentLayoutGuideView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentLayoutGuideView)
        // For some reason, doing |-left-[_contentLayoutGuideView]-(right@999)-| doesn't work when the header's label is more than one line long, so we have to do this as a width.
        contentLayoutGuideWidthConstraint = NSLayoutConstraint(item: contentLayoutGuideView, attribute: .width, relatedBy: .equal,
                                                               toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 1.0)
        // Allow the width constraint to be broken by subviews that are constrained with additional non-zero padding
        contentLayoutGuideWidthConstraint.priority = /*UILayoutPriorityRequired*/ 1000 - 1
        contentView.addConstraint(contentLayoutGuideWidthConstraint)        
    }
    
    open var contentLayoutGuideInsets: UIEdgeInsets {
        let (top, bottom): (CGFloat, CGFloat) = {
            switch self.position {
            case .header, .firstHeader:
                return (self.kLargeVerticalPadding, self.kSmallVerticalPadding)
            case .footer, .lastFooter:
                return (self.kSmallVerticalPadding, self.kLargeVerticalPadding)
            default:
                fatalError("undefined position")
            }
        }()
        return UIEdgeInsets(top: top, left: kDefaultHorizontalPadding, bottom: bottom, right: kDefaultHorizontalPadding)
    }
    
    open override func layoutSubviews() {
        let edgeInsets = totalInsents()
        contentLayoutGuideWidthConstraint.constant = max(bounds.width - edgeInsets.left - edgeInsets.right, 0)
        super.layoutSubviews()
    }
    
    open override func updateConstraints() {

        contentView.removeConstraints(contentLayoutGuideConstraints)

        let vfl: String = {
            switch self.position {
            case .header, .firstHeader:
                return "V:|-(>=top@priorityNotRequired)-[contentLayoutGuideView]-bottom-|"
            case .footer, .lastFooter:
                return "V:|-top-[contentLayoutGuideView]-(>=bottom@priorityNotRequired)-|"
            default:
                fatalError("undefined position")
            }
        }()
        let metrics: [String: AnyObject] = {
           let edgeInsets = self.totalInsents()
            return [
                "left": edgeInsets.left as AnyObject,
                "right": edgeInsets.right as AnyObject,
                "top": edgeInsets.top as AnyObject,
                "bottom": edgeInsets.bottom as AnyObject,
                "priorityNotRequired": (1000 - 1) as AnyObject
            ]
        }()
        let views = [ "contentLayoutGuideView" : contentLayoutGuideView ]

        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: vfl, options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views)
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[_contentLayoutGuideView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views) 

        contentView.addConstraints(verticalConstraints + horizontalConstraints)
        super.updateConstraints()
    }
    
    fileprivate func totalInsents() -> UIEdgeInsets {
        // When you don't specify section footers, they are 17.5pt tall by default. This makes up the
        // inter-section padding in grouped table views. Since the first section header doesn't have a
        // (previous section's) footer before it, the first section header's height is made
        // 17.5pts taller by the system when tableView:heightForHeaderInSection: isn't implemented.
        // This code emulates the system behavior. A similar thing happens for footers.
        let extraTopPadding = (position == .firstHeader) ? kFirstLastSectionExtraVerticalPadding : 0
        let extraBottomPadding = (position == .lastFooter) ? kFirstLastSectionExtraVerticalPadding : 0
        var edgeInsets = contentLayoutGuideInsets
        edgeInsets.top += extraTopPadding
        edgeInsets.bottom += extraBottomPadding
        return edgeInsets
    }
    
    public enum Position {
        case undefined
        case header // Any header but the first one in the table view
        case firstHeader // The first header in the table view
        case footer // Any footer but the last on one in the table view
        case lastFooter // The last footer in the table view
    }
    
    fileprivate let kSmallVerticalPadding: CGFloat = 7;
    fileprivate let kLargeVerticalPadding: CGFloat = 12;
    fileprivate let kDefaultHorizontalPadding: CGFloat = 15;
    fileprivate let kFirstLastSectionExtraVerticalPadding: CGFloat = 17.5;

}
