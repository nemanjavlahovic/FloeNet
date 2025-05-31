import Foundation

/// Fluent builder for constructing HTTP requests
public struct RequestBuilder: Sendable {
    private var method: HTTPMethod
    private var url: URL?
    private var headers: HTTPHeaders
    private var queryParameters: [String: String]
    private var body: Data?
    private var timeout: TimeInterval?
    
    /// Initialize request builder
    public init() {
        self.method = .get
        self.url = nil
        self.headers = .empty
        self.queryParameters = [:]
        self.body = nil
        self.timeout = nil
    }
    
    /// Initialize request builder with base URL
    /// - Parameter url: Base URL for the request
    public init(url: URL) {
        self.init()
        self.url = url
    }
    
    /// Initialize request builder with URL string
    /// - Parameter urlString: URL string for the request
    /// - Throws: NetworkError.invalidURL if string is not a valid URL
    public init(url urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL("Invalid URL string: \(urlString)")
        }
        self.init(url: url)
    }
}

// MARK: - URL Configuration
extension RequestBuilder {
    /// Set the request URL
    /// - Parameter url: Request URL
    /// - Returns: Self for chaining
    public func url(_ url: URL) -> RequestBuilder {
        var builder = self
        builder.url = url
        return builder
    }
    
    /// Set the request URL from string
    /// - Parameter urlString: URL string
    /// - Returns: Self for chaining
    /// - Throws: NetworkError.invalidURL if string is not valid
    public func url(_ urlString: String) throws -> RequestBuilder {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL("Invalid URL string: \(urlString)")
        }
        return self.url(url)
    }
    
    /// Append path component to existing URL
    /// - Parameter path: Path component to append
    /// - Returns: Self for chaining
    public func path(_ path: String) -> RequestBuilder {
        guard let currentURL = url else { return self }
        var builder = self
        builder.url = currentURL.appendingPathComponent(path)
        return builder
    }
}

// MARK: - HTTP Method Configuration
extension RequestBuilder {
    /// Set request method to GET
    /// - Returns: Self for chaining
    public func get() -> RequestBuilder {
        var builder = self
        builder.method = .get
        return builder
    }
    
    /// Set request method to POST
    /// - Returns: Self for chaining
    public func post() -> RequestBuilder {
        var builder = self
        builder.method = .post
        return builder
    }
    
    /// Set request method to PUT
    /// - Returns: Self for chaining
    public func put() -> RequestBuilder {
        var builder = self
        builder.method = .put
        return builder
    }
    
    /// Set request method to PATCH
    /// - Returns: Self for chaining
    public func patch() -> RequestBuilder {
        var builder = self
        builder.method = .patch
        return builder
    }
    
    /// Set request method to DELETE
    /// - Returns: Self for chaining
    public func delete() -> RequestBuilder {
        var builder = self
        builder.method = .delete
        return builder
    }
    
    /// Set custom HTTP method
    /// - Parameter method: HTTP method
    /// - Returns: Self for chaining
    public func method(_ method: HTTPMethod) -> RequestBuilder {
        var builder = self
        builder.method = method
        return builder
    }
}

// MARK: - Header Configuration
extension RequestBuilder {
    /// Add a single header
    /// - Parameters:
    ///   - name: Header name
    ///   - value: Header value
    /// - Returns: Self for chaining
    public func header(_ name: String, _ value: String) -> RequestBuilder {
        var builder = self
        builder.headers.add(name: name, value: value)
        return builder
    }
    
    /// Add multiple headers from dictionary
    /// - Parameter headerDict: Dictionary of headers
    /// - Returns: Self for chaining
    public func headers(_ headerDict: [String: String]) -> RequestBuilder {
        var builder = self
        for (name, value) in headerDict {
            builder.headers.add(name: name, value: value)
        }
        return builder
    }
    
    /// Add HTTPHeaders object
    /// - Parameter headers: HTTPHeaders to add
    /// - Returns: Self for chaining
    public func headers(_ headers: HTTPHeaders) -> RequestBuilder {
        var builder = self
        for (name, value) in headers.dictionary {
            builder.headers.add(name: name, value: value)
        }
        return builder
    }
    
