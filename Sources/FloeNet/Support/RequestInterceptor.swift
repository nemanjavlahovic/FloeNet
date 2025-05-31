import Foundation

/// Protocol for intercepting and modifying requests before they are sent
public protocol RequestInterceptor: Sendable {
    /// Intercept and potentially modify a request before it's sent
    /// - Parameter request: The original HTTP request
    /// - Returns: Modified HTTP request or throws an error
    /// - Throws: NetworkError if the request should be rejected
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest
}

/// Protocol for intercepting responses after they are received
public protocol ResponseInterceptor: Sendable {
    /// Intercept and potentially modify a response after it's received
    /// - Parameter response: The HTTP response
    /// - Returns: Modified HTTP response or throws an error
    /// - Throws: NetworkError if the response should be rejected
    func intercept<T>(_ response: HTTPResponse<T>) async throws -> HTTPResponse<T>
}

// MARK: - Convenience Implementations
public struct AuthorizationInterceptor: RequestInterceptor {
    private let tokenProvider: @Sendable () async throws -> String
    private let headerName: String
    private let tokenPrefix: String
    
    /// Create an authorization interceptor
    /// - Parameters:
    ///   - tokenProvider: Async function that provides the auth token
    ///   - headerName: Header name for authorization (default: "Authorization")
    ///   - tokenPrefix: Prefix for the token (default: "Bearer ")
    public init(
        tokenProvider: @escaping @Sendable () async throws -> String,
        headerName: String = "Authorization",
        tokenPrefix: String = "Bearer "
    ) {
        self.tokenProvider = tokenProvider
        self.headerName = headerName
        self.tokenPrefix = tokenPrefix
    }
    
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        let token = try await tokenProvider()
        let authValue = "\(tokenPrefix)\(token)"
        
        var modifiedRequest = request
        modifiedRequest.headers.add(name: headerName, value: authValue)
        return modifiedRequest
    }
}

/// Interceptor that adds a user agent header
public struct UserAgentInterceptor: RequestInterceptor {
    private let userAgent: String
    
    /// Create a user agent interceptor
    /// - Parameter userAgent: User agent string to add
    public init(userAgent: String) {
        self.userAgent = userAgent
    }
    
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        var modifiedRequest = request
        modifiedRequest.headers.add(name: "User-Agent", value: userAgent)
        return modifiedRequest
    }
}

/// Interceptor that adds custom headers to all requests
public struct HeaderInterceptor: RequestInterceptor {
    private let headers: HTTPHeaders
    
    /// Create a header interceptor
    /// - Parameter headers: Headers to add to all requests
    public init(headers: HTTPHeaders) {
        self.headers = headers
    }
    
    /// Create a header interceptor with a dictionary
    /// - Parameter headerDictionary: Dictionary of headers to add
    public init(_ headerDictionary: [String: String]) {
        var headers = HTTPHeaders()
        for (name, value) in headerDictionary {
            headers.add(name: name, value: value)
        }
        self.init(headers: headers)
    }
    
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        var modifiedRequest = request
        for (name, value) in headers.dictionary {
            modifiedRequest.headers.add(name: name, value: value)
        }
        return modifiedRequest
    }
}

/// Interceptor that validates request size limits
public struct RequestSizeInterceptor: RequestInterceptor {
    private let maxSize: Int
    
    /// Create a request size interceptor
    /// - Parameter maxSize: Maximum allowed request body size in bytes
    public init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        if let bodySize = request.body?.count, bodySize > maxSize {
            throw NetworkError.requestTooLarge
        }
        return request
    }
}

/// Response interceptor that validates response size limits
public struct ResponseSizeInterceptor: ResponseInterceptor {
    private let maxSize: Int
    
    /// Create a response size interceptor
    /// - Parameter maxSize: Maximum allowed response body size in bytes
    public init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    public func intercept<T>(_ response: HTTPResponse<T>) async throws -> HTTPResponse<T> {
        if response.size > maxSize {
            throw NetworkError.responseTooLarge
        }
        return response
    }
}

/// Response interceptor that validates content type
public struct ContentTypeInterceptor: ResponseInterceptor {
    private let allowedTypes: Set<String>
    
    /// Create a content type interceptor
    /// - Parameter allowedTypes: Set of allowed content type prefixes
    public init(allowedTypes: Set<String>) {
        self.allowedTypes = allowedTypes
    }
    
    /// Create a content type interceptor for JSON only
    public static let jsonOnly = ContentTypeInterceptor(allowedTypes: ["application/json"])
    
    /// Create a content type interceptor for text types
    public static let textOnly = ContentTypeInterceptor(allowedTypes: ["text/", "application/json", "application/xml"])
    
    public func intercept<T>(_ response: HTTPResponse<T>) async throws -> HTTPResponse<T> {
        guard let contentType = response.contentType else {
            throw NetworkError.invalidResponse
        }
        
        let isAllowed = allowedTypes.contains { prefix in
            contentType.lowercased().hasPrefix(prefix.lowercased())
        }
        
        if !isAllowed {
            throw NetworkError.invalidResponse
        }
        
        return response
    }
}

/// Response interceptor that handles caching headers
public struct CacheInterceptor: ResponseInterceptor {
    /// Cache control behavior
    public enum CacheControl: Sendable {
        case validateAll
        case respectHeaders
        case ignoreHeaders
    }
    
    private let cacheControl: CacheControl
    
    /// Create a cache interceptor
    /// - Parameter cacheControl: Cache control behavior
    public init(cacheControl: CacheControl = .respectHeaders) {
        self.cacheControl = cacheControl
    }
    
    public func intercept<T>(_ response: HTTPResponse<T>) async throws -> HTTPResponse<T> {
        switch cacheControl {
        case .validateAll:
            break
        case .respectHeaders:
            if let cacheControl = response.headers["Cache-Control"], cacheControl.contains("no-cache") {
                break
            }
        case .ignoreHeaders:
            break
        }
        
        return response
    }
}

/// Composite interceptor that runs multiple request interceptors in sequence
public struct CompositeRequestInterceptor: RequestInterceptor {
    private let interceptors: [RequestInterceptor]
    
    /// Create a composite interceptor
    /// - Parameter interceptors: Array of interceptors to run in order
    public init(_ interceptors: [RequestInterceptor]) {
        self.interceptors = interceptors
    }
    
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        var currentRequest = request
        for interceptor in interceptors {
            currentRequest = try await interceptor.intercept(currentRequest)
        }
        return currentRequest
    }
}

/// Composite interceptor that runs multiple response interceptors in sequence
public struct CompositeResponseInterceptor: ResponseInterceptor {
    private let interceptors: [ResponseInterceptor]
    
    /// Create a composite response interceptor
    /// - Parameter interceptors: Array of interceptors to run in order
    public init(_ interceptors: [ResponseInterceptor]) {
        self.interceptors = interceptors
    }
    
    public func intercept<T>(_ response: HTTPResponse<T>) async throws -> HTTPResponse<T> {
        var currentResponse = response
        for interceptor in interceptors {
            currentResponse = try await interceptor.intercept(currentResponse)
        }
        return currentResponse
    }
} 