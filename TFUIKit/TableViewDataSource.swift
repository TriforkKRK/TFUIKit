//
//  TableViewDataSource.swift
//  TFUIKit
//
//  Created by Wojciech Nagrodzki on 14/10/2017.
//  Copyright © 2017 Wojciech Nagrodzki. All rights reserved.
//

import Foundation
import CoreData

public protocol TableViewCellConfigurator {
    associatedtype Cell: UITableViewCell
    associatedtype Object: NSFetchRequestResult
    func configure(_ cell: Cell, for object: Object)
}

/// - note: Does not support working with multiple sections.
/// - todo: Implement `UITableViewDataSource` and `NSFetchedResultsControllerDelegate` via extensions once it is supported.
public class TableViewDataSource<CellConfigurator: TableViewCellConfigurator>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    private let tableView: UITableView
    private let cellIdentifier: String
    private let cellConfigurator: CellConfigurator
    private let fetchedResultsController: NSFetchedResultsController<CellConfigurator.Object>
    
    public init(tableView: UITableView, cellIdentifier: String, cellConfigurator: CellConfigurator, fetchedResultsController: NSFetchedResultsController<CellConfigurator.Object>) {
        self.tableView = tableView
        self.cellIdentifier = cellIdentifier
        self.cellConfigurator = cellConfigurator
        self.fetchedResultsController = fetchedResultsController
        super.init()
        tableView.dataSource = self
        fetchedResultsController.delegate = self
    }
    
    // MARK: UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueReusableCell(for: indexPath)
        let object = fetchedResultsController.object(at: indexPath)
        cellConfigurator.configure(cell, for: object)
        return cell
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sections = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(sections, with: .automatic)
        case .delete:
            tableView.deleteSections(sections, with: .automatic)
        case .move, .update:
            fatalError()
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            let cell = cellForRow(at: indexPath!)
            let object = fetchedResultsController.object(at: indexPath!)
            cellConfigurator.configure(cell, for: object)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

private extension TableViewDataSource {
    
    func dequeueReusableCell(for indexPath: IndexPath) -> CellConfigurator.Cell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CellConfigurator.Cell else {
            fatalError("Invalid cell type")
        }
        return cell
    }
    
    func cellForRow(at indexPath: IndexPath) -> CellConfigurator.Cell {
        guard let cell = tableView.cellForRow(at: indexPath) as? CellConfigurator.Cell else {
            fatalError("Invalid cell type")
        }
        return cell
    }
}