    /// Add authorization header with Bearer token
    /// - Parameter token: Bearer token
    /// - Returns: Self for chaining
    public func bearerToken(_ token: String) -> RequestBuilder {
        return header("Authorization", "Bearer \(token)")
    }
    
    /// Add basic authentication header
    /// - Parameters:
    ///   - username: Username
    ///   - password: Password
    /// - Returns: Self for chaining
    public func basicAuth(username: String, password: String) -> RequestBuilder {
        let credentials = "\(username):\(password)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        return header("Authorization", "Basic \(encodedCredentials)")
    }
    
    /// Add Content-Type header for JSON
    /// - Returns: Self for chaining
    public func jsonContentType() -> RequestBuilder {
        return header("Content-Type", "application/json")
    }
    
    /// Add Content-Type header for form data
    /// - Returns: Self for chaining
    public func formContentType() -> RequestBuilder {
        return header("Content-Type", "application/x-www-form-urlencoded")
    }
}

// MARK: - Query Parameters
extension RequestBuilder {
    /// Add a single query parameter
    /// - Parameters:
    ///   - name: Parameter name
    ///   - value: Parameter value
    /// - Returns: Self for chaining
    public func query(_ name: String, _ value: String) -> RequestBuilder {
        var builder = self
        builder.queryParameters[name] = value
        return builder
    }
    
    /// Add query parameter with integer value
    /// - Parameters:
    ///   - name: Parameter name
    ///   - value: Integer value
    /// - Returns: Self for chaining
    public func query(_ name: String, _ value: Int) -> RequestBuilder {
        return query(name, String(value))
    }
    
    /// Add query parameter with boolean value
    /// - Parameters:
    ///   - name: Parameter name
    ///   - value: Boolean value
    /// - Returns: Self for chaining
    public func query(_ name: String, _ value: Bool) -> RequestBuilder {
        return query(name, value ? "true" : "false")
    }
    
    /// Add multiple query parameters from dictionary
    /// - Parameter params: Dictionary of query parameters
    /// - Returns: Self for chaining
    public func query(_ params: [String: String]) -> RequestBuilder {
        var builder = self
        for (name, value) in params {
            builder.queryParameters[name] = value
        }
        return builder
    }
    
    /// Add multiple query parameters with mixed types
    /// - Parameter params: Dictionary of query parameters with Any values
    /// - Returns: Self for chaining
    public func query(_ params: [String: Any]) -> RequestBuilder {
        var builder = self
        for (name, value) in params {
            builder.queryParameters[name] = String(describing: value)
        }
        return builder
    }
}

// MARK: - Body Configuration
extension RequestBuilder {
    /// Set request body data
    /// - Parameter data: Body data
    /// - Returns: Self for chaining
    public func body(_ data: Data) -> RequestBuilder {
        var builder = self
        builder.body = data
        return builder
    }
    
    /// Set request body from string
    /// - Parameters:
    ///   - string: Body string
    ///   - encoding: String encoding (default: .utf8)
    /// - Returns: Self for chaining
    public func body(_ string: String, encoding: String.Encoding = .utf8) -> RequestBuilder {
        if let data = string.data(using: encoding) {
            return body(data)
        }
        return self
    }
    
    /// Set request body from Codable object as JSON
    /// - Parameters:
    ///   - object: Codable object to encode
    ///   - encoder: JSON encoder (default: JSONEncoder())
    /// - Returns: Self for chaining
    /// - Throws: EncodingError if object cannot be encoded
    public func jsonBody<T: Encodable>(_ object: T, encoder: JSONEncoder = JSONEncoder()) throws -> RequestBuilder {
        let data = try encoder.encode(object)
        return self.body(data).jsonContentType()
    }
    
    /// Set request body from form parameters
    /// - Parameter parameters: Form parameters
    /// - Returns: Self for chaining
    public func formBody(_ parameters: [String: String]) -> RequestBuilder {
        let formData = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        
        return self.body(formData).formContentType()
    }
}

