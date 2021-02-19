import AppKit
import EasyAppKit
import Services
import Types

public final class ServiceWorkerDetailsTableController: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {
    public var services: [Service] = [] {
        didSet {
            updateTableViewSorting()
        }
    }
    
    private weak var tableView: NSTableView?
    
    public override init() {}
    
    public func prepare(tableView: NSTableView) {
        for column in tableView.tableColumns {
            tableView.removeTableColumn(column)
        }
        
        do {
            let workerIdColumn = NSTableColumn()
            workerIdColumn.identifier = ServiceWorkerDetailsTableController.workerNameColumnId
            tableView.addTableColumn(workerIdColumn)
        }

        var addedColumnIds = Set<NSUserInterfaceItemIdentifier>()
        for serviceWorker in sortedWorkers {
            for combinedState in serviceWorker.combinedStates {
                let columnId = NSUserInterfaceItemIdentifier(combinedState.id)
                guard !addedColumnIds.contains(columnId) else { continue }
                addedColumnIds.insert(columnId)
                let column = NSTableColumn()
                column.identifier = columnId
                column.title = combinedState.state.name + " [\(combinedState.service.name)]"
                column.width = 175
                column.minWidth = 175
                tableView.addTableColumn(column)
            }
        }
        
        tableView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        tableView.usesAlternatingRowBackgroundColors = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40
        tableView.allowsMultipleSelection = true
        
        self.tableView = tableView
        
        tableView.menu = NSMenu.create(delegate: self)
        
        updateTableViewSorting()
    }
    
    struct SharedWorker {
        let commonName: String
        let serviceWorkers: [(service: Service, worker: ServiceWorker)]
        
        var combinedStates: [(id: String, service: Service, serviceWorker: ServiceWorker, state: ServiceWorkerState)] {
            serviceWorkers.flatMap { serviceOfWorker in
                serviceOfWorker.worker.states.map { state in
                    (id: serviceOfWorker.service.name + state.id, service: serviceOfWorker.service, serviceWorker: serviceOfWorker.worker, state: state)
                }
            }
        }
        var combinedActions: [(id: String, service: Service, serviceWorker: ServiceWorker, action: ServiceWorkerAction)] {
            serviceWorkers.flatMap { serviceOfWorker in
                serviceOfWorker.worker.actions.map { action in
                    (id: serviceOfWorker.service.name + action.id, service: serviceOfWorker.service, serviceWorker: serviceOfWorker.worker, action: action)
                }
            }
        }
    }
    
    private func createServiceWorkerList() -> [SharedWorker] {
        var similarlyNamedServiceWorkers = MapWithCollection<String, (service: Service, worker: ServiceWorker)>()
        for service in services {
            for worker in service.serviceWorkers {
                similarlyNamedServiceWorkers.append(key: worker.name, element: (service: service, worker: worker))
            }
        }
        
        return similarlyNamedServiceWorkers.asDictionary.map { (name: String, serviceWorkers: [(service: Service, worker: ServiceWorker)]) -> SharedWorker in
            SharedWorker(commonName: name, serviceWorkers: serviceWorkers)
        }
    }
        
    private func createSortedWorkerList() -> [SharedWorker] {
        let serviceWorkers = createServiceWorkerList()
        
        if sortingColumnId == ServiceWorkerDetailsTableController.workerNameColumnId {
            return serviceWorkers.sorted { (left, right) -> Bool in left.commonName < right.commonName }
        }
        
        return serviceWorkers.sorted { left, right -> Bool in
            let leftStatus = left.combinedStates.first { (id: String, service: Service, serviceWorker: ServiceWorker, state: ServiceWorkerState) -> Bool in id == sortingColumnId.rawValue }?.state.isPositive ?? false
            let rightStatus = right.combinedStates.first { (id: String, service: Service, serviceWorker: ServiceWorker, state: ServiceWorkerState) -> Bool in id == sortingColumnId.rawValue }?.state.isPositive ?? false
            
            if leftStatus == rightStatus {
                return left.commonName < right.commonName
            } else {
                return leftStatus.comparableInt < rightStatus.comparableInt
            }
        }
    }
    
    private lazy var sortedWorkers: [SharedWorker] = createSortedWorkerList()
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        sortedWorkers.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        
        let serviceWorker = sortedWorkers[row]
        
        if tableColumn.identifier == ServiceWorkerDetailsTableController.workerNameColumnId {
            return WorkerNameCellView(text: serviceWorker.commonName)
        } else {
            guard let combinedState = serviceWorker.combinedStates.first(where: { $0.id == tableColumn.identifier.rawValue } ) else {
                return NSView()
            }
            
            return StatusIndicatorCellView(
                backgroundColor: combinedState.service.color.withAlphaComponent(0.15),
                indicatorColor: combinedState.state.isPositive ? greenColor : redColor,
                text: combinedState.state.status
            )
        }
    }
    
    public func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        sortingColumnId = tableColumn.identifier
    }
    
    private let blueColor = NSColor(calibratedRed: 0.105, green: 0.678, blue: 0.972, alpha: 1)
    private let brownColor = NSColor(calibratedRed: 0.675, green: 0.557, blue: 0.290, alpha: 1)
    private let greenColor = NSColor(calibratedRed: 0.196, green: 0.843, blue: 0.294, alpha: 1)
    private let redColor = NSColor(calibratedRed: 1.000, green: 0.164, blue: 0.408, alpha: 1)
    private let yellowColor = NSColor(calibratedRed: 1.0, green: 0.839, blue: 0, alpha: 1)
    
    private static let workerNameColumnId = NSUserInterfaceItemIdentifier("WorkerName")
    
    private var sortingColumnId: NSUserInterfaceItemIdentifier = ServiceWorkerDetailsTableController.workerNameColumnId {
        didSet {
            updateTableViewSorting()
        }
    }
    
    private func updateTableViewSorting() {
        sortedWorkers = createSortedWorkerList()
        guard let tableView = tableView else { return }
        tableView.reloadData()
    }
    
    // MARK: NSMenuDelegate
    
    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        guard let tableView = tableView else { return menu.cancelTrackingWithoutAnimation() }
        
        let clickedRow = tableView.clickedRow
        let clickedColumn = tableView.clickedColumn
        
        guard clickedRow >= 0, clickedColumn >= 0 else { return menu.cancelTrackingWithoutAnimation() }
        
        let selectedWorkers = tableView.selectedRowIndexes.map { sortedWorkers[$0] }
        let actionGroups = selectedWorkers
            .flatMap(\.combinedActions)
            .groupBy(grouping: \.action.id)
            .map(\.value)
        
        for actionGroup in actionGroups {
            let title = actionGroup.map { "\($0.service.name): \($0.action.name)" }.joined(separator: "\n")
            let action = { [weak self] in
                for combinedAction in actionGroup {
                    combinedAction.service.execute(action: combinedAction.action, serviceWorker: combinedAction.serviceWorker)
                    combinedAction.service.updateWorkers()
                }
                self?.updateTableViewSorting()
            }
            menu.addItem(
                NSMenuItem.with(
                    title: title,
                    action: action
                )
            )
        }
    }
}

extension Bool {
    var comparableInt: Int { self == true ? 1 : 0 }
}

extension Collection {
    func groupBy<Key: Hashable>(grouping: (Element) throws -> (Key)) rethrows -> [Key: [Element]] {
        return try Dictionary(grouping: self, by: grouping)
    }
}
