import Foundation

/// Protocol for HTTP client to enable mocking
public protocol HTTPClientProtocol: Sendable {
    /// Send HTTP request and return raw data response
    func send(_ request: HTTPRequest) async throws -> HTTPResponse<Data>
    
    /// Send HTTP request and decode JSON response
    func send<T: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting type: T.Type,
        decoder: JSONDecoder
    ) async throws -> HTTPResponse<T>
    
    /// Send HTTP request for empty response
    func sendEmpty(_ request: HTTPRequest) async throws -> HTTPResponse<EmptyResponse>
    
    /// Send HTTP request and return string response
    func sendString(
        _ request: HTTPRequest,
        encoding: String.Encoding
    ) async throws -> HTTPResponse<String>
}

// MARK: - HTTPClient Protocol Conformance
extension HTTPClient: HTTPClientProtocol {}

/// Mock HTTP client for testing
public final class MockHTTPClient: HTTPClientProtocol, @unchecked Sendable {
    
    /// Mock response definition
    public struct MockResponse: Sendable {
        public let statusCode: Int
        public let headers: [String: String]
        public let data: Data
        public let delay: TimeInterval
        public let error: NetworkError?
        
        public init(
            statusCode: Int = 200,
            headers: [String: String] = [:],
            data: Data = Data(),
            delay: TimeInterval = 0.0,
            error: NetworkError? = nil
        ) {
            self.statusCode = statusCode
            self.headers = headers
            self.data = data
            self.delay = delay
            self.error = error
        }
        
        /// Create successful JSON response
        public static func json<T: Encodable>(
            _ object: T,
            statusCode: Int = 200,
            headers: [String: String] = [:],
            delay: TimeInterval = 0.0,
            encoder: JSONEncoder = JSONEncoder()
        ) throws -> MockResponse {
            let data = try encoder.encode(object)
            var jsonHeaders = headers
            jsonHeaders["Content-Type"] = "application/json"
            
            return MockResponse(
                statusCode: statusCode,
                headers: jsonHeaders,
                data: data,
                delay: delay
            )
        }
        
        /// Create error response
        public static func error(
            _ error: NetworkError,
            delay: TimeInterval = 0.0
        ) -> MockResponse {
            return MockResponse(
                statusCode: 500,
                headers: [:],
                data: Data(),
                delay: delay,
                error: error
            )
        }
        
        /// Create timeout response
        public static func timeout(delay: TimeInterval = 1.0) -> MockResponse {
            return error(.requestTimeout, delay: delay)
        }
        
        /// Create not found response
        public static func notFound(delay: TimeInterval = 0.0) -> MockResponse {
            return MockResponse(
                statusCode: 404,
                headers: [:],
                data: Data(),
                delay: delay
            )
        }
        
        /// Create unauthorized response
        public static func unauthorized(delay: TimeInterval = 0.0) -> MockResponse {
            return MockResponse(
                statusCode: 401,
                headers: [:],
                data: Data(),
                delay: delay
            )
        }
    }
    
    /// Request matcher for stub matching
    public struct RequestMatcher: Sendable {
        public let method: HTTPMethod?
        public let url: URL?
        public let urlPattern: String?
        public let headers: [String: String]?
        public let bodyMatcher: (@Sendable (Data?) -> Bool)?
        
        public init(
            method: HTTPMethod? = nil,
            url: URL? = nil,
            urlPattern: String? = nil,
            headers: [String: String]? = nil,
            bodyMatcher: (@Sendable (Data?) -> Bool)? = nil
        ) {
            self.method = method
            self.url = url
            self.urlPattern = urlPattern
            self.headers = headers
            self.bodyMatcher = bodyMatcher
        }
        
        /// Create matcher for exact URL
        public static func url(_ url: URL) -> RequestMatcher {
            return RequestMatcher(url: url)
        }
        
        /// Create matcher for URL pattern
        public static func urlPattern(_ pattern: String) -> RequestMatcher {
            return RequestMatcher(urlPattern: pattern)
        }
        
        /// Create matcher for HTTP method
        public static func method(_ method: HTTPMethod) -> RequestMatcher {
            return RequestMatcher(method: method)
        }
        
        /// Create matcher for GET requests
        public static var get: RequestMatcher {
            return method(.get)
        }
        
        /// Create matcher for POST requests
        public static var post: RequestMatcher {
            return method(.post)
        }
        
        /// Check if request matches this matcher
        public func matches(_ request: HTTPRequest) -> Bool {
            // Check method
            if let method = method, request.method != method {
                return false
            }
            
            // Check exact URL
            if let url = url, request.url != url {
                return false
            }
            
            // Check URL pattern
            if let pattern = urlPattern {
                let urlString = request.url.absoluteString
                if !urlString.contains(pattern) {
                    return false
                }
            }
            
            // Check headers
            if let headers = headers {
                for (name, value) in headers {
                    if request.headers[name] != value {
                        return false
                    }
                }
            }
            
            // Check body
            if let bodyMatcher = bodyMatcher {
                if !bodyMatcher(request.body) {
                    return false
                }
            }
            
            return true
        }
    }
    
    /// Stubbed response configuration
    public struct Stub: Sendable {
        public let matcher: RequestMatcher
        public let responses: [MockResponse]
        public let repeatLast: Bool
        
        private let callCount = AtomicCounter()
        
        public init(
            matcher: RequestMatcher,
            responses: [MockResponse],
            repeatLast: Bool = true
        ) {
            self.matcher = matcher
            self.responses = responses
            self.repeatLast = repeatLast
        }
        
