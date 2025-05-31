import Foundation

/// Configuration for network operations
public struct NetworkConfiguration: Sendable {
    /// Default timeout for requests
    public let defaultTimeout: TimeInterval
    
    /// Maximum number of concurrent requests
    public let maxConcurrentRequests: Int
    
    /// Default retry policy
    public let retryPolicy: RetryPolicy
    
    /// Network logger
    public let logger: Logger
    
    /// Request interceptors
    public let requestInterceptors: [RequestInterceptor]
    
    /// Response interceptors
    public let responseInterceptors: [ResponseInterceptor]
    
    /// Response validator
    public let responseValidator: ResponseValidator?
    
    /// Whether to allow cellular access
    public let allowsCellularAccess: Bool
    
    /// Whether to allow expensive network access
    public let allowsExpensiveNetworkAccess: Bool
    
    /// Whether to allow constrained network access
    public let allowsConstrainedNetworkAccess: Bool
    
    /// Whether requests should wait for connectivity
    public let waitsForConnectivity: Bool
    
    /// Custom URLSessionConfiguration
    public let urlSessionConfiguration: URLSessionConfiguration?
    
    /// Initialize network configuration
    /// - Parameters:
    ///   - defaultTimeout: Default timeout for requests (default: 60 seconds)
    ///   - maxConcurrentRequests: Maximum concurrent requests (default: 10)
    ///   - retryPolicy: Default retry policy (default: .standard)
    ///   - logger: Network logger (default: .standard)
    ///   - requestInterceptors: Request interceptors (default: empty)
    ///   - responseInterceptors: Response interceptors (default: empty)
    ///   - responseValidator: Response validator (default: nil)
    ///   - allowsCellularAccess: Allow cellular access (default: true)
    ///   - allowsExpensiveNetworkAccess: Allow expensive network (default: true)
    ///   - allowsConstrainedNetworkAccess: Allow constrained network (default: true)
    ///   - waitsForConnectivity: Wait for connectivity (default: true)
    ///   - urlSessionConfiguration: Custom URLSession configuration (default: nil)
    public init(
        defaultTimeout: TimeInterval = 60.0,
        maxConcurrentRequests: Int = 10,
        retryPolicy: RetryPolicy = .standard,
        logger: Logger = .standard,
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        responseValidator: ResponseValidator? = nil,
        allowsCellularAccess: Bool = true,
        allowsExpensiveNetworkAccess: Bool = true,
        allowsConstrainedNetworkAccess: Bool = true,
        waitsForConnectivity: Bool = true,
        urlSessionConfiguration: URLSessionConfiguration? = nil
    ) {
        self.defaultTimeout = defaultTimeout
        self.maxConcurrentRequests = maxConcurrentRequests
        self.retryPolicy = retryPolicy
        self.logger = logger
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.responseValidator = responseValidator
        self.allowsCellularAccess = allowsCellularAccess
        self.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        self.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
        self.waitsForConnectivity = waitsForConnectivity
        self.urlSessionConfiguration = urlSessionConfiguration
    }
    
    /// Create URLSessionConfiguration from network configuration
    public func createURLSessionConfiguration() -> URLSessionConfiguration {
        let config = urlSessionConfiguration ?? URLSessionConfiguration.default
        
        config.allowsCellularAccess = allowsCellularAccess
        config.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        config.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
        config.waitsForConnectivity = waitsForConnectivity
        config.timeoutIntervalForRequest = defaultTimeout
        config.timeoutIntervalForResource = defaultTimeout * 2
        
        if maxConcurrentRequests > 0 {
            config.httpMaximumConnectionsPerHost = maxConcurrentRequests
        }
        
        return config
    }
}

// MARK: - Predefined Configurations
extension NetworkConfiguration {
    /// Default configuration suitable for most applications
    public static let `default` = NetworkConfiguration()
    
    /// Debug configuration with verbose logging
    public static let debug = NetworkConfiguration(
        logger: .debug,
        responseValidator: CompositeValidator.standard
    )
    
    /// Production configuration with minimal logging and strict validation
    public static let production = NetworkConfiguration(
        logger: .basic,
        responseValidator: CompositeValidator.standard,
        waitsForConnectivity: false
    )
    
    /// Conservative configuration with longer timeouts and aggressive retries
    public static let conservative = NetworkConfiguration(
        defaultTimeout: 120.0,
        retryPolicy: .aggressive,
        logger: .standard
    )
    
    /// Fast configuration optimized for quick requests
    public static let fast = NetworkConfiguration(
        defaultTimeout: 30.0,
        retryPolicy: .never,
        logger: .basic,
        waitsForConnectivity: false
    )
    
    /// Offline-friendly configuration that handles poor connectivity
    public static let offlineFriendly = NetworkConfiguration(
        defaultTimeout: 180.0,
        retryPolicy: .aggressive,
        logger: .standard,
        allowsExpensiveNetworkAccess: false,
        allowsConstrainedNetworkAccess: true,
        waitsForConnectivity: true
    )
    
    /// Configuration for background tasks
    public static let background = NetworkConfiguration(
        defaultTimeout: 300.0,
        maxConcurrentRequests: 5,
        retryPolicy: .aggressive,
        logger: .basic,
        urlSessionConfiguration: URLSessionConfiguration.background(
            withIdentifier: "FloeNet.background"
        )
    )
}

// MARK: - Builder Pattern
extension NetworkConfiguration {
    /// Configuration builder for fluent API
    public struct Builder {
        private var config: NetworkConfiguration
        
        public init() {
            self.config = NetworkConfiguration()
        }
        
        public init(from configuration: NetworkConfiguration) {
            self.config = configuration
        }
        
        public func timeout(_ timeout: TimeInterval) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: timeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func maxConcurrentRequests(_ count: Int) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: count,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func retryPolicy(_ policy: RetryPolicy) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: policy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func logger(_ logger: Logger) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func addRequestInterceptor(_ interceptor: RequestInterceptor) -> Builder {
            var builder = self
            var interceptors = config.requestInterceptors
            interceptors.append(interceptor)
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: interceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func addResponseInterceptor(_ interceptor: ResponseInterceptor) -> Builder {
            var builder = self
            var interceptors = config.responseInterceptors
            interceptors.append(interceptor)
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: interceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func responseValidator(_ validator: ResponseValidator) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: validator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func allowsCellularAccess(_ allows: Bool) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: allows,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: config.waitsForConnectivity,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func waitsForConnectivity(_ waits: Bool) -> Builder {
            var builder = self
            builder.config = NetworkConfiguration(
                defaultTimeout: config.defaultTimeout,
                maxConcurrentRequests: config.maxConcurrentRequests,
                retryPolicy: config.retryPolicy,
                logger: config.logger,
                requestInterceptors: config.requestInterceptors,
                responseInterceptors: config.responseInterceptors,
                responseValidator: config.responseValidator,
                allowsCellularAccess: config.allowsCellularAccess,
                allowsExpensiveNetworkAccess: config.allowsExpensiveNetworkAccess,
                allowsConstrainedNetworkAccess: config.allowsConstrainedNetworkAccess,
                waitsForConnectivity: waits,
                urlSessionConfiguration: config.urlSessionConfiguration
            )
            return builder
        }
        
        public func build() -> NetworkConfiguration {
            return config
        }
    }
    
    /// Create a configuration builder
    public static var builder: Builder {
        Builder()
    }
    
    /// Create a configuration builder from existing configuration
    public func builder() -> Builder {
        Builder(from: self)
    }
} 