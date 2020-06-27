import Dispatch
import Foundation
import Models

public final class FakeQueueMetricsProvider: QueueMetricsProvider {
    public func staticQueueMetrics(
        queueSocketAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<StaticQueueMetrics, Error>) -> ()
    ) {
        callbackQueue.async {
            completion(
                Result.success(
                    StaticQueueMetrics(
                        socketAddress: queueSocketAddress,
                        version: "version",
                        startedAt: Date(),
                        hostLogsPath: "~/Library/Logs/ru.avito.emcee.logs/EmceeQueueServer_version/pid_123.wefwe.log"
                    )
                )
            )
        }
    }
    
    public func momentumQueueMetrics(
        queueSocketAddress: SocketAddress,
        callbackQueue: DispatchQueue,
        completion: @escaping (Result<MomentumQueueMetrics, Error>) -> ()
    ) {
        
    }
}