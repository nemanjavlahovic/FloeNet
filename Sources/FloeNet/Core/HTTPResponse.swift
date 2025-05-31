import Foundation

/// HTTP response container with raw data and decoded object support
public struct HTTPResponse<T>: Sendable where T: Sendable {
    /// Raw response data
    public let data: Data
    
    /// HTTP status code
    public let statusCode: Int
    
    /// Response headers
    public let headers: HTTPHeaders
    
    /// Original URL response
    public let urlResponse: HTTPURLResponse
    
    /// Decoded response object (if successful)
    public let value: T?
    
    /// Request duration in seconds
    public let duration: TimeInterval
    
    /// Initialize with raw response data
    public init(data: Data, urlResponse: HTTPURLResponse, value: T? = nil, duration: TimeInterval = 0) {
        self.data = data
        self.statusCode = urlResponse.statusCode
        self.urlResponse = urlResponse
        self.value = value
        self.duration = duration
        
        // Convert response headers
        var responseHeaders = HTTPHeaders()
        for (key, value) in urlResponse.allHeaderFields {
            if let keyString = key as? String, let valueString = value as? String {
                responseHeaders.add(name: keyString, value: valueString)
            }
        }
        self.headers = responseHeaders
    }
}

// MARK: - Response Validation
extension HTTPResponse {
    /// Whether the response indicates success (2xx status code)
    public var isSuccess: Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
    /// Whether the response indicates a client error (4xx status code)
    public var isClientError: Bool {
        return statusCode >= 400 && statusCode < 500
    }
    
    /// Whether the response indicates a server error (5xx status code)
    public var isServerError: Bool {
        return statusCode >= 500 && statusCode < 600
    }
    
    /// Validate response status code and throw error if not successful
    public func validate() throws {
        guard isSuccess else {
            throw NetworkError.from(response: urlResponse, data: data)
        }
    }
}

// MARK: - Data Response (when T is Data)
extension HTTPResponse where T == Data {
    /// Create a data response
    public static func data(data: Data, urlResponse: HTTPURLResponse, duration: TimeInterval = 0) -> HTTPResponse<Data> {
        HTTPResponse<Data>(data: data, urlResponse: urlResponse, value: data, duration: duration)
    }
}

// MARK: - String Response
extension HTTPResponse where T == String {
    /// Create a string response
    public static func string(data: Data, urlResponse: HTTPURLResponse, encoding: String.Encoding = .utf8, duration: TimeInterval = 0) -> HTTPResponse<String> {
        let string = String(data: data, encoding: encoding)
        return HTTPResponse<String>(data: data, urlResponse: urlResponse, value: string, duration: duration)
    }
}

// MARK: - Empty Response (for requests that don't return data)
public struct EmptyResponse: Sendable {}

extension HTTPResponse where T == EmptyResponse {
    /// Create an empty response (for requests like DELETE that may not return data)
    public static func empty(data: Data, urlResponse: HTTPURLResponse, duration: TimeInterval = 0) -> HTTPResponse<EmptyResponse> {
        HTTPResponse<EmptyResponse>(data: data, urlResponse: urlResponse, value: EmptyResponse(), duration: duration)
    }
}

// MARK: - JSON Decoding Support
extension HTTPResponse {
    /// Decode JSON response to specified type
    public func decode<U: Decodable>(
        to type: U.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> HTTPResponse<U> {
        try validate()
        
        guard !data.isEmpty else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let decodedValue = try decoder.decode(type, from: data)
            return HTTPResponse<U>(data: data, urlResponse: urlResponse, value: decodedValue, duration: duration)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    /// Decode JSON response using the response's generic type (if T is Decodable)
    public func decode(using decoder: JSONDecoder = JSONDecoder()) throws -> T where T: Decodable {
        try validate()
        
        guard !data.isEmpty else {
            throw NetworkError.invalidResponse
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}

// MARK: - Convenience Properties
extension HTTPResponse {
    /// Response as UTF-8 string
    public var stringValue: String? {
        String(data: data, encoding: .utf8)
    }
    
    /// Response size in bytes
    public var size: Int {
        data.count
    }
    
    /// Content type from headers
    public var contentType: String? {
        headers[HTTPHeaders.Name.contentType]
    }
    
    /// Content length from headers
    public var contentLength: String? {
        headers[HTTPHeaders.Name.contentLength]
    }
} 
