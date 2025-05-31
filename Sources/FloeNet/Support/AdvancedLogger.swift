import Foundation
import os.log

/// Advanced logger with filtering and debugging capabilities
public final class AdvancedLogger: Sendable {
    /// Log filtering configuration
    public struct FilterConfiguration: Sendable {
        /// URL patterns to include/exclude
        public let urlPatterns: [URLPattern]
        
        /// HTTP methods to log
        public let allowedMethods: Set<HTTPMethod>
        
        /// Minimum response time to log (in seconds)
        public let minResponseTime: TimeInterval?
        
        /// Status codes to log
        public let statusCodeRanges: [ClosedRange<Int>]
        
        /// Headers to exclude from logging
        public let excludedHeaders: Set<String>
        
        /// Whether to log successful requests
        public let logSuccessfulRequests: Bool
        
        /// Whether to log failed requests
        public let logFailedRequests: Bool
        
        /// Custom filter predicate
        public let customFilter: (@Sendable (HTTPRequest, HTTPResponse<Data>?, NetworkError?) -> Bool)?
        
        public struct URLPattern: Sendable {
            public let pattern: String
            public let isRegex: Bool
            public let include: Bool // true to include, false to exclude
            
            public init(pattern: String, isRegex: Bool = false, include: Bool = true) {
                self.pattern = pattern
                self.isRegex = isRegex
                self.include = include
            }
        }
        
        public init(
            urlPatterns: [URLPattern] = [],
            allowedMethods: Set<HTTPMethod> = Set(HTTPMethod.allCases),
            minResponseTime: TimeInterval? = nil,
            statusCodeRanges: [ClosedRange<Int>] = [200...599],
            excludedHeaders: Set<String> = ["authorization", "cookie"],
            logSuccessfulRequests: Bool = true,
            logFailedRequests: Bool = true,
            customFilter: (@Sendable (HTTPRequest, HTTPResponse<Data>?, NetworkError?) -> Bool)? = nil
        ) {
            self.urlPatterns = urlPatterns
            self.allowedMethods = allowedMethods
            self.minResponseTime = minResponseTime
            self.statusCodeRanges = statusCodeRanges
            self.excludedHeaders = excludedHeaders
            self.logSuccessfulRequests = logSuccessfulRequests
            self.logFailedRequests = logFailedRequests
            self.customFilter = customFilter
        }
        
        /// Filter for errors only
        public static let errorsOnly = FilterConfiguration(
            logSuccessfulRequests: false,
            logFailedRequests: true
        )
        
        /// Filter for slow requests only
        public static let slowRequestsOnly = FilterConfiguration(
            minResponseTime: 2.0
        )
        
        /// Filter for API calls only
        public static let apiOnly = FilterConfiguration(
            urlPatterns: [URLPattern(pattern: "/api/", include: true)]
        )
    }
    
    /// Performance monitoring configuration
    public struct PerformanceMonitoring: Sendable {
        /// Whether to enable response time tracking
        public let trackResponseTimes: Bool
        
        /// Whether to enable memory usage tracking
        public let trackMemoryUsage: Bool
        
        /// Whether to enable throughput tracking
        public let trackThroughput: Bool
        
        /// Performance metrics reporting interval
        public let reportingInterval: TimeInterval
        
        /// Performance metrics handler
        public let metricsHandler: (@Sendable (PerformanceSnapshot) -> Void)?
        
        public init(
            trackResponseTimes: Bool = true,
            trackMemoryUsage: Bool = true,
            trackThroughput: Bool = true,
            reportingInterval: TimeInterval = 60,
            metricsHandler: (@Sendable (PerformanceSnapshot) -> Void)? = nil
        ) {
            self.trackResponseTimes = trackResponseTimes
            self.trackMemoryUsage = trackMemoryUsage
            self.trackThroughput = trackThroughput
            self.reportingInterval = reportingInterval
            self.metricsHandler = metricsHandler
        }
        
        /// Minimal monitoring
        public static let minimal = PerformanceMonitoring(
            trackResponseTimes: true,
            trackMemoryUsage: false,
            trackThroughput: false
        )
        
        /// Comprehensive monitoring
        public static let comprehensive = PerformanceMonitoring(
            trackResponseTimes: true,
            trackMemoryUsage: true,
            trackThroughput: true,
            reportingInterval: 30
        )
    }
    
    /// os_log integration configuration
    public struct OSLogConfiguration: Sendable {
        /// Whether to enable os_log integration
        public let enabled: Bool
        
