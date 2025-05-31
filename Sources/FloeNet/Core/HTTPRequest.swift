import Foundation

/// HTTP request configuration
public struct HTTPRequest: Sendable {
    /// HTTP method for the request
    public let method: HTTPMethod
    
    /// Request URL
    public let url: URL
    
    /// HTTP headers
    public let headers: HTTPHeaders
    
    /// Query parameters to append to URL
    public let queryParameters: [String: String]
    
    /// Request body data
    public let body: Data?
    
    /// Custom timeout for this request (overrides client default)
    public let timeout: TimeInterval?
    
    /// Initialize a new HTTP request
    /// - Parameters:
    ///   - method: HTTP method
    ///   - url: Request URL
    ///   - headers: HTTP headers (default: empty)
    ///   - queryParameters: Query parameters (default: empty)
    ///   - body: Request body data (default: nil)
    ///   - timeout: Custom timeout interval (default: nil, uses client default)
    public init(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
        self.timeout = timeout
    }
}

// MARK: - Convenience Initializers
extension HTTPRequest {
    /// Create a GET request
    public static func get(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        timeout: TimeInterval? = nil
    ) -> HTTPRequest {
        HTTPRequest(
            method: .get,
            url: url,
            headers: headers,
            queryParameters: queryParameters,
            timeout: timeout
        )
    }
    
    /// Create a POST request
    public static func post(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) -> HTTPRequest {
        HTTPRequest(
            method: .post,
            url: url,
            headers: headers,
            queryParameters: queryParameters,
            body: body,
            timeout: timeout
        )
    }
    
    /// Create a PUT request
    public static func put(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) -> HTTPRequest {
        HTTPRequest(
            method: .put,
            url: url,
            headers: headers,
            queryParameters: queryParameters,
            body: body,
            timeout: timeout
        )
    }
    
    /// Create a PATCH request
    public static func patch(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil
    ) -> HTTPRequest {
        HTTPRequest(
            method: .patch,
            url: url,
            headers: headers,
            queryParameters: queryParameters,
            body: body,
            timeout: timeout
        )
    }
    
    /// Create a DELETE request
    public static func delete(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        timeout: TimeInterval? = nil
    ) -> HTTPRequest {
        HTTPRequest(
            method: .delete,
            url: url,
            headers: headers,
            queryParameters: queryParameters,
            timeout: timeout
        )
    }
}

// MARK: - JSON Convenience
extension HTTPRequest {
    /// Create a request with JSON body
    public static func json<T: Encodable>(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders = .json,
        queryParameters: [String: String] = [:],
        body: T,
        encoder: JSONEncoder = JSONEncoder(),
        timeout: TimeInterval? = nil
    ) throws -> HTTPRequest {
        let data = try encoder.encode(body)
        var finalHeaders = headers
        finalHeaders.add(name: HTTPHeaders.Name.contentType, value: "application/json")
        
        return HTTPRequest(
            method: method,
            url: url,
            headers: finalHeaders,
            queryParameters: queryParameters,
            body: data,
            timeout: timeout
        )
    }
}

// MARK: - Request Validation
extension HTTPRequest {
    /// Validate the request configuration
    public func validate() throws {
        // Check if body is provided for methods that don't support it
        if !method.allowsRequestBody && body != nil {
            throw NetworkError.invalidRequest("HTTP \(method.rawValue) requests should not include a body")
        }
        
        // Validate URL scheme
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw NetworkError.invalidURL("URL must use HTTP or HTTPS scheme")
        }
        
        // Validate timeout
        if let timeout = timeout, timeout <= 0 {
            throw NetworkError.invalidRequest("Timeout must be greater than 0")
        }
    }
    
    /// Build URLRequest from HTTPRequest
    public func urlRequest() throws -> URLRequest {
        try validate()
        
        // Build URL with query parameters
        let finalURL = try buildURLWithQueryParameters()
        
        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = method.rawValue
        urlRequest.httpBody = body
        
        // Set headers
        for (name, value) in headers.dictionary {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        
        // Set timeout if specified
        if let timeout = timeout {
            urlRequest.timeoutInterval = timeout
        }
        
        return urlRequest
    }
    
    private func buildURLWithQueryParameters() throws -> URL {
        guard !queryParameters.isEmpty else { return url }
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL("Cannot parse URL components")
        }
        
        var queryItems = components.queryItems ?? []
        
        for (key, value) in queryParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            throw NetworkError.invalidURL("Cannot build URL with query parameters")
        }
        
        return finalURL
    }
} 