// MARK: - Timeout Configuration
extension RequestBuilder {
    /// Set request timeout
    /// - Parameter timeout: Timeout interval in seconds
    /// - Returns: Self for chaining
    public func timeout(_ timeout: TimeInterval) -> RequestBuilder {
        var builder = self
        builder.timeout = timeout
        return builder
    }
    
    /// Set request timeout with convenience methods
    /// - Parameter seconds: Timeout in seconds
    /// - Returns: Self for chaining
    public func timeout(seconds: Int) -> RequestBuilder {
        return timeout(TimeInterval(seconds))
    }
    
    /// Set request timeout to 30 seconds
    /// - Returns: Self for chaining
    public func quickTimeout() -> RequestBuilder {
        return timeout(30.0)
    }
    
    /// Set request timeout to 2 minutes
    /// - Returns: Self for chaining
    public func slowTimeout() -> RequestBuilder {
        return timeout(120.0)
    }
}

// MARK: - Build Methods
extension RequestBuilder {
    /// Build the HTTPRequest
    /// - Returns: Configured HTTPRequest
    /// - Throws: NetworkError if URL is not set or invalid
    public func build() throws -> HTTPRequest {
        guard let url = url else {
            throw NetworkError.invalidURL("URL is required to build request")
        }
        
        return HTTPRequest(
            method: method,
            url: url,
            headers: headers,
            queryParameters: queryParameters,
            body: body,
            timeout: timeout
        )
    }
    
    /// Build and execute the request immediately with given client
    /// - Parameter client: HTTPClient to execute request with
    /// - Returns: HTTPResponse with Data
    /// - Throws: NetworkError on failure
    public func send(with client: HTTPClientProtocol) async throws -> HTTPResponse<Data> {
        let request = try build()
        return try await client.send(request)
    }
    
    /// Build and execute the request with JSON decoding
    /// - Parameters:
    ///   - client: HTTPClient to execute request with
    ///   - type: Type to decode response to
    ///   - decoder: JSON decoder (default: JSONDecoder())
    /// - Returns: HTTPResponse with decoded type
    /// - Throws: NetworkError on failure
    public func send<T: Decodable & Sendable>(
        with client: HTTPClientProtocol,
        expecting type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<T> {
        let request = try build()
        return try await client.send(request, expecting: type, decoder: decoder)
    }
}

// MARK: - Convenience Static Methods
extension RequestBuilder {
    /// Create request builder for GET request
    /// - Parameter url: Request URL
    /// - Returns: RequestBuilder configured for GET
    public static func get(_ url: URL) -> RequestBuilder {
        return RequestBuilder(url: url).get()
    }
    
    /// Create request builder for GET request with URL string
    /// - Parameter urlString: Request URL string
    /// - Returns: RequestBuilder configured for GET
    /// - Throws: NetworkError.invalidURL if string is invalid
    public static func get(_ urlString: String) throws -> RequestBuilder {
        return try RequestBuilder(url: urlString).get()
    }
    
    /// Create request builder for POST request
    /// - Parameter url: Request URL
    /// - Returns: RequestBuilder configured for POST
    public static func post(_ url: URL) -> RequestBuilder {
        return RequestBuilder(url: url).post()
    }
    
    /// Create request builder for POST request with URL string
    /// - Parameter urlString: Request URL string
    /// - Returns: RequestBuilder configured for POST
    /// - Throws: NetworkError.invalidURL if string is invalid
    public static func post(_ urlString: String) throws -> RequestBuilder {
        return try RequestBuilder(url: urlString).post()
    }
    
    /// Create request builder for PUT request
    /// - Parameter url: Request URL
    /// - Returns: RequestBuilder configured for PUT
    public static func put(_ url: URL) -> RequestBuilder {
        return RequestBuilder(url: url).put()
    }
    
    /// Create request builder for DELETE request
    /// - Parameter url: Request URL
    /// - Returns: RequestBuilder configured for DELETE
    public static func delete(_ url: URL) -> RequestBuilder {
        return RequestBuilder(url: url).delete()
    }
} 