        /// Subsystem identifier
        public let subsystem: String
        
        /// Category for network logs
        public let category: String
        
        /// Log levels mapping to os_log types
        public let levelMapping: [LogLevel: OSLogType]
        
        public init(
            enabled: Bool = true,
            subsystem: String = "com.floenet.networking",
            category: String = "network",
            levelMapping: [LogLevel: OSLogType] = [
                .error: .error,
                .warning: .default,
                .info: .info,
                .debug: .debug,
                .verbose: .debug
            ]
        ) {
            self.enabled = enabled
            self.subsystem = subsystem
            self.category = category
            self.levelMapping = levelMapping
        }
    }
    
    /// Advanced logger configuration
    public struct Configuration: Sendable {
        /// Base logger configuration
        public let baseLogger: Logger
        
        /// Log filtering configuration
        public let filtering: FilterConfiguration
        
        /// Performance monitoring configuration
        public let performanceMonitoring: PerformanceMonitoring
        
        /// os_log integration configuration
        public let osLogConfig: OSLogConfiguration
        
        /// Whether to enable request/response dumping
        public let enableDumping: Bool
        
        /// Maximum dump size per request/response
        public let maxDumpSize: Int
        
        /// Whether to enable traffic recording
        public let enableRecording: Bool
        
        /// Maximum number of recorded requests
        public let maxRecordedRequests: Int
        
        public init(
            baseLogger: Logger = .debug,
            filtering: FilterConfiguration = FilterConfiguration(),
            performanceMonitoring: PerformanceMonitoring = PerformanceMonitoring(),
            osLogConfig: OSLogConfiguration = OSLogConfiguration(),
            enableDumping: Bool = true,
            maxDumpSize: Int = 4096,
            enableRecording: Bool = true,
            maxRecordedRequests: Int = 100
        ) {
            self.baseLogger = baseLogger
            self.filtering = filtering
            self.performanceMonitoring = performanceMonitoring
            self.osLogConfig = osLogConfig
            self.enableDumping = enableDumping
            self.maxDumpSize = maxDumpSize
            self.enableRecording = enableRecording
            self.maxRecordedRequests = maxRecordedRequests
        }
        
        /// Debug configuration
        public static let debug = Configuration(
            baseLogger: .debug,
            filtering: .errorsOnly,
            performanceMonitoring: .comprehensive,
            enableDumping: true,
            enableRecording: true
        )
        
        /// Production configuration
        public static let production = Configuration(
            baseLogger: .basic,
            filtering: .errorsOnly,
            performanceMonitoring: .minimal,
            enableDumping: false,
            enableRecording: false
        )
    }
    
    /// Performance snapshot
    public struct PerformanceSnapshot: Sendable {
        /// Timestamp of snapshot
        public let timestamp: Date
        
        /// Average response time in seconds
        public let averageResponseTime: TimeInterval
        
        /// Request count in monitoring window
        public let requestCount: Int
        
        /// Error count in monitoring window
        public let errorCount: Int
        
        /// Success rate (0.0 - 1.0)
        public let successRate: Double
        
        /// Memory usage in bytes
        public let memoryUsage: Int
        
        /// Requests per second
        public let requestsPerSecond: Double
        
        internal init(
            timestamp: Date = Date(),
            averageResponseTime: TimeInterval = 0,
            requestCount: Int = 0,
            errorCount: Int = 0,
            successRate: Double = 0,
            memoryUsage: Int = 0,
            requestsPerSecond: Double = 0
        ) {
            self.timestamp = timestamp
            self.averageResponseTime = averageResponseTime
            self.requestCount = requestCount
            self.errorCount = errorCount
            self.successRate = successRate
            self.memoryUsage = memoryUsage
            self.requestsPerSecond = requestsPerSecond
        }
    }
    
    /// Traffic recording entry
    public struct TrafficRecord: Sendable {
        /// Request ID
        public let id: UUID
        
        /// Timestamp
        public let timestamp: Date
        
        /// HTTP request
        public let request: HTTPRequest
        
        /// HTTP response (if completed)
        public let response: HTTPResponse<Data>?
        
        /// Error (if failed)
        public let error: NetworkError?
        
        /// Duration in seconds
        public let duration: TimeInterval
        
