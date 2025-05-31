import Foundation

/// Performance optimizer for network operations
public final class PerformanceOptimizer: Sendable {
    /// Request priority levels
    public enum Priority: Int, CaseIterable, Sendable {
        case background = 0
        case utility = 1
        case `default` = 2
        case userInitiated = 3
        case userInteractive = 4
        
        /// Convert to URLSessionTask priority
        public var urlSessionTaskPriority: Float {
            switch self {
            case .background: return URLSessionTask.lowPriority
            case .utility: return URLSessionTask.lowPriority
            case .default: return URLSessionTask.defaultPriority
            case .userInitiated: return URLSessionTask.highPriority
            case .userInteractive: return URLSessionTask.highPriority
            }
        }
        
        /// Convert to DispatchQoS
        public var qos: DispatchQoS.QoSClass {
            switch self {
            case .background: return .background
            case .utility: return .utility
            case .default: return .default
            case .userInitiated: return .userInitiated
            case .userInteractive: return .userInteractive
            }
        }
    }
    
    /// Connection pool configuration
    public struct ConnectionPoolConfiguration: Sendable {
        /// Maximum number of connections per host
        public let maxConnectionsPerHost: Int
        
        /// Maximum total connections
        public let maxTotalConnections: Int
        
        /// Connection timeout in seconds
        public let connectionTimeout: TimeInterval
        
        /// Keep-alive timeout in seconds
        public let keepAliveTimeout: TimeInterval
        
        /// Whether to enable HTTP/2
        public let enableHTTP2: Bool
        
        /// Whether to enable connection reuse
        public let enableConnectionReuse: Bool
        
        public init(
            maxConnectionsPerHost: Int = 6,
            maxTotalConnections: Int = 50,
            connectionTimeout: TimeInterval = 30,
            keepAliveTimeout: TimeInterval = 60,
            enableHTTP2: Bool = true,
            enableConnectionReuse: Bool = true
        ) {
            self.maxConnectionsPerHost = maxConnectionsPerHost
            self.maxTotalConnections = maxTotalConnections
            self.connectionTimeout = connectionTimeout
            self.keepAliveTimeout = keepAliveTimeout
            self.enableHTTP2 = enableHTTP2
            self.enableConnectionReuse = enableConnectionReuse
        }
        
        /// High performance configuration
        public static let highPerformance = ConnectionPoolConfiguration(
            maxConnectionsPerHost: 10,
            maxTotalConnections: 100,
            connectionTimeout: 15,
            keepAliveTimeout: 120,
            enableHTTP2: true,
            enableConnectionReuse: true
        )
        
        /// Conservative configuration
        public static let conservative = ConnectionPoolConfiguration(
            maxConnectionsPerHost: 4,
            maxTotalConnections: 25,
            connectionTimeout: 30,
            keepAliveTimeout: 30,
            enableHTTP2: false,
            enableConnectionReuse: true
        )
    }
    
    /// Request queue configuration
    public struct QueueConfiguration: Sendable {
        /// Maximum number of concurrent requests
        public let maxConcurrentRequests: Int
        
        /// Maximum queue size (pending requests)
        public let maxQueueSize: Int
        
        /// Request timeout for queued requests
        public let queueTimeout: TimeInterval
        
        /// Whether to enable priority queuing
        public let enablePriorityQueuing: Bool
        
        /// Whether to enable request deduplication
        public let enableDeduplication: Bool
        
        public init(
            maxConcurrentRequests: Int = 10,
            maxQueueSize: Int = 100,
            queueTimeout: TimeInterval = 300,
            enablePriorityQueuing: Bool = true,
            enableDeduplication: Bool = true
        ) {
            self.maxConcurrentRequests = maxConcurrentRequests
            self.maxQueueSize = maxQueueSize
            self.queueTimeout = queueTimeout
            self.enablePriorityQueuing = enablePriorityQueuing
            self.enableDeduplication = enableDeduplication
        }
        
        /// High throughput configuration
        public static let highThroughput = QueueConfiguration(
            maxConcurrentRequests: 20,
            maxQueueSize: 200,
            queueTimeout: 600,
            enablePriorityQueuing: true,
            enableDeduplication: true
        )
        
