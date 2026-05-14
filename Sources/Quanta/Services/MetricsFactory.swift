import Foundation
import Metrics
import SwiftBoxMetrics

/// Local replacement for `StatsDMetricsFactory` (which is `internal` in SwiftBox 1.0.1).
/// Wraps SwiftBox StatsD handlers behind swift-metrics' `MetricsFactory` API.
final class QuantaStatsDMetricsFactory: MetricsFactory {
    private let baseMetricPath: String
    private let handlerFactory: (String) -> MetricsHandler

    init(baseMetricPath: String, handlerFactory: @escaping (String) -> MetricsHandler) {
        self.baseMetricPath = baseMetricPath
        self.handlerFactory = handlerFactory
    }

    private func path(for label: String) -> String {
        "\(baseMetricPath).\(label)"
    }

    func makeCounter(label: String, dimensions _: [(String, String)]) -> CounterHandler {
        handlerFactory(path(for: label))
    }

    func makeRecorder(label: String, dimensions _: [(String, String)], aggregate _: Bool) -> RecorderHandler {
        handlerFactory(path(for: label))
    }

    func makeTimer(label: String, dimensions _: [(String, String)]) -> TimerHandler {
        handlerFactory(path(for: label))
    }

    func makeMeter(label: String, dimensions _: [(String, String)]) -> MeterHandler {
        QuantaMeterHandler()
    }

    func destroyCounter(_: CounterHandler) {}
    func destroyRecorder(_: RecorderHandler) {}
    func destroyTimer(_: TimerHandler) {}
    func destroyMeter(_: MeterHandler) {}
}

private final class QuantaMeterHandler: MeterHandler {
    func set(_: Int64) {}
    func set(_: Double) {}
    func increment(by _: Double) {}
    func decrement(by _: Double) {}
}
