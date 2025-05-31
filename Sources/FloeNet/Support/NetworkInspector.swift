import Foundation
import os.log

/// Network traffic inspector for debugging and monitoring
public final class NetworkInspector: Sendable {
    /// Performance metrics for a network request
    public struct Metrics: Sendable {
        /// Unique request identifier
        public let requestId: UUID
        
        /// Request start time
        public let startTime: Date
        
        /// Request end time
        public let endTime: Date
        
        /// Total request duration in seconds
        public var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
        
        /// Request size in bytes
        public let requestSize: Int
        
        /// Response size in bytes
        public let responseSize: Int
        
        /// HTTP method
        public let method: HTTPMethod
        
        /// Request URL
        public let url: URL
        
        /// Response status code
        public let statusCode: Int
        
        /// Error if request failed
        public let error: NetworkError?
        
        /// Whether the request was successful
        public var isSuccess: Bool { error == nil && (200..<300).contains(statusCode) }
        
        /// Cache hit/miss status
        public let cacheStatus: CacheStatus
        
        /// Connection reuse status
        public let connectionReused: Bool
        
        /// DNS lookup time in seconds
        public let dnsLookupTime: TimeInterval?
        
        /// Connection time in seconds
        public let connectionTime: TimeInterval?
        
        /// SSL handshake time in seconds
        public let sslHandshakeTime: TimeInterval?
        
        /// Time to first byte in seconds
        public let timeToFirstByte: TimeInterval?
        
        public enum CacheStatus: Sendable {
            case hit, miss, notApplicable
        }
        
        internal init(
            requestId: UUID,
            startTime: Date,
            endTime: Date,
            requestSize: Int,
            responseSize: Int,
            method: HTTPMethod,
            url: URL,
            statusCode: Int,
            error: NetworkError? = nil,
            cacheStatus: CacheStatus = .notApplicable,
            connectionReused: Bool = false,
            dnsLookupTime: TimeInterval? = nil,
            connectionTime: TimeInterval? = nil,
            sslHandshakeTime: TimeInterval? = nil,
            timeToFirstByte: TimeInterval? = nil
        ) {
            self.requestId = requestId
            self.startTime = startTime
            self.endTime = endTime
            self.requestSize = requestSize
            self.responseSize = responseSize
            self.method = method
            self.url = url
            self.statusCode = statusCode
            self.error = error
            self.cacheStatus = cacheStatus
            self.connectionReused = connectionReused
            self.dnsLookupTime = dnsLookupTime
            self.connectionTime = connectionTime
            self.sslHandshakeTime = sslHandshakeTime
            self.timeToFirstByte = timeToFirstByte
        }
    }
    
    /// Recorded request and response pair
    public struct RequestRecord: Sendable {
        /// Unique identifier
        public let id: UUID
        
        /// Recorded timestamp
        public let timestamp: Date
        
        /// Original HTTP request
        public let request: HTTPRequest
        
        /// HTTP response (if completed)
        public let response: HTTPResponse<Data>?
        
        /// Performance metrics
        public let metrics: Metrics
        
        /// Request headers (sanitized)
        public let sanitizedRequestHeaders: [String: String]
        
        /// Response headers
        public let responseHeaders: [String: String]
        
        /// Request body preview (first 1KB, sanitized)
        public let requestBodyPreview: String?
        
        /// Response body preview (first 1KB)
        public let responseBodyPreview: String?
        
        internal init(
            id: UUID = UUID(),
            timestamp: Date = Date(),
            request: HTTPRequest,
            response: HTTPResponse<Data>?,
            metrics: Metrics,
            requestBodyPreview: String? = nil,
            responseBodyPreview: String? = nil
        ) {
            self.id = id
            self.timestamp = timestamp
            self.request = request
            self.response = response
            self.metrics = metrics
            self.sanitizedRequestHeaders = Self.sanitizeHeaders(request.headers.dictionary)
            self.responseHeaders = response?.headers.dictionary ?? [:]
            self.requestBodyPreview = requestBodyPreview
            self.responseBodyPreview = responseBodyPreview
        }
        
        private static func sanitizeHeaders(_ headers: [String: String]) -> [String: String] {
            let sensitiveHeaders = ["authorization", "cookie", "x-api-key", "x-auth-token", "x-access-token"]
            return headers.mapValues { value in
                let key = headers.first { $0.value == value }?.key.lowercased() ?? ""
                return sensitiveHeaders.contains(key) ? "***" : value
            }
        }
    }
    
    /// Configuration for the network inspector
    public struct Configuration: Sendable {
        /// Whether to record all requests
        public let recordRequests: Bool
        
