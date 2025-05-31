import Foundation

/// Policy for automatically retrying failed requests
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts
    public let maxRetries: Int
    
    /// Base delay between retries (in seconds)
    public let baseDelay: TimeInterval
    
    /// Maximum delay between retries (in seconds)
    public let maxDelay: TimeInterval
    
    /// Multiplier for exponential backoff
    public let backoffMultiplier: Double
    
    /// Whether to add random jitter to delays
    public let jitterEnabled: Bool
    
    /// Custom condition to determine if a request should be retried
    public let shouldRetry: @Sendable (NetworkError, Int) -> Bool
    
    /// Create a retry policy with custom parameters
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Base delay between retries in seconds (default: 1.0)
    ///   - maxDelay: Maximum delay between retries in seconds (default: 30.0)
    ///   - backoffMultiplier: Multiplier for exponential backoff (default: 2.0)
    ///   - jitterEnabled: Whether to add random jitter (default: true)
    ///   - shouldRetry: Custom retry condition (default: uses NetworkError.isRetryable)
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0,
        jitterEnabled: Bool = true,
        shouldRetry: @escaping @Sendable (NetworkError, Int) -> Bool = { error, _ in error.isRetryable }
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
        self.jitterEnabled = jitterEnabled
        self.shouldRetry = shouldRetry
    }
    
    /// Calculate delay for a given retry attempt
    /// - Parameter attempt: The retry attempt number (0-based)
    /// - Returns: Delay in seconds before the next retry
    public func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(backoffMultiplier, Double(attempt))
        let cappedDelay = min(exponentialDelay, maxDelay)
        
        if jitterEnabled {
            let jitter = Double.random(in: 0.5...1.5)
            return cappedDelay * jitter
        }
        
        return cappedDelay
    }
}

// MARK: - Predefined Policies
extension RetryPolicy {
    /// No retry policy
    public static let never = RetryPolicy(maxRetries: 0)
    
    /// Conservative retry policy (1 retry, 2 second delay)
    public static let conservative = RetryPolicy(
        maxRetries: 1,
        baseDelay: 2.0,
        maxDelay: 2.0,
        backoffMultiplier: 1.0
    )
    
    /// Standard retry policy (3 retries, exponential backoff)
    public static let standard = RetryPolicy()
    
    /// Aggressive retry policy (5 retries, faster backoff)
    public static let aggressive = RetryPolicy(
        maxRetries: 5,
        baseDelay: 0.5,
        maxDelay: 60.0,
        backoffMultiplier: 1.5
    )
    
    /// Retry policy for server errors only
    public static let serverErrorsOnly = RetryPolicy(
        shouldRetry: { error, _ in
            error.isServerError || error.isConnectivityError
        }
    )
    
    /// Retry policy with custom condition
    /// - Parameter condition: Custom retry condition
    /// - Returns: RetryPolicy with the specified condition
    public static func custom(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        condition: @escaping @Sendable (NetworkError, Int) -> Bool
    ) -> RetryPolicy {
        RetryPolicy(
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            shouldRetry: condition
        )
    }
} 