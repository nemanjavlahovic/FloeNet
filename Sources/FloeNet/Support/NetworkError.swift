import Foundation

/// Comprehensive error types for network operations
public enum NetworkError: Error, Sendable {
    /// No internet connection is available
    case noInternetConnection
    
    /// Request timed out
    case requestTimeout
    
    /// Invalid URL provided
    case invalidURL(String)
    
    /// Invalid request configuration
    case invalidRequest(String)
    
    /// HTTP status code errors
    case httpError(statusCode: Int, data: Data?)
    
    /// Client errors (4xx)
    case clientError(statusCode: Int, data: Data?)
    
    /// Server errors (5xx)
    case serverError(statusCode: Int, data: Data?)
    
    /// JSON decoding failed
    case decodingError(DecodingError)
    
    /// JSON encoding failed
    case encodingError(EncodingError)
    
    /// SSL/TLS security errors
    case securityError(Error)
    
    /// Request was cancelled
    case cancelled
    
    /// Unknown or unexpected error
    case unknown(Error)
    
    /// Response data is invalid or corrupted
    case invalidResponse
    
    /// Request body is too large
    case requestTooLarge
    
    /// Response body is too large
    case responseTooLarge
}

// MARK: - Convenience Properties
extension NetworkError {
    /// Whether this error indicates a network connectivity issue
    public var isConnectivityError: Bool {
        switch self {
        case .noInternetConnection, .requestTimeout:
            return true
        default:
            return false
        }
    }
    
    /// Whether this error is a client error (4xx)
    public var isClientError: Bool {
        switch self {
        case .clientError(let statusCode, _):
            return statusCode >= 400 && statusCode < 500
        case .httpError(let statusCode, _):
            return statusCode >= 400 && statusCode < 500
        default:
            return false
        }
    }
    
    /// Whether this error is a server error (5xx)
    public var isServerError: Bool {
        switch self {
        case .serverError(let statusCode, _):
            return statusCode >= 500 && statusCode < 600
        case .httpError(let statusCode, _):
            return statusCode >= 500 && statusCode < 600
        default:
            return false
        }
    }
    
    /// Whether this error might be resolved by retrying
    public var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .requestTimeout, .serverError:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500 || statusCode == 429 || statusCode == 408
        default:
            return false
        }
    }
    
    /// HTTP status code if applicable
    public var statusCode: Int? {
        switch self {
        case .httpError(let code, _),
             .clientError(let code, _),
             .serverError(let code, _):
            return code
        default:
            return nil
        }
    }
    
    /// Response data if available
    public var responseData: Data? {
        switch self {
        case .httpError(_, let data),
             .clientError(_, let data),
             .serverError(_, let data):
            return data
        default:
            return nil
        }
    }
}

// MARK: - LocalizedError
extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection available"
        case .requestTimeout:
            return "Request timed out"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .httpError(let statusCode, _):
            return "HTTP error \(statusCode)"
        case .clientError(let statusCode, _):
            return "Client error \(statusCode)"
        case .serverError(let statusCode, _):
            return "Server error \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .securityError(let error):
            return "Security error: \(error.localizedDescription)"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response received"
        case .requestTooLarge:
            return "Request body is too large"
        case .responseTooLarge:
            return "Response body is too large"
        }
    }
}

// MARK: - Factory Methods
extension NetworkError {
    /// Create NetworkError from URLError
    public static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .requestTimeout
        case .cancelled:
            return .cancelled
        case .secureConnectionFailed, .serverCertificateUntrusted:
            return .securityError(urlError)
        default:
            return .unknown(urlError)
        }
    }
    
    /// Create NetworkError from HTTP response
    public static func from(response: HTTPURLResponse, data: Data?) -> NetworkError {
        let statusCode = response.statusCode
        
        switch statusCode {
        case 400..<500:
            return .clientError(statusCode: statusCode, data: data)
        case 500..<600:
            return .serverError(statusCode: statusCode, data: data)
        default:
            return .httpError(statusCode: statusCode, data: data)
        }
    }
} 