        /// Resource constrained configuration
        public static let resourceConstrained = QueueConfiguration(
            maxConcurrentRequests: 5,
            maxQueueSize: 50,
            queueTimeout: 120,
            enablePriorityQueuing: true,
            enableDeduplication: true
        )
    }
    
    /// Memory management configuration
    public struct MemoryConfiguration: Sendable {
        /// Maximum memory usage in bytes
        public let maxMemoryUsage: Int
        
        /// Maximum response cache size
        public let maxResponseCacheSize: Int
        
        /// Memory warning threshold (0.0 - 1.0)
        public let memoryWarningThreshold: Double
        
        /// Whether to enable automatic memory cleanup
        public let enableAutomaticCleanup: Bool
        
        /// Cleanup interval in seconds
        public let cleanupInterval: TimeInterval
        
        public init(
            maxMemoryUsage: Int = 50 * 1024 * 1024, // 50MB
            maxResponseCacheSize: Int = 10 * 1024 * 1024, // 10MB
            memoryWarningThreshold: Double = 0.8,
            enableAutomaticCleanup: Bool = true,
            cleanupInterval: TimeInterval = 60
        ) {
            self.maxMemoryUsage = maxMemoryUsage
            self.maxResponseCacheSize = maxResponseCacheSize
            self.memoryWarningThreshold = memoryWarningThreshold
            self.enableAutomaticCleanup = enableAutomaticCleanup
            self.cleanupInterval = cleanupInterval
        }
        
        /// Low memory configuration
        public static let lowMemory = MemoryConfiguration(
            maxMemoryUsage: 10 * 1024 * 1024, // 10MB
            maxResponseCacheSize: 2 * 1024 * 1024, // 2MB
            memoryWarningThreshold: 0.7,
            enableAutomaticCleanup: true,
            cleanupInterval: 30
        )
        
        /// High memory configuration
        public static let highMemory = MemoryConfiguration(
            maxMemoryUsage: 100 * 1024 * 1024, // 100MB
            maxResponseCacheSize: 25 * 1024 * 1024, // 25MB
            memoryWarningThreshold: 0.9,
            enableAutomaticCleanup: true,
            cleanupInterval: 120
        )
    }
    
    /// Performance optimization configuration
    public struct Configuration: Sendable {
        /// Connection pool configuration
        public let connectionPool: ConnectionPoolConfiguration
        
        /// Request queue configuration
        public let requestQueue: QueueConfiguration
        
        /// Memory management configuration
        public let memory: MemoryConfiguration
        
        /// Whether to enable performance monitoring
        public let enableMonitoring: Bool
        
        /// Performance metrics handler
        public let metricsHandler: (@Sendable (PerformanceMetrics) -> Void)?
        
        public init(
            connectionPool: ConnectionPoolConfiguration = ConnectionPoolConfiguration(),
            requestQueue: QueueConfiguration = QueueConfiguration(),
            memory: MemoryConfiguration = MemoryConfiguration(),
            enableMonitoring: Bool = true,
            metricsHandler: (@Sendable (PerformanceMetrics) -> Void)? = nil
        ) {
            self.connectionPool = connectionPool
            self.requestQueue = requestQueue
            self.memory = memory
            self.enableMonitoring = enableMonitoring
            self.metricsHandler = metricsHandler
        }
        
        /// High performance configuration
        public static let highPerformance = Configuration(
            connectionPool: .highPerformance,
            requestQueue: .highThroughput,
            memory: .highMemory,
            enableMonitoring: true
        )
        
        /// Battery optimized configuration
        public static let batteryOptimized = Configuration(
            connectionPool: .conservative,
            requestQueue: .resourceConstrained,
            memory: .lowMemory,
            enableMonitoring: false
        )
    }
    
    /// Performance metrics
    public struct PerformanceMetrics: Sendable {
        /// Current memory usage in bytes
        public let currentMemoryUsage: Int
        
        /// Number of active connections
        public let activeConnections: Int
        
        /// Number of queued requests
        public let queuedRequests: Int
        
        /// Number of active requests
        public let activeRequests: Int
        
        /// Average response time in seconds
        public let averageResponseTime: TimeInterval
        
        /// Request throughput (requests per second)
        public let requestThroughput: Double
        
