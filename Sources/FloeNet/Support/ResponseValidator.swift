import Foundation

/// Protocol for validating HTTP responses
public protocol ResponseValidator: Sendable {
    /// Validate an HTTP response
    /// - Parameter response: The HTTP response to validate
    /// - Throws: NetworkError if validation fails
    func validate<T>(_ response: HTTPResponse<T>) throws
}

/// Default response validator that checks status codes
public struct StatusCodeValidator: ResponseValidator {
    private let acceptableStatusCodes: Set<Int>
    
    /// Create a status code validator
    /// - Parameter acceptableStatusCodes: Set of acceptable status codes
    public init(acceptableStatusCodes: Set<Int>) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }
    
    /// Create a validator for success status codes (200-299)
    public static let success = StatusCodeValidator(acceptableStatusCodes: Set(200..<300))
    
    /// Create a validator for success and redirection codes (200-399)
    public static let successAndRedirection = StatusCodeValidator(acceptableStatusCodes: Set(200..<400))
    
    /// Create a validator that accepts any status code
    public static let any = StatusCodeValidator(acceptableStatusCodes: Set(100..<600))
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        guard acceptableStatusCodes.contains(response.statusCode) else {
            throw NetworkError.from(response: response.urlResponse, data: response.data)
        }
    }
}

/// Validator that checks content type headers
public struct ContentTypeValidator: ResponseValidator {
    private let expectedContentTypes: Set<String>
    private let strict: Bool
    
    /// Create a content type validator
    /// - Parameters:
    ///   - expectedContentTypes: Set of expected content type prefixes
    ///   - strict: Whether to require exact match or allow prefix matching
    public init(expectedContentTypes: Set<String>, strict: Bool = false) {
        self.expectedContentTypes = expectedContentTypes
        self.strict = strict
    }
    
    /// Validator for JSON content type
    public static let json = ContentTypeValidator(expectedContentTypes: ["application/json"])
    
    /// Validator for any text content type
    public static let text = ContentTypeValidator(expectedContentTypes: ["text/"])
    
    /// Validator for images
    public static let image = ContentTypeValidator(expectedContentTypes: ["image/"])
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        guard let contentType = response.contentType else {
            throw NetworkError.invalidResponse
        }
        
        let isValid = expectedContentTypes.contains { expected in
            if strict {
                return contentType.lowercased() == expected.lowercased()
            } else {
                return contentType.lowercased().hasPrefix(expected.lowercased())
            }
        }
        
        if !isValid {
            throw NetworkError.invalidResponse
        }
    }
}

/// Validator that checks response size limits
public struct ResponseSizeValidator: ResponseValidator {
    private let minSize: Int?
    private let maxSize: Int?
    
    /// Create a response size validator
    /// - Parameters:
    ///   - minSize: Minimum acceptable response size in bytes
    ///   - maxSize: Maximum acceptable response size in bytes
    public init(minSize: Int? = nil, maxSize: Int? = nil) {
        self.minSize = minSize
        self.maxSize = maxSize
    }
    
    /// Create a validator with only maximum size
    /// - Parameter maxSize: Maximum acceptable response size in bytes
    public static func maxSize(_ maxSize: Int) -> ResponseSizeValidator {
        ResponseSizeValidator(maxSize: maxSize)
    }
    
    /// Create a validator with only minimum size
    /// - Parameter minSize: Minimum acceptable response size in bytes
    public static func minSize(_ minSize: Int) -> ResponseSizeValidator {
        ResponseSizeValidator(minSize: minSize)
    }
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        let size = response.size
        
        if let minSize = minSize, size < minSize {
            throw NetworkError.invalidResponse
        }
        
        if let maxSize = maxSize, size > maxSize {
            throw NetworkError.responseTooLarge
        }
    }
}

/// Validator that checks for required headers
public struct HeaderValidator: ResponseValidator {
    private let requiredHeaders: Set<String>
    private let caseSensitive: Bool
    
