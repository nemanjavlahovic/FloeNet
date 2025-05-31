import Foundation

/// HTTP methods supported by FloeNet
public enum HTTPMethod: String, CaseIterable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"
}

extension HTTPMethod {
    /// Whether this HTTP method typically includes a request body
    public var allowsRequestBody: Bool {
        switch self {
        case .get, .head, .delete, .options, .trace, .connect:
            return false
        case .post, .put, .patch:
            return true
        }
    }
    
    /// Whether this HTTP method is considered idempotent
    public var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete, .head, .options, .trace:
            return true
        case .post, .patch, .connect:
            return false
        }
    }
} 