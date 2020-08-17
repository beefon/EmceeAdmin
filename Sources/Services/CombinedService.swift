import Foundation
import SocketModels
import Types

public final class CombinedService: Service, CustomStringConvertible {
    private let services: [Service]
    
    public init(services: [Service]) {
        self.services = services
    }
    
    public var id: String {
        services.map { $0.id }.joined()
    }
    
    public var name: String {
        "Combined Service: " + services.map { $0.name }.joined(separator: ", ")
    }
    
    public var socketAddress: SocketAddress {
        SocketAddress(host: "", port: 0)
    }
    
    public var version: String {
        services.map { $0.version }.joined(separator: ", ")
    }
    
    public var serviceWorkers: [ServiceWorker] {
        var similarlyNamedServiceWorkers = MapWithCollection<String, ServiceWorker>()
        
        for service in services {
            for worker in service.serviceWorkers {
                similarlyNamedServiceWorkers.append(key: worker.name, element: worker)
            }
        }
        
        return similarlyNamedServiceWorkers.asDictionary.map { (name: String, serviceWorkers: [ServiceWorker]) -> CombinedServiceWorker in
            CombinedServiceWorker(serviceWorkers: serviceWorkers, name: name)
        }
    }
    
    public func updateWorkers() {
        let queue = DispatchQueue(label: "updateQueue", qos: .default, attributes: .concurrent)
        
        let group = DispatchGroup()
        
        for service in services {
            group.enter()
            queue.async {
                defer {
                    group.leave()
                }
                service.updateWorkers()
            }
        }
        
        group.wait()
    }
    
    public var description: String { "<\(id) \(name) \(serviceWorkers)" }
}

final class CombinedServiceWorker: ServiceWorker, CustomStringConvertible {
    let serviceWorkers: [ServiceWorker]
    let name: String
    
    init(serviceWorkers: [ServiceWorker], name: String) {
        self.serviceWorkers = serviceWorkers
        self.name = name
    }
    
    var id: String {
        serviceWorkers.map { $0.id }.joined()
    }
    
    var actions: [ServiceWorkerAction] {
        serviceWorkers.flatMap { $0.actions }
    }
    
    var states: [ServiceWorkerState] {
        serviceWorkers.flatMap { $0.states }
    }
    
    var description: String { "<\(name) states=\(states) actions=\(actions)" }
}