    /// Create a header validator
    /// - Parameters:
    ///   - requiredHeaders: Set of required header names
    ///   - caseSensitive: Whether header names should be case sensitive
    public init(requiredHeaders: Set<String>, caseSensitive: Bool = false) {
        self.requiredHeaders = caseSensitive ? requiredHeaders : Set(requiredHeaders.map { $0.lowercased() })
        self.caseSensitive = caseSensitive
    }
    
    /// Create a validator for common security headers
    public static let securityHeaders = HeaderValidator(requiredHeaders: [
        "X-Content-Type-Options",
        "X-Frame-Options",
        "X-XSS-Protection"
    ])
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        let responseHeaders = caseSensitive ? 
            Set(response.headers.dictionary.keys) : 
            Set(response.headers.dictionary.keys.map { $0.lowercased() })
        
        let missingHeaders = requiredHeaders.subtracting(responseHeaders)
        
        if !missingHeaders.isEmpty {
            throw NetworkError.invalidResponse
        }
    }
}

/// Validator that checks response body against custom conditions
public struct BodyValidator: ResponseValidator {
    private let validator: @Sendable (Data) throws -> Void
    
    /// Create a body validator with custom validation logic
    /// - Parameter validator: Function that validates response body data
    public init(validator: @escaping @Sendable (Data) throws -> Void) {
        self.validator = validator
    }
    
    /// Create a validator that checks if response body is not empty
    public static let notEmpty = BodyValidator { data in
        if data.isEmpty {
            throw NetworkError.invalidResponse
        }
    }
    
    /// Create a validator that checks if response body is valid JSON
    public static let validJSON = BodyValidator { data in
        guard !data.isEmpty else {
            throw NetworkError.invalidResponse
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw NetworkError.decodingError(DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON response")
            ))
        }
    }
    
    /// Create a validator that checks if response body is valid UTF-8 string
    public static let validUTF8 = BodyValidator { data in
        guard !data.isEmpty else {
            throw NetworkError.invalidResponse
        }
        
        if String(data: data, encoding: .utf8) == nil {
            throw NetworkError.invalidResponse
        }
    }
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        try validator(response.data)
    }
}

/// Validator that checks response timing
public struct TimingValidator: ResponseValidator {
    private let maxDuration: TimeInterval?
    private let minDuration: TimeInterval?
    
    /// Create a timing validator
    /// - Parameters:
    ///   - minDuration: Minimum acceptable response time
    ///   - maxDuration: Maximum acceptable response time
    public init(minDuration: TimeInterval? = nil, maxDuration: TimeInterval? = nil) {
        self.minDuration = minDuration
        self.maxDuration = maxDuration
    }
    
    /// Create a validator with only maximum duration
    /// - Parameter maxDuration: Maximum acceptable response time
    public static func maxDuration(_ maxDuration: TimeInterval) -> TimingValidator {
        TimingValidator(maxDuration: maxDuration)
    }
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        // Note: This validator would need duration tracking in HTTPClient
        // For now, it's a placeholder for future implementation
    }
}

/// Composite validator that runs multiple validators
public struct CompositeValidator: ResponseValidator {
    private let validators: [ResponseValidator]
    
    /// Create a composite validator
    /// - Parameter validators: Array of validators to run
    public init(_ validators: [ResponseValidator]) {
        self.validators = validators
    }
    
    /// Create a standard validator with common checks
    public static let standard = CompositeValidator([
        StatusCodeValidator.success,
        ResponseSizeValidator.maxSize(10 * 1024 * 1024) // 10MB limit
    ])
    
    /// Create a strict JSON validator
    public static let strictJSON = CompositeValidator([
        StatusCodeValidator.success,
        ContentTypeValidator.json,
        BodyValidator.validJSON,
        ResponseSizeValidator.maxSize(1 * 1024 * 1024) // 1MB limit
    ])
    
    public func validate<T>(_ response: HTTPResponse<T>) throws {
        for validator in validators {
            try validator.validate(response)
        }
    }
} 