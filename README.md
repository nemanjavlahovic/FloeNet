# FloeNet 🌊

A modern, lightweight networking library for Swift with async/await support.

## Overview

FloeNet is a mini networking layer built on top of URLSession, designed to provide a clean, type-safe, and easy-to-use API for making HTTP requests in Swift applications.

## Features

- **🚀 Modern Async/Await**: Full Swift concurrency support with proper error handling
- **🔧 Request Builder Pattern**: Fluent API for building HTTP requests
- **🎭 Mock HTTP Client**: Comprehensive mocking for unit testing
- **🧪 Enhanced Testing Utilities**: Rich test helpers and assertions
- **⚡ Core HTTP Client**: Clean wrapper around URLSession
- **🔄 Retry Mechanisms**: Built-in retry with exponential backoff
- **🎯 Request/Response Interceptors**: Middleware pattern for authentication, logging, etc.
- **📊 Comprehensive Error Handling**: Detailed error types covering all networking scenarios
- **🔒 Thread-Safe Operations**: All operations are safe for concurrent use
- **⚙️ Advanced Configuration**: Timeout and connection management
- **✅ Response Validation**: Customizable response validation
- **📝 Logging Support**: Comprehensive request/response logging
- **🏗️ Type-Safe**: Leverages Swift's type system for compile-time safety
- **📦 Zero Dependencies**: Built entirely on Foundation and URLSession

## Requirements

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add FloeNet to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/FloeNet.git", from: "0.3.0")
]
```

## Quick Start

### Basic Usage

```swift
import FloeNet

let client = HTTPClient()

// Real-world example: US Population data from DataUSA API
let url = URL(string: "https://datausa.io/api/data?drilldowns=Nation&measures=Population")!

do {
    let response = try await client.get(url: url)
    print("Status: \(response.statusCode)")
    print("Population Data: \(response.stringValue ?? "")")
} catch {
    print("Error: \(error)")
}
```

### Request Builder Pattern with Real API

```swift
// Fetch US population data with custom headers
let response = try await RequestBuilder
    .get("https://datausa.io/api/data")
    .header("User-Agent", "MyApp/1.0")
    .query("drilldowns", "Nation")
    .query("measures", "Population")
    .timeout(30.0)
    .send(with: client)

// Decode structured response
struct DataUSAResponse: Codable {
    let data: [PopulationData]
    let source: [DataSource]
}

struct PopulationData: Codable {
    let nation: String
    let year: String
    let population: Int
    
    private enum CodingKeys: String, CodingKey {
        case nation = "Nation"
        case year = "Year"
        case population = "Population"
    }
}

let populationResponse = try await RequestBuilder()
    .url("https://datausa.io/api/data")
    .get()
    .query("drilldowns", "Nation")
    .query("measures", "Population")
    .send(with: client, expecting: DataUSAResponse.self)

let latestPopulation = populationResponse.value?.data.first
print("US Population in \(latestPopulation?.year ?? "Unknown"): \(latestPopulation?.population.formatted() ?? "Unknown")")
```

### Request Builder Pattern

```swift
// Fluent request building
let response = try await RequestBuilder
    .get("https://api.example.com/users")
    .bearerToken("your-token")
    .header("User-Agent", "MyApp/1.0")
    .query("limit", 10)
    .query("active", true)
    .timeout(30.0)
    .send(with: client)

// Complex POST with JSON body
struct User: Codable {
    let name: String
    let email: String
}

let user = User(name: "John Doe", email: "john@example.com")

let response = try await RequestBuilder()
    .url("https://api.example.com/users")
    .post()
    .bearerToken("your-token")
    .jsonBody(user)
    .send(with: client, expecting: User.self)

print("Created user: \(response.data)")
```

### Mock Client for Testing

```swift
import XCTest
@testable import YourApp

class APITests: XCTestCase {
    func testUserFetch() async throws {
        // Setup mock client
        let mockClient = MockHTTPClient()
        let testUser = TestUser(id: 1, name: "John", email: "john@example.com")
        
        mockClient.stub(
            url: URL(string: "https://api.example.com/users/1")!,
            response: try .json(testUser)
        )
        
        // Test your code
        let apiClient = UserAPIClient(httpClient: mockClient)
        let user = try await apiClient.getUser(id: 1)
        
        // Assertions
        XCTAssertEqual(user.name, "John")
        XCTAssertTrue(mockClient.verify(.url(URL(string: "https://api.example.com/users/1")!)))
    }
}
```

## API Reference

## 🔧 Request Builder

The RequestBuilder provides a fluent interface for constructing HTTP requests:

### Basic Configuration

```swift
let request = try RequestBuilder()
    .url("https://api.example.com/users")  // Set URL
    .get()                                 // HTTP method
    .build()                              // Build HTTPRequest

// Or use static factory methods
let request = try RequestBuilder.get("https://api.example.com/users")
    .build()