        /// Cache hit rate (0.0 - 1.0)
        public let cacheHitRate: Double
        
        /// Connection reuse rate (0.0 - 1.0)
        public let connectionReuseRate: Double
        
        /// Memory pressure level (0.0 - 1.0)
        public let memoryPressure: Double
        
        internal init(
            currentMemoryUsage: Int = 0,
            activeConnections: Int = 0,
            queuedRequests: Int = 0,
            activeRequests: Int = 0,
            averageResponseTime: TimeInterval = 0,
            requestThroughput: Double = 0,
            cacheHitRate: Double = 0,
            connectionReuseRate: Double = 0,
            memoryPressure: Double = 0
        ) {
            self.currentMemoryUsage = currentMemoryUsage
            self.activeConnections = activeConnections
            self.queuedRequests = queuedRequests
            self.activeRequests = activeRequests
            self.averageResponseTime = averageResponseTime
            self.requestThroughput = requestThroughput
            self.cacheHitRate = cacheHitRate
            self.connectionReuseRate = connectionReuseRate
            self.memoryPressure = memoryPressure
        }
    }
    
    /// Queued request information
    private struct QueuedRequest: Sendable {
        let id: UUID
        let request: HTTPRequest
        let priority: Priority
        let queueTime: Date
        let completion: @Sendable (Result<HTTPResponse<Data>, NetworkError>) -> Void
        
        init(
            id: UUID = UUID(),
            request: HTTPRequest,
            priority: Priority,
            queueTime: Date = Date(),
            completion: @escaping @Sendable (Result<HTTPResponse<Data>, NetworkError>) -> Void
        ) {
            self.id = id
            self.request = request
            self.priority = priority
            self.queueTime = queueTime
            self.completion = completion
        }
    }
    
    private let configuration: Configuration
    private let queue = DispatchQueue(label: "com.floenet.performance", qos: .utility)
    private var _queuedRequests: [QueuedRequest] = []
    private var _activeRequests: Set<UUID> = []
    private var _connectionPool: [String: URLSession] = [:]
    private var _memoryUsage: Int = 0
    private var _responseTimes: [TimeInterval] = []
    private var _requestCount: Int = 0
    private var _startTime: Date = Date()
    private var _cleanupTimer: DispatchSourceTimer?
    
    /// Initialize performance optimizer
    /// - Parameter configuration: Performance configuration
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        
        if configuration.memory.enableAutomaticCleanup {
            setupMemoryCleanup()
        }
        