        internal init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            request: HTTPRequest,
            response: HTTPResponse<Data>? = nil,
            error: NetworkError? = nil,
            duration: TimeInterval = 0
        ) {
            self.id = id
            self.timestamp = timestamp
            self.request = request
            self.response = response
            self.error = error
            self.duration = duration
        }
    }
    
    private let configuration: Configuration
    private let osLog: OSLog?
    private let queue = DispatchQueue(label: "com.floenet.advancedlogger", qos: .utility)
    
    // Performance tracking
    private var _responseTimes: [TimeInterval] = []
    private var _requestCount: Int = 0
    private var _errorCount: Int = 0
    private var _monitoringStartTime: Date = Date()
    private var _performanceTimer: DispatchSourceTimer?
    
    // Traffic recording
    private var _trafficRecords: [TrafficRecord] = []
    private var _activeRequests: [UUID: (request: HTTPRequest, startTime: Date)] = [:]
    
    /// Initialize advanced logger
    /// - Parameter configuration: Logger configuration
    public init(configuration: Configuration = .debug) {
        self.configuration = configuration
        
        // Setup os_log if enabled
        if configuration.osLogConfig.enabled {
            self.osLog = OSLog(subsystem: configuration.osLogConfig.subsystem, category: configuration.osLogConfig.category)
        } else {
            self.osLog = nil
        }
        
        // Setup performance monitoring
        if configuration.performanceMonitoring.trackResponseTimes ||
           configuration.performanceMonitoring.trackMemoryUsage ||
           configuration.performanceMonitoring.trackThroughput {
            setupPerformanceMonitoring()
        }
    }
    
    deinit {
        _performanceTimer?.cancel()
    }
    
    /// Log request start
    /// - Parameter request: HTTP request
    /// - Returns: Request ID for tracking
    public func logRequestStart(_ request: HTTPRequest) -> UUID {
        let requestId = UUID()
        
        if configuration.enableRecording {
            queue.async { [weak self] in
                self?._activeRequests[requestId] = (request, Date())
            }
        }
        
        if shouldLogRequest(request, response: nil, error: nil) {
            let message = formatRequestStart(request, id: requestId)
            logMessage(message, level: .info)
        }
        
        return requestId
    }
    
    /// Log request completion
    /// - Parameters:
    ///   - requestId: Request ID from logRequestStart
    ///   - response: HTTP response (if successful)
    ///   - error: Network error (if failed)
    ///   - duration: Request duration in seconds
    public func logRequestCompletion(
        requestId: UUID,
        response: HTTPResponse<Data>? = nil,
        error: NetworkError? = nil,
        duration: TimeInterval
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let request = self._activeRequests.removeValue(forKey: requestId)?.request
            
            // Update performance metrics
            if self.configuration.performanceMonitoring.trackResponseTimes {
                self._responseTimes.append(duration)
                if self._responseTimes.count > 100 {
                    self._responseTimes.removeFirst()
                }
            }
            
            self._requestCount += 1
            if error != nil {
                self._errorCount += 1
            }
            
            // Record traffic if enabled
            if self.configuration.enableRecording, let request = request {
                let record = TrafficRecord(
                    id: requestId,
                    request: request,
                    response: response,
                    error: error,
                    duration: duration
                )
                self.addTrafficRecord(record)
            }
        }
        
        // Log completion if it passes filters
        if let request = _activeRequests[requestId]?.request,
           shouldLogRequest(request, response: response, error: error) {
            let message = formatRequestCompletion(requestId, response: response, error: error, duration: duration)
            let level: LogLevel = error != nil ? .error : .info
            logMessage(message, level: level)
        }
    }
    
    /// Get recorded traffic
    /// - Returns: Array of traffic records
    public func getTrafficRecords() -> [TrafficRecord] {
        return queue.sync {
            return Array(_trafficRecords)
        }
    }
    
    /// Clear recorded traffic
    public func clearTrafficRecords() {
        queue.async { [weak self] in
            self?._trafficRecords.removeAll()
        }
    }
    
    /// Get current performance snapshot
    /// - Returns: Performance snapshot
    public func getPerformanceSnapshot() -> PerformanceSnapshot {
        return queue.sync {
            return createPerformanceSnapshot()
        }
    }
    
    /// Dump request/response details
    /// - Parameters:
    ///   - request: HTTP request
    ///   - response: HTTP response (optional)
    ///   - level: Log level
    public func dumpRequestResponse(
        _ request: HTTPRequest,
        response: HTTPResponse<Data>? = nil,
        level: LogLevel = .debug
    ) {
        guard configuration.enableDumping else { return }
        
        let dump = createDetailedDump(request: request, response: response)
        logMessage(dump, level: level)
    }
    
    /// Export traffic records as formatted string
    /// - Parameter format: Export format
    /// - Returns: Formatted string
    public func exportTrafficRecords(format: ExportFormat = .text) -> String {
        let records = getTrafficRecords()
        
        switch format {
        case .text:
            return exportAsText(records)
        case .json:
            return exportAsJSON(records)
        case .har:
            return exportAsHAR(records)
        }
    }
    
    public enum ExportFormat {
        case text, json, har
    }
}