```

### Headers and Authentication

```swift
let request = try RequestBuilder
    .post("https://api.example.com/data")
    .header("Content-Type", "application/json")
    .header("X-Custom-Header", "value")
    .bearerToken("your-jwt-token")
    .basicAuth(username: "user", password: "pass")
    .build()
```

### Query Parameters

```swift
let request = try RequestBuilder
    .get("https://api.example.com/search")
    .query("q", "swift")
    .query("limit", 10)
    .query("active", true)
    .query(["sort": "name", "order": "asc"])  // Dictionary
    .build()
```

### Request Bodies

```swift
// JSON body (automatic Content-Type)
struct PostData: Codable {
    let title: String
    let content: String
}

let request = try RequestBuilder
    .post("https://api.example.com/posts")
    .jsonBody(PostData(title: "Hello", content: "World"))
    .build()

// Form data
let request = try RequestBuilder
    .post("https://api.example.com/login")
    .formBody(["username": "user", "password": "pass"])
    .build()

// Raw data
let request = try RequestBuilder
    .post("https://api.example.com/upload")
    .body("Raw text content")
    .header("Content-Type", "text/plain")
    .build()
```

### Timeouts and Convenience

```swift
let request = try RequestBuilder
    .get("https://api.example.com/data")
    .timeout(30.0)          // Custom timeout
    .quickTimeout()         // 30 seconds
    .slowTimeout()          // 2 minutes
    .build()
```

### Path Building

```swift
let request = try RequestBuilder
    .get("https://api.example.com")
    .path("users")           // https://api.example.com/users
    .path("123")             // https://api.example.com/users/123
    .path("profile")         // https://api.example.com/users/123/profile
    .build()
```

### Direct Execution

```swift
// Send immediately without building
let response = try await RequestBuilder
    .get("https://api.example.com/users")
    .bearerToken("token")
    .send(with: client)

// With type expectation
let users = try await RequestBuilder
    .get("https://api.example.com/users")
    .send(with: client, expecting: [User].self)
    .data
```

## 🎭 Mock Client for Testing

The MockHTTPClient enables comprehensive testing without network calls:

### Basic Mocking

```swift
let mockClient = MockHTTPClient()

// Simple response
mockClient.stub(
    url: URL(string: "https://api.example.com/data")!,
    response: MockHTTPClient.MockResponse(
        statusCode: 200,
        data: "Hello, World!".data(using: .utf8)!
    )
)

// JSON response
let user = User(name: "John", email: "john@example.com")
mockClient.stub(
    url: URL(string: "https://api.example.com/user")!,
    response: try .json(user)
)
```

### Advanced Matching

```swift
// URL pattern matching
mockClient.stub(
    .urlPattern("users"),               // Matches any URL containing "users"
    response: try .json(users)
)

// HTTP method matching
mockClient.stub(
    .post,                              // Any POST request
    response: .unauthorized()
)

// Header matching
mockClient.stub(
    .authenticated(token: "valid-token"),
    response: try .json(["success": true])
)
```

### Response Scenarios

```swift
// Error responses
mockClient.stub(url: errorURL, response: .error(.noConnection))
mockClient.stub(url: notFoundURL, response: .notFound())
mockClient.stub(url: timeoutURL, response: .timeout(delay: 2.0))

// Delayed responses
mockClient.stub(
    url: slowURL,
    response: try .json(data, delay: 1.5)
)

// Response sequences
mockClient.stubSequence(
    .urlPattern("flaky-endpoint"),
    responses: [
        .error(.timeout),
        .error(.noConnection),
        try .json(successData)
    ]
)
```

### Request Verification

```swift
// Verify specific requests were made
XCTAssertTrue(mockClient.verify(.url(specificURL)))
XCTAssertTrue(mockClient.verify(.post))
XCTAssertTrue(mockClient.verify(.authenticated(token: "token")))

// Request count verification
XCTAssertEqual(mockClient.requestCount(), 3)

// Get recorded requests
let requests = mockClient.recordedRequests()
let postRequests = mockClient.requests(matching: .post)
```

## 🧪 Enhanced Testing Utilities

### Test Data Generation

```swift
// Generate test data
let user = TestUtilities.DataGenerator.testUser()
let randomData = TestUtilities.DataGenerator.randomJSON()
let largeFile = TestUtilities.DataGenerator.largeData(sizeInKB: 100)

// Predefined test URLs
let getURL = TestUtilities.TestURLs.get
let postURL = TestUtilities.TestURLs.post
let invalidURL = TestUtilities.TestURLs.invalid
```

### XCTest Extensions

```swift
class MyNetworkTests: XCTestCase {
    func testAPIResponse() async throws {
        let response = try await client.get(url: testURL)
        
        // Enhanced assertions
        assertSuccess(response)
        assertStatusCode(response, equals: 200)
        assertHeader(response, name: "Content-Type", equals: "application/json")
        assertHasHeader(response, name: "X-Request-ID")
        
        // Error testing
        do {
            _ = try await client.get(url: invalidURL)
        } catch {
            assertNetworkError(error, is: .noConnection)
        }
    }
    