        setupMemoryWarningNotifications()
    }
    
    deinit {
        _cleanupTimer?.cancel()
    }
    
    /// Optimize request for execution
    /// - Parameters:
    ///   - request: HTTP request to optimize
    ///   - priority: Request priority
    /// - Returns: Optimized request
    public func optimizeRequest(_ request: HTTPRequest, priority: Priority) -> HTTPRequest {
        // Create a new optimized request instead of modifying the existing one
        let optimizedTimeout = request.timeout ?? optimizeTimeout(for: request, priority: priority)
        let optimizedHeaders = optimizeHeaders(request.headers, priority: priority)
        
        return HTTPRequest(
            method: request.method,
            url: request.url,
            headers: optimizedHeaders,
            queryParameters: request.queryParameters,
            body: request.body,
            timeout: optimizedTimeout
        )
    }
    
    /// Queue request for execution with priority
    /// - Parameters:
    ///   - request: HTTP request to queue
    ///   - priority: Request priority
    ///   - completion: Completion handler
    /// - Returns: Request ID for tracking
    @discardableResult
    public func queueRequest(
        _ request: HTTPRequest,
        priority: Priority = .default,
        completion: @escaping @Sendable (Result<HTTPResponse<Data>, NetworkError>) -> Void
    ) -> UUID {
        let queuedRequest = QueuedRequest(
            request: request,
            priority: priority,
            completion: completion
        )
        
        queue.async { [weak self] in
            self?.addToQueue(queuedRequest)
        }
        
        return queuedRequest.id
    }
    
    /// Cancel queued request
    /// - Parameter requestId: Request ID to cancel
    public func cancelRequest(_ requestId: UUID) {
        queue.async { [weak self] in
            self?._queuedRequests.removeAll { $0.id == requestId }
        }
    }
    
    /// Get optimized URL session for host
    /// - Parameter host: Target host
    /// - Returns: Optimized URL session
    public func getURLSession(for host: String) -> URLSession {
        return queue.sync {
            if let existingSession = _connectionPool[host] {
                return existingSession
            }
            
            let session = createOptimizedSession(for: host)
            _connectionPool[host] = session
            return session
        }
    }
    
    /// Get current performance metrics
    /// - Returns: Performance metrics
    public func getMetrics() -> PerformanceMetrics {
        return queue.sync {
            let metrics = PerformanceMetrics(
                currentMemoryUsage: _memoryUsage,
                activeConnections: _connectionPool.count,
                queuedRequests: _queuedRequests.count,
                activeRequests: _activeRequests.count,
                averageResponseTime: calculateAverageResponseTime(),
                requestThroughput: calculateRequestThroughput(),
                cacheHitRate: 0.0, // TODO: Implement cache hit tracking
                connectionReuseRate: 0.0, // TODO: Implement connection reuse tracking
                memoryPressure: Double(_memoryUsage) / Double(configuration.memory.maxMemoryUsage)
            )
            
            if configuration.enableMonitoring {
                configuration.metricsHandler?(metrics)
            }
            
            return metrics
        }
    }
    
    /// Record response time for metrics
    /// - Parameter responseTime: Response time in seconds
    public func recordResponseTime(_ responseTime: TimeInterval) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self._responseTimes.append(responseTime)
            
            // Keep only recent response times (last 100)
            if self._responseTimes.count > 100 {
                self._responseTimes.removeFirst(self._responseTimes.count - 100)
            }
            
            self._requestCount += 1
        }
    }
    
    /// Clean up resources
    public func cleanup() {
        queue.async { [weak self] in
            self?.performCleanup()
        }
    }
}

