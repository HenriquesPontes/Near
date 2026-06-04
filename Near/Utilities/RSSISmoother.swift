import Foundation
import Combine

/// A utility class that applies an Exponential Moving Average (EMA) to raw RSSI values.
/// This prevents erratic UI jumping caused by Bluetooth signal interference.
class RSSISmoother: ObservableObject {
    @Published var smoothedRSSI: Double = -100.0
    private var isInitialized = false
    private let alpha: Double // Smoothing factor (0.0 < alpha <= 1.0)

    /// - Parameter alpha: The weight of the most recent value. A lower alpha means smoother but slower response.
    init(alpha: Double = 0.15) {
        self.alpha = alpha
    }

    /// Add a new raw RSSI reading to update the smoothed value.
    func add(rssi: Int) {
        let currentRSSI = Double(rssi)
        if !isInitialized {
            smoothedRSSI = currentRSSI
            isInitialized = true
        } else {
            // Exponential Moving Average Formula
            smoothedRSSI = (alpha * currentRSSI) + ((1.0 - alpha) * smoothedRSSI)
        }
    }
    
    /// Reset the smoother.
    func reset() {
        isInitialized = false
        smoothedRSSI = -100.0
    }
}
