//
//  TableViewDataSource.swift
//  PositionIn
//
//  Created by Ruslan Kolchakov on 05/08/16.
//  Copyright (c) 2016 Soluna Labs. All rights reserved.
//

import Foundation

public protocol TableViewDelegate: class {
    func didScrollToTheEndOfTable()
}