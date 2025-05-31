import Foundation

extension URLRequest {
    /// Create URLRequest with timeout configuration
    /// - Parameters:
    ///   - url: Request URL
    ///   - timeout: Timeout configuration
    /// - Returns: URLRequest with timeout applied
    public static func withTimeout(url: URL, timeout: TimeoutConfiguration) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout.requestTimeout
        return request
    }
    
    /// Get content length from headers
    public var contentLength: Int? {
        guard let lengthString = value(forHTTPHeaderField: "Content-Length"),
              let length = Int(lengthString) else {
            return nil
        }
        return length
    }
    
    /// Get content type from headers
    public var contentType: String? {
        return value(forHTTPHeaderField: "Content-Type")
    }
    
    /// Check if request has JSON content type
    public var hasJSONContentType: Bool {
        guard let contentType = contentType else { return false }
        return contentType.lowercased().contains("application/json")
    }
    
    /// Get request body size
    public var bodySize: Int {
        return httpBody?.count ?? 0
    }
    
    /// Validate request for common issues
    /// - Throws: NetworkError if validation fails
    public func validate() throws {
        guard let url = url else {
            throw NetworkError.invalidURL("URL is nil")
        }
        
        guard let scheme = url.scheme, !scheme.isEmpty else {
            throw NetworkError.invalidURL("URL scheme is missing")
        }
        
        guard scheme.lowercased() == "http" || scheme.lowercased() == "https" else {
            throw NetworkError.invalidURL("URL scheme must be http or https")
        }
        
        guard let host = url.host, !host.isEmpty else {
            throw NetworkError.invalidURL("URL host is missing")
        }
        
        if let httpMethod = httpMethod, httpMethod.isEmpty {
            throw NetworkError.invalidRequest("HTTP method is empty")
        }
        
        if let body = httpBody, !body.isEmpty {
            if contentType == nil {
                throw NetworkError.invalidRequest("Content-Type header is required for requests with body")
            }
        }
    }
    
    /// Add or update HTTP header
    /// - Parameters:
    ///   - name: Header name
    ///   - value: Header value
    public mutating func addHeader(name: String, value: String) {
        setValue(value, forHTTPHeaderField: name)
    }
    
    /// Add HTTP headers from dictionary
    /// - Parameter headers: Dictionary of headers to add
    public mutating func addHeaders(_ headers: [String: String]) {
        for (name, value) in headers {
            addHeader(name: name, value: value)
        }
    }
    
    /// Remove HTTP header
    /// - Parameter name: Header name to remove
    public mutating func removeHeader(name: String) {
        setValue(nil, forHTTPHeaderField: name)
    }
    
    /// Create a copy with modified timeout
    /// - Parameter timeout: New timeout interval
    /// - Returns: New URLRequest with updated timeout
    public func withTimeout(_ timeout: TimeInterval) -> URLRequest {
        var request = self
        request.timeoutInterval = timeout
        return request
    }
    
    /// Create a copy with additional headers
    /// - Parameter headers: Headers to add
    /// - Returns: New URLRequest with additional headers
    public func withHeaders(_ headers: [String: String]) -> URLRequest {
        var request = self
        request.addHeaders(headers)
        return request
    }
    
    /// Create a copy with updated HTTP method
    /// - Parameter method: New HTTP method
    /// - Returns: New URLRequest with updated method
    public func withMethod(_ method: String) -> URLRequest {
        var request = self
        request.httpMethod = method
        return request
    }
    
    /// Create a copy with updated body
    /// - Parameter body: New request body
    /// - Returns: New URLRequest with updated body
    public func withBody(_ body: Data) -> URLRequest {
        var request = self
        request.httpBody = body
        return request
    }
}

// MARK: - Debug Support
extension URLRequest {
    /// Pretty printed description for debugging
    public var debugDescription: String {
        var components: [String] = []
        
        if let method = httpMethod, let url = url {
            components.append("\(method) \(url.absoluteString)")
        }
        
        if let headers = allHTTPHeaderFields, !headers.isEmpty {
            components.append("Headers:")
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                components.append("  \(key): \(value)")
            }
        }
        
        if let body = httpBody, !body.isEmpty {
            components.append("Body: \(body.count) bytes")
            if let bodyString = String(data: body, encoding: .utf8) {
                components.append("Body Content: \(bodyString)")
            }
        }
        
        components.append("Timeout: \(timeoutInterval)s")
        
        return components.joined(separator: "\n")
    }
} 