// MARK: - Private Implementation
private extension AdvancedLogger {
    func setupPerformanceMonitoring() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + configuration.performanceMonitoring.reportingInterval,
            repeating: configuration.performanceMonitoring.reportingInterval
        )
        timer.setEventHandler { [weak self] in
            self?.reportPerformanceMetrics()
        }
        timer.resume()
        _performanceTimer = timer
    }
    
    func reportPerformanceMetrics() {
        let snapshot = createPerformanceSnapshot()
        configuration.performanceMonitoring.metricsHandler?(snapshot)
        
        // Reset monitoring window
        let windowDuration = Date().timeIntervalSince(_monitoringStartTime)
        if windowDuration > configuration.performanceMonitoring.reportingInterval * 2 {
            _requestCount = 0
            _errorCount = 0
            _monitoringStartTime = Date()
        }
    }
    
    func createPerformanceSnapshot() -> PerformanceSnapshot {
        let averageResponseTime = _responseTimes.isEmpty ? 0 : _responseTimes.reduce(0, +) / Double(_responseTimes.count)
        let successRate = _requestCount > 0 ? Double(_requestCount - _errorCount) / Double(_requestCount) : 0
        let windowDuration = Date().timeIntervalSince(_monitoringStartTime)
        let requestsPerSecond = windowDuration > 0 ? Double(_requestCount) / windowDuration : 0
        
        return PerformanceSnapshot(
            averageResponseTime: averageResponseTime,
            requestCount: _requestCount,
            errorCount: _errorCount,
            successRate: successRate,
            memoryUsage: getCurrentMemoryUsage(),
            requestsPerSecond: requestsPerSecond
        )
    }
    
    func getCurrentMemoryUsage() -> Int {
        guard configuration.performanceMonitoring.trackMemoryUsage else { return 0 }
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    func shouldLogRequest(_ request: HTTPRequest, response: HTTPResponse<Data>?, error: NetworkError?) -> Bool {
        let filter = configuration.filtering
        
        // Check success/failure filters
        if error != nil && !filter.logFailedRequests { return false }
        if error == nil && !filter.logSuccessfulRequests { return false }
        
        // Check method filter
        if !filter.allowedMethods.contains(request.method) { return false }
        
        // Check URL patterns
        if !filter.urlPatterns.isEmpty {
            let url = request.url.absoluteString
            let shouldInclude = filter.urlPatterns.contains { pattern in
                let matches = pattern.isRegex ? matchesRegex(url, pattern.pattern) : url.contains(pattern.pattern)
                return pattern.include ? matches : !matches
            }
            if !shouldInclude { return false }
        }
        
        // Check response time filter
        if let minResponseTime = filter.minResponseTime,
           let response = response,
           response.duration < minResponseTime {
            return false
        }
        
        // Check status code filter
        if let response = response {
            let statusCode = response.statusCode
            let inRange = filter.statusCodeRanges.contains { range in
                range.contains(statusCode)
            }
            if !inRange { return false }
        }
        
        // Check custom filter
        if let customFilter = filter.customFilter {
            return customFilter(request, response, error)
        }
        
        return true
    }
    
    func matchesRegex(_ string: String, _ pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(string.startIndex..., in: string)
            return regex.firstMatch(in: string, options: [], range: range) != nil
        } catch {
            return false
        }
    }
    
    func logMessage(_ message: String, level: LogLevel) {
        // Log to base logger
        configuration.baseLogger.log(message, level: level)
        
        // Log to os_log if enabled
        if let osLog = osLog,
           let osLogType = configuration.osLogConfig.levelMapping[level] {
            os_log("%{public}@", log: osLog, type: osLogType, message)
        }
    }
    
    func formatRequestStart(_ request: HTTPRequest, id: UUID) -> String {
        return "🚀 [\(id.uuidString.prefix(8))] \(request.method.rawValue.uppercased()) \(request.url)"
    }
    
    func formatRequestCompletion(
        _ requestId: UUID,
        response: HTTPResponse<Data>?,
        error: NetworkError?,
        duration: TimeInterval
    ) -> String {
        let emoji = error != nil ? "❌" : "✅"
        let status = response?.statusCode ?? 0
        let durationStr = String(format: "%.3f", duration)
        
        if let error = error {
            return "\(emoji) [\(requestId.uuidString.prefix(8))] Failed (\(durationStr)s): \(error.localizedDescription)"
        } else {
            return "\(emoji) [\(requestId.uuidString.prefix(8))] \(status) (\(durationStr)s)"
        }
    }
    
    func createDetailedDump(request: HTTPRequest, response: HTTPResponse<Data>?) -> String {
        var dump = "📋 DETAILED REQUEST/RESPONSE DUMP\n"
        dump += "=" * 50 + "\n"
        
        // Request details
        dump += "REQUEST:\n"
        dump += "Method: \(request.method.rawValue.uppercased())\n"
        dump += "URL: \(request.url)\n"
        
        if !request.headers.isEmpty {
            dump += "Headers:\n"
            for (name, value) in request.headers.dictionary {
                let displayValue = configuration.filtering.excludedHeaders.contains(name.lowercased()) ? "***" : value
                dump += "  \(name): \(displayValue)\n"
            }
        }
        
        if let body = request.body {
            dump += "Body: \(formatBodyForDump(body))\n"
        }
        
        // Response details
        if let response = response {
            dump += "\nRESPONSE:\n"
            dump += "Status: \(response.statusCode)\n"
            
            if !response.headers.isEmpty {
                dump += "Headers:\n"
                for (name, value) in response.headers.dictionary {
                    dump += "  \(name): \(value)\n"
                }
            }
            
            dump += "Body: \(formatBodyForDump(response.data))\n"
        }
        
        dump += "=" * 50
        return dump
    }
    
    func formatBodyForDump(_ data: Data) -> String {
        let maxSize = min(data.count, configuration.maxDumpSize)
        let truncatedData = data.prefix(maxSize)
        
        if let string = String(data: truncatedData, encoding: .utf8) {
            let result = data.count > maxSize ? "\(string)... (\(data.count - maxSize) more bytes)" : string
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "\(data.count) bytes of binary data"
    }
    
    func addTrafficRecord(_ record: TrafficRecord) {
        _trafficRecords.append(record)
        
        // Keep only recent records
        if _trafficRecords.count > configuration.maxRecordedRequests {
            _trafficRecords.removeFirst(_trafficRecords.count - configuration.maxRecordedRequests)
        }
    }
    
    func exportAsText(_ records: [TrafficRecord]) -> String {
        var output = "FloeNet Advanced Logger Traffic Export\n"
        output += "Generated: \(Date())\n"
        output += "Total Records: \(records.count)\n\n"
        
        for record in records {
            output += "[\(record.timestamp)] \(record.request.method.rawValue.uppercased()) \(record.request.url)\n"
            if let response = record.response {
                output += "  → \(response.statusCode) (\(String(format: "%.3f", record.duration))s)\n"
            } else if let error = record.error {
                output += "  → ERROR: \(error.localizedDescription)\n"
            }
            output += "\n"
        }
        
        return output
    }
    
    func exportAsJSON(_ records: [TrafficRecord]) -> String {
        // Simplified JSON export - in production, this would use proper Codable
        var json = "{\n  \"export_time\": \"\(Date())\",\n  \"records\": [\n"
        
        for (index, record) in records.enumerated() {
            json += "    {\n"
            json += "      \"timestamp\": \"\(record.timestamp)\",\n"
            json += "      \"method\": \"\(record.request.method.rawValue.uppercased())\",\n"
            json += "      \"url\": \"\(record.request.url)\",\n"
            json += "      \"duration\": \(record.duration)\n"
            json += "    }"
            if index < records.count - 1 { json += "," }
            json += "\n"
        }
        
        json += "  ]\n}"
        return json
    }
    
    func exportAsHAR(_ records: [TrafficRecord]) -> String {
        // Simplified HAR export - in production, this would create proper HAR format
        return "{ \"log\": { \"version\": \"1.2\", \"creator\": { \"name\": \"FloeNet\", \"version\": \"0.4.0\" }, \"entries\": [] } }"
    }
}

// MARK: - String Extension
private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
} 