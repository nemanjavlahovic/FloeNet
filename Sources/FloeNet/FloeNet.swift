// FloeNet - A Mini Networking Layer for Swift
// Version 0.2 - Phase 3 Features (Request Builder, Enhanced Testing)

@_exported import Foundation

// MARK: - Core Networking Types
/// HTTP client for making network requests
public typealias FloeHTTPClient = HTTPClient

/// HTTP request configuration
public typealias FloeHTTPRequest = HTTPRequest

/// HTTP response container
public typealias FloeHTTPResponse<T> = HTTPResponse<T>

/// HTTP methods
public typealias FloeHTTPMethod = HTTPMethod

/// HTTP headers
public typealias FloeHTTPHeaders = HTTPHeaders

/// Network errors
public typealias FloeNetworkError = NetworkError

/// Empty response type for requests that don't return data
public typealias FloeEmptyResponse = EmptyResponse

/// Request builder for fluent request construction
public typealias FloeRequestBuilder = RequestBuilder

// MARK: - Convenience
/// Default FloeNet client instance for simple usage
public let FloeNet = HTTPClient()

/// Quick access to common HTTP methods
public struct Floe {
    /// Shared HTTP client instance
    public static let client = HTTPClient()
    
    /// Create a new request builder
    public static func request() -> RequestBuilder {
        return RequestBuilder()
    }
    
    /// Create a request builder with URL
    public static func request(url: URL) -> RequestBuilder {
        return RequestBuilder(url: url)
    }
    
    /// Create a request builder with URL string
    public static func request(url urlString: String) throws -> RequestBuilder {
        return try RequestBuilder(url: urlString)
    }
    
    /// Perform GET request
    public static func get(url: URL) async throws -> HTTPResponse<Data> {
        return try await client.get(url: url)
    }
    
    /// Perform GET request with JSON decoding
    public static func get<T: Decodable & Sendable>(
        url: URL,
        expecting type: T.Type
    ) async throws -> HTTPResponse<T> {
        return try await client.get(url: url, expecting: type)
    }
    
    /// Perform POST request with JSON body
    public static func post<T: Encodable>(
        url: URL,
        body: T
    ) async throws -> HTTPResponse<Data> {
        return try await client.post(url: url, body: body)
    }
    
    /// Perform POST request with JSON body and response decoding
    public static func post<RequestBody: Encodable, ResponseBody: Decodable & Sendable>(
        url: URL,
        body: RequestBody,
        expecting responseType: ResponseBody.Type
    ) async throws -> HTTPResponse<ResponseBody> {
        return try await client.post(url: url, body: body, expecting: responseType)
    }
}

// MARK: - Global Convenience Functions
/// Create a new request builder (global convenience)
public func buildRequest() -> RequestBuilder {
    return RequestBuilder()
}

/// Create a request builder with URL (global convenience)
public func buildRequest(url: URL) -> RequestBuilder {
    return RequestBuilder(url: url)
}

/// Create a request builder with URL string (global convenience)
public func buildRequest(url urlString: String) throws -> RequestBuilder {
    return try RequestBuilder(url: urlString)
}
