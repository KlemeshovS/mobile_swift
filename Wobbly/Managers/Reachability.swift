//
//  Reachability.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 22.02.26.
//
import Foundation
import Network

final class Reachability {
    static func isConnectedToNetwork() -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 1)
        monitor.cancel()
        return isConnected
    }
}