        /// Maximum number of requests to keep in memory
        public let maxRecordedRequests: Int
        
        /// Whether to capture request bodies
        public let captureRequestBodies: Bool
        
        /// Whether to capture response bodies
        public let captureResponseBodies: Bool
        
        /// Maximum body size to capture (in bytes)
        public let maxBodyCaptureSize: Int
        
        /// Whether to enable performance monitoring
        public let performanceMonitoring: Bool
        
        /// Log level for automatic logging
        public let logLevel: LogLevel?
        
        /// Custom logger for output
        public let logger: Logger?
        
        public init(
            recordRequests: Bool = true,
            maxRecordedRequests: Int = 100,
            captureRequestBodies: Bool = true,
            captureResponseBodies: Bool = true,
            maxBodyCaptureSize: Int = 1024,
            performanceMonitoring: Bool = true,
            logLevel: LogLevel? = .debug,
            logger: Logger? = nil
        ) {
            self.recordRequests = recordRequests
            self.maxRecordedRequests = maxRecordedRequests
            self.captureRequestBodies = captureRequestBodies
            self.captureResponseBodies = captureResponseBodies
            self.maxBodyCaptureSize = maxBodyCaptureSize
            self.performanceMonitoring = performanceMonitoring
            self.logLevel = logLevel
            self.logger = logger
        }
        
        /// Default configuration for debugging
        public static let debug = Configuration(
            recordRequests: true,
            maxRecordedRequests: 50,
            captureRequestBodies: true,
            captureResponseBodies: true,
            performanceMonitoring: true,
            logLevel: .debug
        )
        
        /// Production-safe configuration
        public static let production = Configuration(
            recordRequests: false,
            maxRecordedRequests: 10,
            captureRequestBodies: false,
            captureResponseBodies: false,
            performanceMonitoring: true,
            logLevel: .warning
        )
    }
    
    private let configuration: Configuration
    private let queue = DispatchQueue(label: "com.floenet.inspector", qos: .utility)
    private var _records: [RequestRecord] = []
    private var _activeRequests: [UUID: (request: HTTPRequest, startTime: Date)] = [:]
    
    /// Initialize network inspector
    /// - Parameter configuration: Inspector configuration
    public init(configuration: Configuration = .debug) {
        self.configuration = configuration
    }
    
    /// Record the start of a network request
    /// - Parameter request: HTTP request being started
    /// - Returns: Request ID for tracking
    public func requestStarted(_ request: HTTPRequest) -> UUID {
        let requestId = UUID()
        
        queue.async { [weak self] in
            self?._activeRequests[requestId] = (request, Date())
        }
        
        if let logLevel = configuration.logLevel {
            let logger = configuration.logger ?? Logger.standard
            logger.log("🚀 Request \(requestId.uuidString.prefix(8)) started: \(request.method.rawValue.uppercased()) \(request.url)", level: logLevel)
        }
        
        return requestId
    }
    
    /// Record the completion of a network request
    /// - Parameters:
    ///   - requestId: Request ID from requestStarted
    ///   - response: HTTP response received
    ///   - error: Error if request failed
    ///   - urlSessionMetrics: URLSessionTaskMetrics for detailed timing
    public func requestCompleted(
        requestId: UUID,
        response: HTTPResponse<Data>?,
        error: NetworkError? = nil,
        urlSessionMetrics: URLSessionTaskMetrics? = nil
    ) {
        queue.async { [weak self] in
            guard let self = self,
                  let (request, startTime) = self._activeRequests.removeValue(forKey: requestId) else {
                return
            }
            
            let endTime = Date()
            let metrics = self.createMetrics(
                requestId: requestId,
                request: request,
                response: response,
                error: error,
                startTime: startTime,
                endTime: endTime,
                urlSessionMetrics: urlSessionMetrics
            )
            
            if self.configuration.recordRequests {
                let record = RequestRecord(
                    id: requestId,
                    request: request,
                    response: response,
                    metrics: metrics,
                    requestBodyPreview: self.createBodyPreview(request.body, isRequest: true),
                    responseBodyPreview: self.createBodyPreview(response?.data, isRequest: false)
                )
                
                self.addRecord(record)
            }
            
            if let logLevel = self.configuration.logLevel {
                let logger = self.configuration.logger ?? Logger.standard
                let statusEmoji = error != nil ? "❌" : (response?.isSuccess == true ? "✅" : "⚠️")
                let status = response?.statusCode ?? 0
                logger.log("\(statusEmoji) Request \(requestId.uuidString.prefix(8)) completed: \(status) (\(String(format: "%.3f", metrics.duration))s)", level: logLevel)
            }
        }
    }
    