    func testMockVerification() async throws {
        let mockClient = MockHTTPClient()
        // ... setup and test
        
        assertRequestRecorded(mockClient, matching: .get)
        assertRequestCount(mockClient, equals: 1)
    }
}
```

### Test Scenarios

```swift
// Quick scenario setup
try TestScenarios.setupSuccessScenario(
    mockClient: mockClient,
    url: testURL,
    user: testUser
)

TestScenarios.setupNetworkErrorScenario(
    mockClient: mockClient,
    url: errorURL,
    error: .timeout
)

try TestScenarios.setupSlowNetworkScenario(
    mockClient: mockClient,
    url: slowURL,
    delay: 2.0
)
```

## Core API (Traditional Approach)

### POST Request with JSON

```swift
struct User: Codable {
    let name: String
    let email: String
}

let client = HTTPClient()
let url = URL(string: "https://api.example.com/users")!
let user = User(name: "John Doe", email: "john@example.com")

do {
    let response = try await client.post(url: url, body: user)
    print("Created user: \(response.statusCode)")
} catch {
    print("Error: \(error)")
}
```

### Custom Request Building

```swift
let headers: HTTPHeaders = [
    "Authorization": "Bearer token123",
    "User-Agent": "MyApp/1.0"
]

let request = HTTPRequest.get(
    url: url,
    headers: headers,
    queryParameters: ["limit": "10", "page": "1"],
    timeout: 30.0
)

let response = try await client.send(request)
```

### Convenience API

```swift
// Quick access using the Floe convenience API
let response = try await Floe.get(url: url)
let userResponse = try await Floe.post(url: url, body: user, expecting: User.self)

// RequestBuilder convenience
let request = try Floe.request()
    .url("https://api.example.com/data")
    .get()
    .bearerToken("token")
    .build()
```

## Core Types

### HTTPClient & Protocol

```swift
// Protocol for testing
protocol HTTPClientProtocol {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse<Data>
    // ... other methods
}

// Real client
let client = HTTPClient()

// Mock client for testing
let mockClient = MockHTTPClient()
```

### HTTPRequest

```swift
let request = HTTPRequest(
    method: .post,
    url: url,
    headers: headers,
    queryParameters: queryParams,
    body: data,
    timeout: 30.0
)
```

### HTTPResponse

```swift
let response: HTTPResponse<Data> = try await client.send(request)
print("Status: \(response.statusCode)")
print("Headers: \(response.headers)")
print("Data: \(response.data)")
```

### HTTPHeaders

```swift
var headers = HTTPHeaders()
headers["Content-Type"] = "application/json"
headers["authorization"] = "Bearer token"  // Case insensitive

// Common headers
let jsonHeaders = HTTPHeaders.json
let formHeaders = HTTPHeaders.formURLEncoded
```

### NetworkError

```swift
enum NetworkError {
    case noConnection
    case timeout
    case invalidURL(String)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(String)
    case requestTooLarge
    case responseTooLarge
    // ... and more
}
```

## Architecture

FloeNet follows these design principles:

- **Protocol-Oriented**: Built for testability and extensibility
- **Type-Safe**: Leverages Swift's type system for compile-time safety
- **Async/Await First**: Modern concurrency with proper error handling
- **Zero Dependencies**: Built entirely on Foundation and URLSession
- **Thread-Safe**: All operations are safe for concurrent use
- **Fluent API**: RequestBuilder pattern for readable request construction
- **Test-Friendly**: Comprehensive mocking and testing utilities

## Testing

FloeNet provides both traditional XCTest integration and a custom test runner for comprehensive testing.

### Running XCTests

```bash
swift test
```

### Running Custom Test Runner

For real-world API testing and comprehensive validation:

```swift
import FloeNet

// Run comprehensive test suite with real DataUSA API
await TestRunner.runAllTests()
```

The custom test runner includes:
- **Unit Tests**: Core functionality, offline
- **Integration Tests**: Real DataUSA API calls  
- **Performance Tests**: Concurrent request handling
- **Error Scenario Tests**: Timeout, invalid URLs, JSON decoding errors

### DataUSA API Integration Tests

FloeNet includes dedicated tests using the real DataUSA Population API to demonstrate:
- JSON decoding with complex nested structures
- Query parameter handling
- Real-world error scenarios  
- Concurrent request processing
- Response validation

```swift
// Example: Test real API integration
func testDataUSAAPI() async throws {
    let client = HTTPClient()
    let url = URL(string: "https://datausa.io/api/data?drilldowns=Nation&measures=Population")!
    
    let response = try await client.send(
        HTTPRequest.get(url: url), 
        expecting: DataUSAResponse.self
    )
    
    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(response.value?.data.first?.nation, "United States")
    XCTAssertTrue((response.value?.data.first?.population ?? 0) > 300_000_000)
}
```

## Examples

Check out the `Examples/`