import XCTest
import Foundation
@testable import FloeNet

/// Test utilities for FloeNet testing
public struct TestUtilities {
    
    /// Test data generators
    public struct DataGenerator {
        /// Generate random string
        public static func randomString(length: Int = 10) -> String {
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<length).map { _ in letters.randomElement()! })
        }
        
        /// Generate random JSON data
        public static func randomJSON() throws -> Data {
            let json = [
                "id": Int.random(in: 1...1000),
                "name": randomString(),
                "email": "\(randomString(length: 8))@example.com",
                "active": Bool.random()
            ] as [String: Any]
            
            return try JSONSerialization.data(withJSONObject: json)
        }
        
        /// Generate test user object
        public static func testUser(id: Int? = nil, name: String? = nil) -> TestUser {
            return TestUser(
                id: id ?? Int.random(in: 1...1000),
                name: name ?? randomString(),
                email: "\(randomString(length: 8))@example.com"
            )
        }
        
        /// Generate large data for testing
        public static func largeData(sizeInKB: Int) -> Data {
            let bytes = Array(repeating: UInt8.random(in: 0...255), count: sizeInKB * 1024)
            return Data(bytes)
        }
    }
    
    /// Test URLs for different scenarios
    public struct TestURLs {
        public static let httpbin = URL(string: "https://httpbin.org")!
        public static let get = URL(string: "https://httpbin.org/get")!
        public static let post = URL(string: "https://httpbin.org/post")!
        public static let put = URL(string: "https://httpbin.org/put")!
        public static let delete = URL(string: "https://httpbin.org/delete")!
        public static let status = { (code: Int) in URL(string: "https://httpbin.org/status/\(code)")! }
        public static let delay = { (seconds: Int) in URL(string: "https://httpbin.org/delay/\(seconds)")! }
        public static let invalid = URL(string: "https://invalid-domain-that-does-not-exist.com")!
        public static let localhost = URL(string: "http://localhost:8080")!
        
        /// Generate random test URL
        public static func random() -> URL {
            return URL(string: "https://api.example.com/\(DataGenerator.randomString())")!
        }
        
        /// DataUSA Population API - reliable, real-world JSON API
        public static let dataUSAPopulation = URL(string: "https://datausa.io/api/data?drilldowns=Nation&measures=Population")!
        
        /// DataUSA base API URL for building custom queries
        public static let dataUSABase = URL(string: "https://datausa.io/api/data")!
        
        /// HTMLBin for testing HTML responses (not JSON)
        public static let htmlResponse = URL(string: "https://httpbin.org/html")!
        
        /// Invalid domain for testing connectivity errors
        public static let invalidDomain = URL(string: "https://invalid-domain-that-doesnt-exist-12345.com/api")!
        
        /// DataUSA with invalid endpoint for 404 testing
        public static let notFound = URL(string: "https://datausa.io/api/nonexistent-endpoint")!
        
        /// General purpose example URL for builder testing (non-network)
        public static let example = URL(string: "https://api.example.com")!
    }
    
    /// Common test headers
    public struct TestHeaders {
        public static let json: HTTPHeaders = ["Content-Type": "application/json"]
        public static let auth: HTTPHeaders = ["Authorization": "Bearer test-token"]
        public static let userAgent: HTTPHeaders = ["User-Agent": "FloeNet-Test/1.0"]
        
        public static func bearer(_ token: String) -> HTTPHeaders {
            return ["Authorization": "Bearer \(token)"]
        }
        
        public static func basic(username: String, password: String) -> HTTPHeaders {
            let credentials = "\(username):\(password)"
            let encoded = Data(credentials.utf8).base64EncodedString()
            return ["Authorization": "Basic \(encoded)"]
        }
    }
}

