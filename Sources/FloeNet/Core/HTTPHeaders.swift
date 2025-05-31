import Foundation

/// HTTP headers container with case-insensitive key handling
public struct HTTPHeaders: Sendable {
    private var headers: [String: String] = [:]
    
    /// Initialize empty headers
    public init() {}
    
    /// Initialize with a dictionary of headers
    public init(_ dictionary: [String: String]) {
        for (key, value) in dictionary {
            headers[key.lowercased()] = value
        }
    }
    
    /// Initialize with an array of header tuples
    public init(_ array: [(String, String)]) {
        for (key, value) in array {
            headers[key.lowercased()] = value
        }
    }
    
    /// Get header value for key (case-insensitive)
    public subscript(key: String) -> String? {
        get { headers[key.lowercased()] }
        set { headers[key.lowercased()] = newValue }
    }
    
    /// Add a header
    public mutating func add(name: String, value: String) {
        headers[name.lowercased()] = value
    }
    
    /// Remove a header
    public mutating func remove(name: String) {
        headers.removeValue(forKey: name.lowercased())
    }
    
    /// Get all headers as dictionary with original casing preserved where possible
    public var dictionary: [String: String] {
        headers
    }
    
    /// Check if headers contain a specific key
    public func contains(_ key: String) -> Bool {
        headers.keys.contains(key.lowercased())
    }
    
    /// All header names
    public var names: [String] {
        Array(headers.keys)
    }
    
    /// Check if headers are empty
    public var isEmpty: Bool {
        headers.isEmpty
    }
}

// MARK: - ExpressibleByDictionaryLiteral
extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements)
    }
}

// MARK: - Common Headers
extension HTTPHeaders {
    public static let empty = HTTPHeaders()
    
    /// Content-Type: application/json
    public static let json = HTTPHeaders(["Content-Type": "application/json"])
    
    /// Content-Type: application/x-www-form-urlencoded
    public static let formURLEncoded = HTTPHeaders(["Content-Type": "application/x-www-form-urlencoded"])
    
    /// Accept: application/json
    public static let acceptJSON = HTTPHeaders(["Accept": "application/json"])
}

// MARK: - Common Header Names
extension HTTPHeaders {
    public struct Name {
        public static let authorization = "Authorization"
        public static let contentType = "Content-Type"
        public static let contentLength = "Content-Length"
        public static let accept = "Accept"
        public static let userAgent = "User-Agent"
        public static let cacheControl = "Cache-Control"
        public static let acceptLanguage = "Accept-Language"
        public static let acceptEncoding = "Accept-Encoding"
    }
} 