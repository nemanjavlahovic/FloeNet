import Foundation
import os.log

/// Network logging levels
public enum LogLevel: Int, CaseIterable, Sendable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
    case verbose = 5
    
    public var description: String {
        switch self {
        case .none: return "NONE"
        case .error: return "ERROR"
        case .warning: return "WARNING"
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .verbose: return "VERBOSE"
        }
    }
}

/// Network logger for debugging and monitoring
public final class Logger: Sendable {
    /// Current logging level
    public let level: LogLevel
    
    /// Whether to log request details
    public let logRequests: Bool
    
    /// Whether to log response details
    public let logResponses: Bool
    
    /// Whether to log response data
    public let logResponseData: Bool
    
    /// Whether to use pretty printing for JSON
    public let prettyPrint: Bool
    
    /// Custom log output handler
    public let outputHandler: @Sendable (String) -> Void
    
    /// Initialize logger with configuration
    /// - Parameters:
    ///   - level: Minimum log level to output
    ///   - logRequests: Whether to log request details
    ///   - logResponses: Whether to log response details
    ///   - logResponseData: Whether to log response body data
    ///   - prettyPrint: Whether to format JSON nicely
    ///   - outputHandler: Custom output handler (default: print)
    public init(
        level: LogLevel = .info,
        logRequests: Bool = true,
        logResponses: Bool = true,
        logResponseData: Bool = false,
        prettyPrint: Bool = true,
        outputHandler: @escaping @Sendable (String) -> Void = { print($0) }
    ) {
        self.level = level
        self.logRequests = logRequests
        self.logResponses = logResponses
        self.logResponseData = logResponseData
        self.prettyPrint = prettyPrint
        self.outputHandler = outputHandler
    }
    
    /// Log a message at the specified level
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level
    public func log(_ message: String, level: LogLevel = .info) {
        guard level.rawValue <= self.level.rawValue else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [FloeNet] [\(level.description)] \(message)"
        outputHandler(logMessage)
    }
    
    /// Log an error
    /// - Parameter error: Error to log
    public func error(_ error: Error) {
        log("Error: \(error)", level: .error)
    }
    
    /// Log a warning message
    /// - Parameter message: Warning message
    public func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    /// Log an info message
    /// - Parameter message: Info message
    public func info(_ message: String) {
        log(message, level: .info)
    }
    
    /// Log a debug message
    /// - Parameter message: Debug message
    public func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    /// Log a verbose message
    /// - Parameter message: Verbose message
    public func verbose(_ message: String) {
        log(message, level: .verbose)
    }
}

// MARK: - Request/Response Logging
extension Logger {
    /// Log HTTP request details
    /// - Parameters:
    ///   - request: HTTP request to log
    ///   - urlRequest: Underlying URLRequest
    public func logRequest(_ request: HTTPRequest, urlRequest: URLRequest) {
        guard logRequests && level.rawValue >= LogLevel.info.rawValue else { return }
        
        var logParts: [String] = []
        logParts.append("→ \(request.method.rawValue.uppercased()) \(urlRequest.url?.absoluteString ?? "Unknown URL")")
        
        if level.rawValue >= LogLevel.debug.rawValue {
            if !request.headers.isEmpty {
                logParts.append("Headers:")
                for (name, value) in request.headers.dictionary {
                    let maskedValue = shouldMaskHeader(name) ? "***" : value
                    logParts.append("  \(name): \(maskedValue)")
                }
            }
            
            if let body = urlRequest.httpBody, !body.isEmpty {
                logParts.append("Body: \(formatBody(body))")
            }
            
            if let timeout = request.timeout {
                logParts.append("Timeout: \(timeout)s")
            }
        }
        
        log(logParts.joined(separator: "\n"), level: .info)
    }
    
    /// Log HTTP response details
    /// - Parameters:
    ///   - response: HTTP response to log
    ///   - duration: Request duration in seconds
    public func logResponse<T>(_ response: HTTPResponse<T>, duration: TimeInterval) {
        guard logResponses && level.rawValue >= LogLevel.info.rawValue else { return }
        
        var logParts: [String] = []
        let statusEmoji = response.isSuccess ? "✅" : (response.isClientError ? "⚠️" : "❌")
        logParts.append("← \(statusEmoji) \(response.statusCode) (\(String(format: "%.3f", duration))s)")
        
        if level.rawValue >= LogLevel.debug.rawValue {
            if !response.headers.isEmpty {
                logParts.append("Headers:")
                for (name, value) in response.headers.dictionary {
                    logParts.append("  \(name): \(value)")
                }
            }
            
            logParts.append("Size: \(formatBytes(response.size))")
            
            if let contentType = response.contentType {
                logParts.append("Content-Type: \(contentType)")
            }
        }
        
        if logResponseData && level.rawValue >= LogLevel.verbose.rawValue && !response.data.isEmpty {
            logParts.append("Body: \(formatBody(response.data))")
        }
        
        log(logParts.joined(separator: "\n"), level: .info)
    }
    
    /// Log network error
    /// - Parameters:
    ///   - error: Network error to log
    ///   - duration: Request duration in seconds
    public func logError(_ error: NetworkError, duration: TimeInterval) {
        guard level.rawValue >= LogLevel.error.rawValue else { return }
        
        let errorMessage = "❌ Request failed after \(String(format: "%.3f", duration))s: \(error.localizedDescription)"
        log(errorMessage, level: .error)
        
        if level.rawValue >= LogLevel.debug.rawValue {
            if let data = error.responseData, !data.isEmpty {
                log("Error Response Body: \(formatBody(data))", level: .debug)
            }
        }
    }
    
    /// Log retry attempt
    /// - Parameters:
    ///   - attempt: Retry attempt number
    ///   - delay: Delay before retry in seconds
    ///   - error: Error that triggered the retry
    public func logRetry(attempt: Int, delay: TimeInterval, error: NetworkError) {
        guard level.rawValue >= LogLevel.warning.rawValue else { return }
        
        log("🔄 Retry attempt \(attempt + 1) in \(String(format: "%.1f", delay))s due to: \(error.localizedDescription)", level: .warning)
    }
}

// MARK: - Private Helpers
private extension Logger {
    func shouldMaskHeader(_ name: String) -> Bool {
        let sensitiveHeaders = ["authorization", "cookie", "x-api-key", "x-auth-token"]
        return sensitiveHeaders.contains(name.lowercased())
    }
    
    func formatBody(_ data: Data) -> String {
        guard !data.isEmpty else { return "Empty" }
        
        if let jsonString = formatAsJSON(data) {
            return jsonString
        }
        
        if let string = String(data: data, encoding: .utf8) {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return "\(data.count) bytes of binary data"
    }
    
    func formatAsJSON(_ data: Data) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        
        let options: JSONSerialization.WritingOptions = prettyPrint ? [.prettyPrinted, .sortedKeys] : []
        
        guard let formattedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: options),
              let formattedString = String(data: formattedData, encoding: .utf8) else {
            return nil
        }
        
        return formattedString
    }
    
    func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}

// MARK: - Predefined Loggers
extension Logger {
    /// Silent logger (no output)
    public static let silent = Logger(level: .none)
    
    /// Basic logger (errors and warnings only)
    public static let basic = Logger(level: .warning, logResponseData: false)
    
    /// Standard logger (info level)
    public static let standard = Logger(level: .info, logResponseData: false)
    
    /// Debug logger (debug level with response data)
    public static let debug = Logger(level: .debug, logResponseData: true)
    
    /// Verbose logger (all levels)
    public static let verbose = Logger(level: .verbose, logResponseData: true)
}

// MARK: - DateFormatter Extension
private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
} 