/// Test user model for testing
public struct TestUser: Codable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let email: String
    
    public init(id: Int, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

/// Test API response wrapper
public struct TestAPIResponse<T: Codable>: Codable, Sendable {
    public let data: T
    public let message: String
    public let success: Bool
    
    public init(data: T, message: String = "Success", success: Bool = true) {
        self.data = data
        self.message = message
        self.success = success
    }
}

/// Test error response
public struct TestErrorResponse: Codable, Error, Sendable {
    public let error: String
    public let code: Int
    public let details: String?
    
    public init(error: String, code: Int, details: String? = nil) {
        self.error = error
        self.code = code
        self.details = details
    }
}

/// DataUSA API Models for real-world testing
public struct DataUSAResponse: Codable, Sendable {
    public let data: [PopulationData]
    public let source: [DataSource]
    
    public init(data: [PopulationData], source: [DataSource]) {
        self.data = data
        self.source = source
    }
}

public struct PopulationData: Codable, Sendable {
    public let idNation: String
    public let nation: String
    public let idYear: String
    public let year: String
    public let population: Int
    public let slugNation: String
    
    private enum CodingKeys: String, CodingKey {
        case idNation = "ID Nation"
        case nation = "Nation"
        case idYear = "ID Year"
        case year = "Year"
        case population = "Population"
        case slugNation = "Slug Nation"
    }
    
    public init(idNation: String, nation: String, idYear: String, year: String, population: Int, slugNation: String) {
        self.idNation = idNation
        self.nation = nation
        self.idYear = idYear
        self.year = year
        self.population = population
        self.slugNation = slugNation
    }
}

public struct DataSource: Codable, Sendable {
    public let measures: [String]
    public let annotations: SourceAnnotations
    public let name: String
    public let substitutions: [String]
    
    public init(measures: [String], annotations: SourceAnnotations, name: String, substitutions: [String]) {
        self.measures = measures
        self.annotations = annotations
        self.name = name
        self.substitutions = substitutions
    }
}

public struct SourceAnnotations: Codable, Sendable {
    public let sourceName: String
    public let sourceDescription: String
    public let datasetName: String
    public let datasetLink: String
    public let tableId: String
    public let topic: String
    public let subtopic: String
    
    private enum CodingKeys: String, CodingKey {
        case sourceName = "source_name"
        case sourceDescription = "source_description"
        case datasetName = "dataset_name"
        case datasetLink = "dataset_link"
        case tableId = "table_id"
        case topic = "topic"
        case subtopic = "subtopic"
    }
    
    public init(sourceName: String, sourceDescription: String, datasetName: String, datasetLink: String, tableId: String, topic: String, subtopic: String) {
        self.sourceName = sourceName
        self.sourceDescription = sourceDescription
        self.datasetName = datasetName
        self.datasetLink = datasetLink
        self.tableId = tableId
        self.topic = topic
        self.subtopic = subtopic
    }
}

// MARK: - XCTest Extensions
extension XCTestCase {
    
    /// Assert HTTP response status code
    public func assertStatusCode<T>(
        _ response: HTTPResponse<T>,
        equals expectedStatusCode: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            response.statusCode,
            expectedStatusCode,
            "Expected status code \(expectedStatusCode), got \(response.statusCode)",
            file: file,
            line: line
        )
    }
    
    /// Assert HTTP response is successful (200-299)
    public func assertSuccess<T>(
        _ response: HTTPResponse<T>,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            response.isSuccess,
            "Expected successful response, got status code \(response.statusCode)",
            file: file,
            line: line
        )
    }
    
    /// Assert HTTP response header value
    public func assertHeader<T>(
        _ response: HTTPResponse<T>,
        name: String,
        equals expectedValue: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            response.headers[name],
            expectedValue,
            "Expected header '\(name)' to be '\(expectedValue)', got '\(response.headers[name] ?? "nil")'",
            file: file,
            line: line
        )
    }
    
    /// Assert HTTP response has header
    public func assertHasHeader<T>(
        _ response: HTTPResponse<T>,
        name: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNotNil(
            response.headers[name],
            "Expected response to have header '\(name)'",
            file: file,
            line: line
        )
    }
    
    /// Assert network error type
    public func assertNetworkError(
        _ error: Error,
        is expectedType: NetworkError,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let networkError = error as? NetworkError else {
            XCTFail("Expected NetworkError, got \(type(of: error))", file: file, line: line)
            return
        }
        
        switch (networkError, expectedType) {
        case (.requestTimeout, .requestTimeout),
             (.noInternetConnection, .noInternetConnection),
             (.invalidURL(_), .invalidURL(_)),
             (.invalidRequest(_), .invalidRequest(_)),
             (.requestTooLarge, .requestTooLarge),
             (.responseTooLarge, .responseTooLarge),
             (.cancelled, .cancelled),
             (.invalidResponse, .invalidResponse):
            break // Match
        case let (.httpError(code1, _), .httpError(code2, _)) where code1 == code2:
            break // Match
        case let (.clientError(code1, _), .clientError(code2, _)) where code1 == code2:
            break // Match
        case let (.serverError(code1, _), .serverError(code2, _)) where code1 == code2:
            break // Match
        case (.decodingError(_), .decodingError(_)):
            break // Match (don't compare DecodingError details)
        case (.encodingError(_), .encodingError(_)):
            break // Match (don't compare EncodingError details)
        case (.securityError(_), .securityError(_)):
            break // Match (don't compare security error details)
        case (.unknown(_), .unknown(_)):
            break // Match (don't compare underlying error details)
        default:
            XCTFail(
                "Expected \(expectedType), got \(networkError)",
                file: file,
                line: line
            )
        }
    }
    
    /// Assert request was recorded by mock client
    public func assertRequestRecorded(
        _ mockClient: MockHTTPClient,
        matching matcher: MockHTTPClient.RequestMatcher,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            mockClient.verify(matcher),
            "Expected request matching criteria to be recorded",
            file: file,
            line: line
        )
    }
    
    /// Assert specific request count
    public func assertRequestCount(
        _ mockClient: MockHTTPClient,
        equals expectedCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            mockClient.requestCount(),
            expectedCount,
            "Expected \(expectedCount) requests, got \(mockClient.requestCount())",
            file: file,
            line: line
        )
    }
    
    /// Wait for async operation with timeout
    public func waitFor<T>(
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line,
        operation: () async throws -> T
    ) async rethrows -> T {
        let start = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(start)
        
        if duration > timeout {
            XCTFail(
                "Operation took \(duration)s, longer than timeout of \(timeout)s",
                file: file,
                line: line
            )
        }
        
        return result
    }
}

