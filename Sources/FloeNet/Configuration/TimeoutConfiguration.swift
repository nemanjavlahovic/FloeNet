import Foundation

/// Configuration for timeout handling
public struct TimeoutConfiguration: Sendable {
    /// Connection timeout (time to establish connection)
    public let connectionTimeout: TimeInterval
    
    /// Request timeout (time to send request and receive first byte)
    public let requestTimeout: TimeInterval
    
    /// Resource timeout (total time for entire request/response cycle)
    public let resourceTimeout: TimeInterval
    
    /// Initialize timeout configuration
    /// - Parameters:
    ///   - connectionTimeout: Time to establish connection (default: 30 seconds)
    ///   - requestTimeout: Time for request/response (default: 60 seconds)
    ///   - resourceTimeout: Total time for operation (default: 120 seconds)
    public init(
        connectionTimeout: TimeInterval = 30.0,
        requestTimeout: TimeInterval = 60.0,
        resourceTimeout: TimeInterval = 120.0
    ) {
        self.connectionTimeout = connectionTimeout
        self.requestTimeout = requestTimeout
        self.resourceTimeout = resourceTimeout
    }
    
    /// Apply timeout configuration to URLSessionConfiguration
    /// - Parameter configuration: URLSessionConfiguration to modify
    public func apply(to configuration: URLSessionConfiguration) {
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = resourceTimeout
    }
    
    /// Create URLRequest with timeout applied
    /// - Parameters:
    ///   - request: Base URLRequest
    ///   - overrideTimeout: Optional override for request timeout
    /// - Returns: URLRequest with timeout configuration applied
    public func apply(to request: URLRequest, overrideTimeout: TimeInterval? = nil) -> URLRequest {
        var modifiedRequest = request
        modifiedRequest.timeoutInterval = overrideTimeout ?? requestTimeout
        return modifiedRequest
    }
}

// MARK: - Predefined Configurations
extension TimeoutConfiguration {
    /// Fast timeout configuration for quick operations
    public static let fast = TimeoutConfiguration(
        connectionTimeout: 10.0,
        requestTimeout: 30.0,
        resourceTimeout: 60.0
    )
    
    /// Standard timeout configuration for normal operations
    public static let standard = TimeoutConfiguration(
        connectionTimeout: 30.0,
        requestTimeout: 60.0,
        resourceTimeout: 120.0
    )
    
    /// Conservative timeout configuration for slow networks
    public static let conservative = TimeoutConfiguration(
        connectionTimeout: 60.0,
        requestTimeout: 120.0,
        resourceTimeout: 300.0
    )
    
    /// Patient timeout configuration for large uploads/downloads
    public static let patient = TimeoutConfiguration(
        connectionTimeout: 60.0,
        requestTimeout: 300.0,
        resourceTimeout: 600.0
    )
    
    /// Background timeout configuration for background tasks
    public static let background = TimeoutConfiguration(
        connectionTimeout: 120.0,
        requestTimeout: 300.0,
        resourceTimeout: 3600.0 // 1 hour
    )
}

// MARK: - Builder Pattern
extension TimeoutConfiguration {
    /// Timeout configuration builder
    public struct Builder {
        private var connectionTimeout: TimeInterval = 30.0
        private var requestTimeout: TimeInterval = 60.0
        private var resourceTimeout: TimeInterval = 120.0
        
        public init() {}
        
        public func connectionTimeout(_ timeout: TimeInterval) -> Builder {
            var builder = self
            builder.connectionTimeout = timeout
            return builder
        }
        
        public func requestTimeout(_ timeout: TimeInterval) -> Builder {
            var builder = self
            builder.requestTimeout = timeout
            return builder
        }
        
        public func resourceTimeout(_ timeout: TimeInterval) -> Builder {
            var builder = self
            builder.resourceTimeout = timeout
            return builder
        }
        
        public func allTimeouts(_ timeout: TimeInterval) -> Builder {
            var builder = self
            builder.connectionTimeout = timeout
            builder.requestTimeout = timeout
            builder.resourceTimeout = timeout * 2
            return builder
        }
        
        public func build() -> TimeoutConfiguration {
            return TimeoutConfiguration(
                connectionTimeout: connectionTimeout,
                requestTimeout: requestTimeout,
                resourceTimeout: resourceTimeout
            )
        }
    }
    
    /// Create a timeout configuration builder
    public static var builder: Builder {
        Builder()
    }
} 