// MARK: - Private Implementation
private extension PerformanceOptimizer {
    func setupMemoryCleanup() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + configuration.memory.cleanupInterval, repeating: configuration.memory.cleanupInterval)
        timer.setEventHandler { [weak self] in
            self?.performCleanup()
        }
        timer.resume()
        _cleanupTimer = timer
    }
    
    func setupMemoryWarningNotifications() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        #endif
    }
    
    private func addToQueue(_ queuedRequest: QueuedRequest) {
        // Check queue size limit
        guard _queuedRequests.count < configuration.requestQueue.maxQueueSize else {
            queuedRequest.completion(.failure(.invalidRequest("Request queue is full")))
            return
        }
        
        // Check for deduplication
        if configuration.requestQueue.enableDeduplication {
            if let existingIndex = _queuedRequests.firstIndex(where: { isDuplicateRequest($0.request, queuedRequest.request) }) {
                // Replace with higher priority request
                if queuedRequest.priority.rawValue > _queuedRequests[existingIndex].priority.rawValue {
                    _queuedRequests[existingIndex] = queuedRequest
                }
                return
            }
        }
        
        // Add to queue
        _queuedRequests.append(queuedRequest)
        
        // Sort by priority if enabled
        if configuration.requestQueue.enablePriorityQueuing {
            _queuedRequests.sort { $0.priority.rawValue > $1.priority.rawValue }
        }
        
        // Process queue
        processQueue()
    }
    
    func processQueue() {
        // Remove expired requests
        let now = Date()
        _queuedRequests.removeAll { request in
            let isExpired = now.timeIntervalSince(request.queueTime) > configuration.requestQueue.queueTimeout
            if isExpired {
                request.completion(.failure(.requestTimeout))
            }
            return isExpired
        }
        
        // Process requests up to concurrent limit
        while _activeRequests.count < configuration.requestQueue.maxConcurrentRequests && !_queuedRequests.isEmpty {
            let queuedRequest = _queuedRequests.removeFirst()
            _activeRequests.insert(queuedRequest.id)
            
            // Execute request on appropriate queue
            let executionQueue = DispatchQueue(label: "com.floenet.request", qos: DispatchQoS(qosClass: queuedRequest.priority.qos, relativePriority: 0))
            
            executionQueue.async { [weak self] in
                // TODO: Execute actual request here
                // For now, simulate completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.queue.async {
                        self?._activeRequests.remove(queuedRequest.id)
                        self?.processQueue() // Process next requests
                    }
                }
            }
        }
    }
    
    func createOptimizedSession(for host: String) -> URLSession {
        let config = URLSessionConfiguration.default
        
        // Apply connection pool settings
        config.httpMaximumConnectionsPerHost = configuration.connectionPool.maxConnectionsPerHost
        config.timeoutIntervalForRequest = configuration.connectionPool.connectionTimeout
        config.timeoutIntervalForResource = configuration.connectionPool.keepAliveTimeout
        
        // HTTP/2 support
        if configuration.connectionPool.enableHTTP2 {
            config.httpShouldUsePipelining = true
        }
        
        // Connection reuse
        if !configuration.connectionPool.enableConnectionReuse {
            config.urlCache = nil
            config.urlCredentialStorage = nil
        }
        
        // Memory optimizations
        config.urlCache?.memoryCapacity = configuration.memory.maxResponseCacheSize
        
        return URLSession(configuration: config)
    }
    
    func optimizeTimeout(for request: HTTPRequest, priority: Priority) -> TimeInterval {
        let baseTimeout: TimeInterval = 30.0
        
        switch priority {
        case .background:
            return baseTimeout * 2.0 // Longer timeout for background requests
        case .utility:
            return baseTimeout * 1.5
        case .default:
            return baseTimeout
        case .userInitiated:
            return baseTimeout * 0.75
        case .userInteractive:
            return baseTimeout * 0.5 // Shorter timeout for interactive requests
        }
    }
    
    func optimizeHeaders(_ headers: HTTPHeaders, priority: Priority) -> HTTPHeaders {
        var optimizedHeaders = headers
        
        // Add priority hints for HTTP/2
        if configuration.connectionPool.enableHTTP2 {
            switch priority {
            case .userInteractive, .userInitiated:
                optimizedHeaders.add(name: "Priority", value: "u=1") // High priority
            case .default:
                optimizedHeaders.add(name: "Priority", value: "u=3") // Normal priority
            case .utility, .background:
                optimizedHeaders.add(name: "Priority", value: "u=6") // Low priority
            }
        }
        
        // Connection management
        if configuration.connectionPool.enableConnectionReuse {
            optimizedHeaders.add(name: "Connection", value: "keep-alive")
        } else {
            optimizedHeaders.add(name: "Connection", value: "close")
        }
        
        return optimizedHeaders
    }
    
    func isDuplicateRequest(_ request1: HTTPRequest, _ request2: HTTPRequest) -> Bool {
        return request1.method == request2.method &&
               request1.url == request2.url &&
               request1.headers.dictionary == request2.headers.dictionary &&
               request1.body == request2.body
    }
    
    func calculateAverageResponseTime() -> TimeInterval {
        guard !_responseTimes.isEmpty else { return 0 }
        return _responseTimes.reduce(0, +) / Double(_responseTimes.count)
    }
    
    func calculateRequestThroughput() -> Double {
        let timeElapsed = Date().timeIntervalSince(_startTime)
        guard timeElapsed > 0 else { return 0 }
        return Double(_requestCount) / timeElapsed
    }
    
    func performCleanup() {
        // Clean up expired sessions
        _connectionPool = _connectionPool.compactMapValues { session in
            // Simple cleanup logic - in practice, you'd track session age
            return session
        }
        
        // Reset metrics if memory pressure is high
        let memoryPressure = Double(_memoryUsage) / Double(configuration.memory.maxMemoryUsage)
        if memoryPressure > configuration.memory.memoryWarningThreshold {
            _responseTimes = Array(_responseTimes.suffix(25)) // Keep only recent data
        }
    }
    
    func handleMemoryWarning() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Aggressive cleanup on memory warning
            self._responseTimes = Array(self._responseTimes.suffix(10))
            
            // Clear cached sessions
            self._connectionPool.removeAll()
            
            // Cancel low priority queued requests
            self._queuedRequests.removeAll { request in
                let shouldCancel = request.priority.rawValue <= Priority.utility.rawValue
                if shouldCancel {
                    request.completion(.failure(.cancelled))
                }
                return shouldCancel
            }
        }
    }
} 