// MARK: - Mock Response Builders
extension MockHTTPClient.MockResponse {
    
    /// Create success response with test user
    public static func userSuccess(user: TestUser? = nil) throws -> MockHTTPClient.MockResponse {
        let testUser = user ?? TestUtilities.DataGenerator.testUser()
        return try json(testUser)
    }
    
    /// Create API wrapper response
    public static func apiSuccess<T: Codable>(data: T) throws -> MockHTTPClient.MockResponse {
        let wrapper = TestAPIResponse(data: data)
        return try json(wrapper)
    }
    
    /// Create validation error response
    public static func validationError(message: String = "Validation failed") -> MockHTTPClient.MockResponse {
        let error = TestErrorResponse(error: message, code: 422)
        let data = try! JSONEncoder().encode(error)
        
        return MockHTTPClient.MockResponse(
            statusCode: 422,
            headers: ["Content-Type": "application/json"],
            data: data
        )
    }
    
    /// Create rate limit response
    public static func rateLimited(retryAfter: Int = 60) -> MockHTTPClient.MockResponse {
        return MockHTTPClient.MockResponse(
            statusCode: 429,
            headers: [
                "Retry-After": "\(retryAfter)",
                "X-RateLimit-Remaining": "0"
            ]
        )
    }
    
    /// Create server error response
    public static func serverError(message: String = "Internal server error") -> MockHTTPClient.MockResponse {
        let error = TestErrorResponse(error: message, code: 500)
        let data = try! JSONEncoder().encode(error)
        
        return MockHTTPClient.MockResponse(
            statusCode: 500,
            headers: ["Content-Type": "application/json"],
            data: data
        )
    }
}

// MARK: - Request Matcher Builders
extension MockHTTPClient.RequestMatcher {
    
    /// Create matcher for JSON POST requests
    public static func jsonPost(to url: URL) -> MockHTTPClient.RequestMatcher {
        return MockHTTPClient.RequestMatcher(
            method: .post,
            url: url,
            headers: ["Content-Type": "application/json"]
        )
    }
    
    /// Create matcher for authenticated requests
    public static func authenticated(token: String) -> MockHTTPClient.RequestMatcher {
        return MockHTTPClient.RequestMatcher(
            headers: ["Authorization": "Bearer \(token)"]
        )
    }
    
    /// Create matcher for requests with JSON body containing specific data
    public static func jsonBodyContains<T: Encodable>(_ object: T) -> MockHTTPClient.RequestMatcher {
        return MockHTTPClient.RequestMatcher { body in
            guard let body = body,
                  let expectedData = try? JSONEncoder().encode(object) else {
                return false
            }
            return body == expectedData
        }
    }
}

// MARK: - Test Scenarios
public struct TestScenarios {
    
    /// Set up common success scenario
    public static func setupSuccessScenario(
        mockClient: MockHTTPClient,
        url: URL,
        user: TestUser? = nil
    ) throws {
        let testUser = user ?? TestUtilities.DataGenerator.testUser()
        mockClient.stub(url: url, response: try .userSuccess(user: testUser))
    }
    
    /// Set up network error scenario
    public static func setupNetworkErrorScenario(
        mockClient: MockHTTPClient,
        url: URL,
        error: NetworkError = .noInternetConnection
    ) {
        mockClient.stub(url: url, response: .error(error))
    }
    
    /// Set up slow network scenario
    public static func setupSlowNetworkScenario(
        mockClient: MockHTTPClient,
        url: URL,
        delay: TimeInterval = 2.0
    ) throws {
        let response = try MockHTTPClient.MockResponse.json(
            TestUtilities.DataGenerator.testUser(),
            delay: delay
        )
        mockClient.stub(url: url, response: response)
    }
    
    /// Set up authentication failure scenario
    public static func setupAuthFailureScenario(
        mockClient: MockHTTPClient,
        url: URL
    ) {
        mockClient.stub(url: url, response: .unauthorized())
    }
    
    /// Set up rate limiting scenario
    public static func setupRateLimitScenario(
        mockClient: MockHTTPClient,
        url: URL,
        retryAfter: Int = 60
    ) {
        mockClient.stub(url: url, response: .rateLimited(retryAfter: retryAfter))
    }
} 
