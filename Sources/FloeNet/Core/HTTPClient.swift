import Foundation

/// Main HTTP client for making network requests
public final class HTTPClient: Sendable {
    private let urlSession: URLSession
    private let defaultTimeout: TimeInterval
    
    /// Initialize HTTP client with custom URL session and timeout
    /// - Parameters:
    ///   - urlSession: Custom URLSession (default: .shared)
    ///   - defaultTimeout: Default timeout for requests (default: 60 seconds)
    public init(
        urlSession: URLSession = .shared,
        defaultTimeout: TimeInterval = 60.0
    ) {
        self.urlSession = urlSession
        self.defaultTimeout = defaultTimeout
    }
    
    /// Create HTTP client with custom configuration
    /// - Parameter configuration: URLSessionConfiguration
    /// - Returns: HTTPClient instance
    public static func with(configuration: URLSessionConfiguration) -> HTTPClient {
        let session = URLSession(configuration: configuration)
        return HTTPClient(urlSession: session)
    }
}

// MARK: - Main Request Methods
extension HTTPClient {
    /// Send HTTP request and return raw data response
    /// - Parameter request: HTTP request to send
    /// - Returns: HTTPResponse with Data
    /// - Throws: NetworkError on failure
    public func send(_ request: HTTPRequest) async throws -> HTTPResponse<Data> {
        do {
            let urlRequest = try request.urlRequest()
            
            var finalRequest = urlRequest
            if finalRequest.timeoutInterval == 60.0 {
                finalRequest.timeoutInterval = request.timeout ?? defaultTimeout
            }
            
            let (data, response) = try await urlSession.data(for: finalRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            let httpResponseData = HTTPResponse.data(data: data, urlResponse: httpResponse)
            try httpResponseData.validate()
            
            return httpResponseData
            
        } catch let urlError as URLError {
            throw NetworkError.from(urlError)
        } catch let networkError as NetworkError {
            throw networkError
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    /// Send HTTP request and decode JSON response
    /// - Parameters:
    ///   - request: HTTP request to send
    ///   - type: Type to decode response to
    ///   - decoder: JSON decoder (default: JSONDecoder())
    /// - Returns: HTTPResponse with decoded type
    /// - Throws: NetworkError on failure
    public func send<T: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<T> {
        let dataResponse = try await send(request)
        return try dataResponse.decode(to: type, using: decoder)
    }
    
    /// Send HTTP request for empty response (like DELETE operations)
    /// - Parameter request: HTTP request to send
    /// - Returns: HTTPResponse with EmptyResponse
    /// - Throws: NetworkError on failure
    public func sendEmpty(_ request: HTTPRequest) async throws -> HTTPResponse<EmptyResponse> {
        let dataResponse = try await send(request)
        return HTTPResponse.empty(data: dataResponse.data, urlResponse: dataResponse.urlResponse)
    }
    
    /// Send HTTP request and return string response
    /// - Parameters:
    ///   - request: HTTP request to send
    ///   - encoding: String encoding (default: .utf8)
    /// - Returns: HTTPResponse with String
    /// - Throws: NetworkError on failure
    public func sendString(
        _ request: HTTPRequest,
        encoding: String.Encoding = .utf8
    ) async throws -> HTTPResponse<String> {
        let dataResponse = try await send(request)
        return HTTPResponse.string(data: dataResponse.data, urlResponse: dataResponse.urlResponse, encoding: encoding)
    }
}

// MARK: - Convenience Methods
extension HTTPClient {
    /// Perform GET request
    /// - Parameters:
    ///   - url: Request URL
    ///   - headers: HTTP headers
    ///   - queryParameters: Query parameters
    /// - Returns: HTTPResponse with Data
    public func get(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:]
    ) async throws -> HTTPResponse<Data> {
        let request = HTTPRequest.get(url: url, headers: headers, queryParameters: queryParameters)
        return try await send(request)
    }
    
    /// Perform GET request with JSON decoding
    /// - Parameters:
    ///   - url: Request URL
    ///   - headers: HTTP headers
    ///   - queryParameters: Query parameters
    ///   - type: Type to decode response to
    ///   - decoder: JSON decoder
    /// - Returns: HTTPResponse with decoded type
    public func get<T: Decodable & Sendable>(
        url: URL,
        headers: HTTPHeaders = .empty,
        queryParameters: [String: String] = [:],
        expecting type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<T> {
        let request = HTTPRequest.get(url: url, headers: headers, queryParameters: queryParameters)
        return try await send(request, expecting: type, decoder: decoder)
    }
    
    /// Perform POST request with JSON body
    /// - Parameters:
    ///   - url: Request URL
    ///   - body: Encodable object to send as JSON
    ///   - headers: HTTP headers
    ///   - encoder: JSON encoder
    /// - Returns: HTTPResponse with Data
    public func post<T: Encodable>(
        url: URL,
        body: T,
        headers: HTTPHeaders = .json,
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> HTTPResponse<Data> {
        let request = try HTTPRequest.json(method: .post, url: url, headers: headers, body: body, encoder: encoder)
        return try await send(request)
    }
    
    /// Perform POST request with JSON body and response decoding
    /// - Parameters:
    ///   - url: Request URL
    ///   - body: Encodable object to send as JSON
    ///   - headers: HTTP headers
    ///   - responseType: Type to decode response to
    ///   - encoder: JSON encoder
    ///   - decoder: JSON decoder
    /// - Returns: HTTPResponse with decoded response type
    public func post<RequestBody: Encodable, ResponseBody: Decodable & Sendable>(
        url: URL,
        body: RequestBody,
        headers: HTTPHeaders = .json,
        expecting responseType: ResponseBody.Type,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<ResponseBody> {
        let request = try HTTPRequest.json(method: .post, url: url, headers: headers, body: body, encoder: encoder)
        return try await send(request, expecting: responseType, decoder: decoder)
    }
    
    /// Perform PUT request with JSON body and response decoding
    /// - Parameters:
    ///   - url: Request URL
    ///   - body: Encodable object to send as JSON
    ///   - headers: HTTP headers
    ///   - responseType: Type to decode response to
    ///   - encoder: JSON encoder
    ///   - decoder: JSON decoder
    /// - Returns: HTTPResponse with decoded response type
    public func put<RequestBody: Encodable, ResponseBody: Decodable & Sendable>(
        url: URL,
        body: RequestBody,
        headers: HTTPHeaders = .json,
        expecting responseType: ResponseBody.Type,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<ResponseBody> {
        let request = try HTTPRequest.json(method: .put, url: url, headers: headers, body: body, encoder: encoder)
        return try await send(request, expecting: responseType, decoder: decoder)
    }
    
    /// Perform PATCH request with JSON body and response decoding
    /// - Parameters:
    ///   - url: Request URL
    ///   - body: Encodable object to send as JSON
    ///   - headers: HTTP headers
    ///   - responseType: Type to decode response to
    ///   - encoder: JSON encoder
    ///   - decoder: JSON decoder
    /// - Returns: HTTPResponse with decoded response type
    public func patch<RequestBody: Encodable, ResponseBody: Decodable & Sendable>(
        url: URL,
        body: RequestBody,
        headers: HTTPHeaders = .json,
        expecting responseType: ResponseBody.Type,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> HTTPResponse<ResponseBody> {
        let request = try HTTPRequest.json(method: .patch, url: url, headers: headers, body: body, encoder: encoder)
        return try await send(request, expecting: responseType, decoder: decoder)
    }
    
    /// Perform DELETE request
    /// - Parameters:
    ///   - url: Request URL
    ///   - headers: HTTP headers
    /// - Returns: HTTPResponse with EmptyResponse
    public func delete(
        url: URL,
        headers: HTTPHeaders = .empty
    ) async throws -> HTTPResponse<EmptyResponse> {
        let request = HTTPRequest.delete(url: url, headers: headers)
        return try await sendEmpty(request)
    }
}

// MARK: - Result-based API (for easier error handling)
extension HTTPClient {
    /// Send request and return Result type
    /// - Parameter request: HTTP request to send
    /// - Returns: Result with HTTPResponse<Data> or NetworkError
    public func sendRequest(_ request: HTTPRequest) async -> Result<HTTPResponse<Data>, NetworkError> {
        do {
            let response = try await send(request)
            return .success(response)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    /// Send request with JSON decoding and return Result type
    /// - Parameters:
    ///   - request: HTTP request to send
    ///   - type: Type to decode response to
    ///   - decoder: JSON decoder
    /// - Returns: Result with HTTPResponse<T> or NetworkError
    public func sendRequest<T: Decodable & Sendable>(
        _ request: HTTPRequest,
        expecting type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async -> Result<HTTPResponse<T>, NetworkError> {
        do {
            let response = try await send(request, expecting: type, decoder: decoder)
            return .success(response)
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error))
        }
    }
} 