        public init(
            matcher: RequestMatcher,
            response: MockResponse
        ) {
            self.init(matcher: matcher, responses: [response], repeatLast: true)
        }
        
        public func nextResponse() -> MockResponse? {
            let count = callCount.increment()
            
            if count <= responses.count {
                return responses[count - 1]
            } else if repeatLast && !responses.isEmpty {
                return responses.last
            } else {
                return nil
            }
        }
    }
    
    private var stubs: [Stub] = []
    private var requests: [HTTPRequest] = []
    private let queue = DispatchQueue(label: "MockHTTPClient.queue", attributes: .concurrent)
    
    /// Initialize mock client
    public init() {}
    
    /// Add stub response for matching requests
    /// - Parameter stub: Stub configuration
    public func stub(_ stub: Stub) {
        queue.async(flags: .barrier) {
            self.stubs.append(stub)
        }
    }
    
    /// Add stub response with matcher and response
    /// - Parameters:
    ///   - matcher: Request matcher
    ///   - response: Mock response
    public func stub(_ matcher: RequestMatcher, response: MockResponse) {
        stub(Stub(matcher: matcher, response: response))
    }
    
    /// Add stub response with URL and response
    /// - Parameters:
    ///   - url: URL to match
    ///   - response: Mock response
    public func stub(url: URL, response: MockResponse) {
        stub(.url(url), response: response)
    }
    
    /// Add stub response sequence
    /// - Parameters:
    ///   - matcher: Request matcher
    ///   - responses: Array of responses to return in sequence
    ///   - repeatLast: Whether to repeat the last response after sequence ends
    public func stubSequence(
        _ matcher: RequestMatcher,
        responses: [MockResponse],
        repeatLast: Bool = true
    ) {
        stub(Stub(matcher: matcher, responses: responses, repeatLast: repeatLast))
    }
    
    /// Clear all stubs
    public func clearStubs() {
        queue.async(flags: .barrier) {
            self.stubs.removeAll()
        }
    }
    
    /// Get all recorded requests
    public func recordedRequests() -> [HTTPRequest] {
        return queue.sync {
            return requests
        }
    }
    
    /// Get request count
    public func requestCount() -> Int {
        return queue.sync {
            return requests.count
        }
    }
    
    /// Clear recorded requests
    public func clearRequests() {
        queue.async(flags: .barrier) {
            self.requests.removeAll()
        }
    }
    
    /// Reset both stubs and requests
    public func reset() {
        queue.async(flags: .barrier) {
            self.stubs.removeAll()
            self.requests.removeAll()
        }
    }
}

// MARK: - HTTPClientProtocol Implementation
extension MockHTTPClient {
    public func send(_ request: HTTPRequest) async throws -> HTTPResponse<Data> {
        // Record the request
        queue.async(flags: .barrier) {
            self.requests.append(request)
        }
        
        // Find matching stub
        let matchingStub = queue.sync {
            return stubs.first { $0.matcher.matches(request) }
        }
        
        guard let stub = matchingStub,
              let mockResponse = stub.nextResponse() else {
            throw NetworkError.noInternetConnection
        }
        
        // Apply delay if specified
        if mockResponse.delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockResponse.delay * 1_000_000_000))
        }
        
        // Return error if specified
        if let error = mockResponse.error {
            throw error
        }
        
        // Create mock HTTPURLResponse
        let urlResponse = HTTPURLResponse(
            url: request.url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )!
        
        return HTTPResponse.data(data: mockResponse.data, urlResponse: urlResponse)
    }
    
    public func send<T: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<T> {
        let dataResponse = try await send(request)
        return try dataResponse.decode(to: type, using: decoder)
    }
    
    public func sendEmpty(_ request: HTTPRequest) async throws -> HTTPResponse<EmptyResponse> {
        let dataResponse = try await send(request)
        return HTTPResponse.empty(data: dataResponse.data, urlResponse: dataResponse.urlResponse)
    }
    
    public func sendString(
        _ request: HTTPRequest,
        encoding: String.Encoding = .utf8
    ) async throws -> HTTPResponse<String> {
        let dataResponse = try await send(request)
        return HTTPResponse.string(data: dataResponse.data, urlResponse: dataResponse.urlResponse, encoding: encoding)
    }
}

// MARK: - Convenience Testing Methods
extension MockHTTPClient {
    /// Verify that a request was made matching the criteria
    /// - Parameter matcher: Request matcher
    /// - Returns: True if matching request was found
    public func verify(_ matcher: RequestMatcher) -> Bool {
        return recordedRequests().contains { matcher.matches($0) }
    }
    
    /// Verify request count
    /// - Parameter count: Expected request count
    /// - Returns: True if request count matches
    public func verify(requestCount count: Int) -> Bool {
        return requestCount() == count
    }
    
    /// Get requests matching criteria
    /// - Parameter matcher: Request matcher
    /// - Returns: Array of matching requests
    public func requests(matching matcher: RequestMatcher) -> [HTTPRequest] {
        return recordedRequests().filter { matcher.matches($0) }
    }
    
    /// Check if no requests were made
    /// - Returns: True if no requests recorded
    public func verifyNoRequests() -> Bool {
        return requestCount() == 0
    }
}

// MARK: - Helper Types
private final class AtomicCounter: @unchecked Sendable {
    private var value: Int = 0
    private let lock = NSLock()
    
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
    
    func get() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
} 