    /// Get all recorded requests
    /// - Returns: Array of request records
    public func getRecords() -> [RequestRecord] {
        return queue.sync {
            return Array(_records)
        }
    }
    
    /// Get requests matching a filter
    /// - Parameter filter: Filter predicate
    /// - Returns: Filtered array of request records
    public func getRecords(matching filter: @escaping (RequestRecord) -> Bool) -> [RequestRecord] {
        return queue.sync {
            return _records.filter(filter)
        }
    }
    
    /// Clear all recorded requests
    public func clearRecords() {
        queue.async { [weak self] in
            self?._records.removeAll()
        }
    }
    
    /// Get current performance summary
    /// - Returns: Performance summary
    public func getPerformanceSummary() -> PerformanceSummary {
        return queue.sync {
            return PerformanceSummary(from: _records)
        }
    }
    
    /// Export records as formatted string
    /// - Parameter format: Export format
    /// - Returns: Formatted string
    public func export(format: ExportFormat = .text) -> String {
        let records = getRecords()
        
        switch format {
        case .text:
            return exportAsText(records)
        case .json:
            return exportAsJSON(records)
        case .csv:
            return exportAsCSV(records)
        }
    }
    
    public enum ExportFormat {
        case text, json, csv
    }
}

// MARK: - Performance Summary
extension NetworkInspector {
    /// Performance summary statistics
    public struct PerformanceSummary: Sendable {
        /// Total number of requests
        public let totalRequests: Int
        
        /// Number of successful requests
        public let successfulRequests: Int
        
        /// Number of failed requests
        public let failedRequests: Int
        
        /// Success rate as percentage
        public var successRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(successfulRequests) / Double(totalRequests) * 100
        }
        
        /// Average request duration in seconds
        public let averageDuration: TimeInterval
        
        /// Fastest request duration in seconds
        public let fastestDuration: TimeInterval
        
        /// Slowest request duration in seconds
        public let slowestDuration: TimeInterval
        
        /// Total data transferred in bytes
        public let totalBytesTransferred: Int
        
        /// Average request size in bytes
        public let averageRequestSize: Int
        
        /// Average response size in bytes
        public let averageResponseSize: Int
        
        /// Most common status codes
        public let statusCodeDistribution: [Int: Int]
        
        /// Error distribution
        public let errorDistribution: [String: Int]
        
        internal init(from records: [RequestRecord]) {
            self.totalRequests = records.count
            self.successfulRequests = records.filter { $0.metrics.isSuccess }.count
            self.failedRequests = records.filter { !$0.metrics.isSuccess }.count
            
            if !records.isEmpty {
                let durations = records.map { $0.metrics.duration }
                self.averageDuration = durations.reduce(0, +) / Double(durations.count)
                self.fastestDuration = durations.min() ?? 0
                self.slowestDuration = durations.max() ?? 0
            } else {
                self.averageDuration = 0
                self.fastestDuration = 0
                self.slowestDuration = 0
            }
            
            self.totalBytesTransferred = records.reduce(0) { $0 + $1.metrics.requestSize + $1.metrics.responseSize }
            self.averageRequestSize = totalRequests > 0 ? records.reduce(0) { $0 + $1.metrics.requestSize } / totalRequests : 0
            self.averageResponseSize = totalRequests > 0 ? records.reduce(0) { $0 + $1.metrics.responseSize } / totalRequests : 0
            
            // Status code distribution
            var statusCodes: [Int: Int] = [:]
            for record in records {
                statusCodes[record.metrics.statusCode, default: 0] += 1
            }
            self.statusCodeDistribution = statusCodes
            
            // Error distribution
            var errors: [String: Int] = [:]
            for record in records.filter({ $0.metrics.error != nil }) {
                let errorType = String(describing: type(of: record.metrics.error!))
                errors[errorType, default: 0] += 1
            }
            self.errorDistribution = errors
        }
    }
}

