//
//  TableViewDataSource.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 19/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation

open class TableViewDataSource: NSObject {
    
    /// Set as the parent view controller of any cells implementing TableViewChildViewControllerCell.
    open weak var parentViewController: UIViewController?
    open weak var tableViewDelegate: TableViewDelegate?
    
    //MARK: Configuration
    
    open func tableView(_ tableView: UITableView, configureCell cell: TableViewCell, forIndexPath indexPath: IndexPath) {
        cell.setModel(self.tableView(tableView, modelForIndexPath: indexPath))
    }
    
    open func tableView(_ tableView: UITableView, configureHeader header: TableViewSectionHeaderFooterView, forSection section: Int) {
        header.position = (0 == section) ? .firstHeader : .header
    }
    
    open func tableView(_ tableView: UITableView, configureFooter footer: TableViewSectionHeaderFooterView, forSection section: Int) {
        footer.position = (tableView.numberOfSections - 1 == section) ? .lastFooter : .footer
    }
    
    
    //MARK: Reuse Identifiers
    
    @objc open func tableView(_ tableView: UITableView, reuseIdentifierForIndexPath indexPath: IndexPath) -> String {
        fatalError("\(type(of: self)): You must override \(#function)")
    }
    
    @objc open func tableView(_ tableView: UITableView, reuseIdentifierForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    @objc open func tableView(_ tableView: UITableView, reuseIdentifierForFooterInSection section: Int) -> String? {
        return nil
    }
    
    //MARK: Models
    
    open func tableView(_ tableView: UITableView, modelForIndexPath indexPath: IndexPath) -> TableViewCellModel {
        fatalError("\(type(of: self)): You must override \(#function)")
    }
    
    //MARK: register views
    
    @objc open func configureTable(_ tableView: UITableView) {
        for reuseId in nibCellsId() {
            tableView.register(UINib(nibName: reuseId, bundle: nil), forCellReuseIdentifier: reuseId)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    open func nibCellsId() -> [String] {
        return []
    }
    
    
}

extension TableViewDataSource: UITableViewDataSource {
    
    @objc open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError("\(type(of: self)): You must override \(#function)")
    }
    
    @objc open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseId = self.tableView(tableView, reuseIdentifierForIndexPath: indexPath)
        let cell = tableView .dequeueReusableCell(withIdentifier: reuseId) as! TableViewCell
        self.tableView(tableView, configureCell: cell, forIndexPath: indexPath)
        return cell
    }
    
    @objc open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let reuseID = self.tableView(tableView, reuseIdentifierForHeaderInSection: section),
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseID) as? TableViewSectionHeaderFooterView {
                self.tableView(tableView, configureHeader: header, forSection: section)
                return header
        }
        return nil
    }	
    
    @objc open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let reuseID = self.tableView(tableView, reuseIdentifierForFooterInSection: section),
            let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseID) as? TableViewSectionHeaderFooterView {
                self.tableView(tableView, configureFooter: footer, forSection: section)
                return footer
        }
        return nil
    }
    
}

extension TableViewDataSource: UITableViewDelegate {
    
    @objc open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (tableView as? TableView != nil) {
            return UITableViewAutomaticDimension
        } else {
            fatalError("This can only be the delegate of a TableView")
        }
    }
    
    @objc open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    @objc open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}

//MARK: ChildViewController support
extension TableViewDataSource {
    
    @objc(tableView:willDisplayCell:forRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == tableView.numberOfRows(inSection: (indexPath as NSIndexPath).section) - 1 {
            tableViewDelegate?.didScrollToTheEndOfTable()
        }
        
        guard cell.conforms(to: TableViewChildViewControllerCell.self) else  {
            return
        }
        guard let parentController = parentViewController else {
            fatalError("Must have a parent view controller to support cell \(cell)")
        }
        let viewControllerCell = cell as! TableViewChildViewControllerCell
        let childController = viewControllerCell.childViewController
        childController.willMove(toParentViewController: parentController)
        parentController.addChildViewController(childController)
        childController.didMove(toParentViewController: parentController)
    }
    
    @objc(tableView:didEndDisplayingCell:forRowAtIndexPath:)
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.conforms(to: TableViewChildViewControllerCell.self) {
            guard let _ = parentViewController else {
                fatalError("Must have a parent view controller to support cell \(cell)")
            }
            let viewControllerCell = cell as! TableViewChildViewControllerCell
            let childController = viewControllerCell.childViewController
            childController.willMove(toParentViewController: nil)
            childController.removeFromParentViewController()
        }
    }
    
}

//MARK: UIScrollViewDelegate
extension TableViewDataSource {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let tableView = scrollView as? TableView {
            tableView.refreshHeaderView?.containingScrollViewDidScroll(tableView)
        } else {
            fatalError("his can only be the delegate of a TableView")
        }
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let tableView = scrollView as? TableView {
            tableView.refreshHeaderView?.containingScrollViewDidEndDragging(tableView)
        } else {
            fatalError("his can only be the delegate of a TableView")
        }
    }
}
