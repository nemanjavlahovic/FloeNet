# FloeNet 🌊

A modern, lightweight networking library for Swift with async/await support.

## Overview

FloeNet is a mini networking layer built on top of URLSession, designed to provide a clean, type-safe, and easy-to-use API for making HTTP requests in Swift applications.

## Features

### ✅ Phase 1 (MVP) - Completed

- **Core HTTP Client**: `HTTPClient.send(_:)` that wraps URLSession
- **Request Configuration**: `HTTPRequest` struct with method, URL, headers, query parameters, body, and custom timeout support
- **Response Handling**: `HTTPResponse` with raw response data and decoded object support
- **Built-in JSON Support**: Automatic JSON encoding/decoding with `Codable`
- **Comprehensive Error Handling**: `NetworkError` enum covering connectivity, HTTP status, decoding, and security errors
- **Thread-Safe Operations**: Full async/await support with proper concurrency handling
- **Request Validation**: Built-in validation for HTTP methods, URLs, and request configuration

## Requirements

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
- Swift 5.7+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add FloeNet to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/FloeNet.git", from: "0.1.0")
]
```

## Quick Start

### Basic GET Request

```swift
import FloeNet

let client = HTTPClient()
let url = URL(string: "https://api.example.com/users")!

do {
    let response = try await client.get(url: url)
    print("Status: \(response.statusCode)")
    print("Data: \(response.stringValue ?? "")")
} catch {
    print("Error: \(error)")
}
```

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

### JSON Response Decoding

```swift
struct ApiResponse: Codable {
    let message: String
    let data: [User]
}

let response = try await client.get(
    url: url,
    expecting: ApiResponse.self
)

print("Message: \(response.value?.message ?? "")")
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

### Error Handling

```swift
// Using Result-based API
let result = await client.sendRequest(request)

switch result {
case .success(let response):
    print("Success: \(response.statusCode)")
case .failure(let error):
    if error.isConnectivityError {
        print("Network connectivity issue")
    } else if error.isClientError {
        print("Client error: \(error.statusCode ?? 0)")
    } else if error.isServerError {
        print("Server error: \(error.statusCode ?? 0)")
    }
}
```

### Convenience API

```swift
// Quick access using the Floe convenience API
let response = try await Floe.get(url: url)
let userResponse = try await Floe.post(url: url, body: user, expecting: User.self)
```

## Core Types

### HTTPClient

The main client for making HTTP requests:

```swift
let client = HTTPClient()
let customClient = HTTPClient(defaultTimeout: 30.0)
let configuredClient = HTTPClient.with(configuration: .ephemeral)
```

### HTTPRequest

Request configuration with full customization:

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

Response container with typed data access:

```swift
let response: HTTPResponse<Data> = try await client.send(request)
print("Status: \(response.statusCode)")
print("Headers: \(response.headers)")
print("Data: \(response.data)")
```

### HTTPHeaders

Case-insensitive header management:

```swift
var headers = HTTPHeaders()
headers["Content-Type"] = "application/json"
headers["authorization"] = "Bearer token"  // Case insensitive

// Common headers
let jsonHeaders = HTTPHeaders.json
let formHeaders = HTTPHeaders.formURLEncoded
```

### NetworkError

Comprehensive error handling:

```swift
enum NetworkError {
    case noInternetConnection
    case requestTimeout
    case invalidURL(String)
    case httpError(statusCode: Int, data: Data?)
    case clientError(statusCode: Int, data: Data?)
    case serverError(statusCode: Int, data: Data?)
    case decodingError(DecodingError)
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

## Testing

Run the test suite:

```bash
swift test
```

Or use the basic test runner:

```swift
import FloeNet

// Run basic validation tests
BasicTests.runAllTests()
```

## Examples

Check out the `Examples/` directory for more detailed usage examples:

- `BasicUsage.swift` - Core functionality demonstrations
- More examples coming in future phases

## Roadmap

### 🔄 Phase 2 (Advanced Convenience)
- Request builder pattern
- Retry mechanisms with exponential backoff
- Request/Response interceptors
- File upload support

### 🧪 Phase 3 (Testability + Mocks)
- HTTPClientProtocol abstraction
- Mock engine for testing
- Request recording/playback

### 🔧 Phase 4 (Debugging & Logging)
- Built-in logging and debugging tools
- Performance metrics
- Network traffic inspection

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

FloeNet is available under the MIT license. See the LICENSE file for more info.

---

**FloeNet** - Making networking flow smoothly 🌊