// MARK: - Private Helpers
private extension NetworkInspector {
    func createMetrics(
        requestId: UUID,
        request: HTTPRequest,
        response: HTTPResponse<Data>?,
        error: NetworkError?,
        startTime: Date,
        endTime: Date,
        urlSessionMetrics: URLSessionTaskMetrics?
    ) -> Metrics {
        return Metrics(
            requestId: requestId,
            startTime: startTime,
            endTime: endTime,
            requestSize: request.body?.count ?? 0,
            responseSize: response?.data.count ?? 0,
            method: request.method,
            url: request.url,
            statusCode: response?.statusCode ?? 0,
            error: error,
            cacheStatus: determineCacheStatus(response, urlSessionMetrics),
            connectionReused: urlSessionMetrics?.connectionReused ?? false,
            dnsLookupTime: urlSessionMetrics?.domainLookupTime,
            connectionTime: urlSessionMetrics?.connectTime,
            sslHandshakeTime: urlSessionMetrics?.secureConnectionTime,
            timeToFirstByte: urlSessionMetrics?.responseStartTime
        )
    }
    
    func determineCacheStatus(_ response: HTTPResponse<Data>?, _ metrics: URLSessionTaskMetrics?) -> Metrics.CacheStatus {
        // Simple cache status determination
        if let cacheControl = response?.headers["Cache-Control"] {
            if cacheControl.contains("no-cache") || cacheControl.contains("no-store") {
                return .notApplicable
            }
        }
        
        // Check if response came from cache based on timing
        if let metrics = metrics, let responseTime = metrics.responseStartTime, responseTime < 0.01 {
            return .hit
        }
        
        return .miss
    }
    
    func createBodyPreview(_ data: Data?, isRequest: Bool) -> String? {
        guard let data = data, !data.isEmpty else { return nil }
        
        let captureEnabled = isRequest ? configuration.captureRequestBodies : configuration.captureResponseBodies
        guard captureEnabled else { return nil }
        
        let maxSize = min(data.count, configuration.maxBodyCaptureSize)
        let previewData = data.prefix(maxSize)
        
        if let string = String(data: previewData, encoding: .utf8) {
            return data.count > maxSize ? "\(string)... (\(data.count - maxSize) more bytes)" : string
        }
        
        return "\(data.count) bytes of binary data"
    }
    
    func addRecord(_ record: RequestRecord) {
        _records.append(record)
        
        // Keep only the most recent records
        if _records.count > configuration.maxRecordedRequests {
            _records.removeFirst(_records.count - configuration.maxRecordedRequests)
        }
    }
    
    func exportAsText(_ records: [RequestRecord]) -> String {
        var output = "FloeNet Network Inspector Report\n"
        output += "Generated: \(Date())\n"
        output += "Total Requests: \(records.count)\n\n"
        
        for record in records {
            output += "[\(record.timestamp)] \(record.request.method.rawValue.uppercased()) \(record.request.url)\n"
            output += "  Status: \(record.metrics.statusCode) (\(String(format: "%.3f", record.metrics.duration))s)\n"
            output += "  Size: \(record.metrics.requestSize)B → \(record.metrics.responseSize)B\n"
            if let error = record.metrics.error {
                output += "  Error: \(error.localizedDescription)\n"
            }
            output += "\n"
        }
        
        return output
    }
    
    func exportAsJSON(_ records: [RequestRecord]) -> String {
        // Simplified JSON export - in a real implementation, this would use Codable
        return "{ \"records\": \(records.count), \"exported\": \"\(Date())\" }"
    }
    
    func exportAsCSV(_ records: [RequestRecord]) -> String {
        var csv = "Timestamp,Method,URL,Status,Duration,RequestSize,ResponseSize,Error\n"
        
        for record in records {
            let error = record.metrics.error?.localizedDescription.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(record.timestamp),\(record.request.method.rawValue),\(record.request.url),\(record.metrics.statusCode),\(record.metrics.duration),\(record.metrics.requestSize),\(record.metrics.responseSize),\(error)\n"
        }
        
        return csv
    }
}

// MARK: - URLSessionTaskMetrics Extensions
private extension URLSessionTaskMetrics {
    var domainLookupTime: TimeInterval? {
        guard let transaction = transactionMetrics.first,
              let start = transaction.domainLookupStartDate, 
              let end = transaction.domainLookupEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var connectTime: TimeInterval? {
        guard let transaction = transactionMetrics.first,
              let start = transaction.connectStartDate, 
              let end = transaction.connectEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var secureConnectionTime: TimeInterval? {
        guard let transaction = transactionMetrics.first,
              let start = transaction.secureConnectionStartDate, 
              let end = transaction.secureConnectionEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var responseStartTime: TimeInterval? {
        guard let transaction = transactionMetrics.first,
              let start = transaction.requestStartDate, 
              let responseStart = transaction.responseStartDate else { return nil }
        return responseStart.timeIntervalSince(start)
    }
    
    var connectionReused: Bool {
        return transactionMetrics.first?.isReusedConnection ?? false
    }
} 