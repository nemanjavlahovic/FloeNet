import Foundation
@testable import FloeNet

/// Comprehensive test runner for FloeNet
/// This can be run standalone to verify all functionality works as expected
@available(iOS 15.0, macOS 12.0, *)
public struct TestRunner {
    
    private static var passedTests = 0
    private static var failedTests = 0
    private static var skippedTests = 0
    
    /// Run all tests
    public static func runAllTests() async {
        print("🧪 FloeNet Comprehensive Test Suite")
        print("====================================")
        print()
        
        resetCounters()
        
        // Phase 1: Unit Tests (Offline)
        print("📦 Phase 1: Unit Tests (Offline)")
        print("----------------------------------")
        await runUnitTests()
        print()
        
        // Phase 2: Integration Tests (Online - requires internet)
        print("🌐 Phase 2: Integration Tests (Online)")
        print("---------------------------------------")
        await runIntegrationTests()
        print()
        
        // Phase 3: Performance Tests
        print("⚡ Phase 3: Performance Tests")
        print("------------------------------")
        await runPerformanceTests()
        print()
        
        // Phase 4: Error Scenario Tests
        print("❌ Phase 4: Error Scenario Tests")
        print("---------------------------------")
        await runErrorScenarioTests()
        print()
        
        printSummary()
    }
    
    // MARK: - Unit Tests (Offline)
    
    private static func runUnitTests() async {
        print("Testing HTTPMethod...")
        testHTTPMethod()
        
        print("Testing HTTPHeaders...")
        testHTTPHeaders()
        
        print("Testing NetworkError...")
        testNetworkError()
        
        print("Testing HTTPRequest...")
        await testHTTPRequest()
        
        print("Testing HTTPResponse...")
        testHTTPResponse()
        
        print("Testing RetryPolicy...")
        testRetryPolicy()
        
        print("Testing NetworkConfiguration...")
        testNetworkConfiguration()
    }
    
    private static func testHTTPMethod() {
        executeTest("HTTPMethod raw values") {
            assert(HTTPMethod.get.rawValue == "GET")
            assert(HTTPMethod.post.rawValue == "POST")
            assert(HTTPMethod.put.rawValue == "PUT")
            assert(HTTPMethod.delete.rawValue == "DELETE")
        }
        
        executeTest("HTTPMethod body support") {
            assert(!HTTPMethod.get.allowsRequestBody)
            assert(HTTPMethod.post.allowsRequestBody)
            assert(HTTPMethod.put.allowsRequestBody)
            assert(!HTTPMethod.delete.allowsRequestBody)
        }
        
        executeTest("HTTPMethod idempotency") {
            assert(HTTPMethod.get.isIdempotent)
            assert(!HTTPMethod.post.isIdempotent)
            assert(HTTPMethod.put.isIdempotent)
            assert(HTTPMethod.delete.isIdempotent)
        }
    }
    
    private static func testHTTPHeaders() {
        executeTest("HTTPHeaders case insensitivity") {
            var headers = HTTPHeaders()
            headers["Content-Type"] = "application/json"
            assert(headers["content-type"] == "application/json")
            assert(headers["CONTENT-TYPE"] == "application/json")
        }
        
        executeTest("HTTPHeaders common headers") {
            let jsonHeaders = HTTPHeaders.json
            assert(jsonHeaders["Content-Type"] == "application/json")
            
            let formHeaders = HTTPHeaders.formURLEncoded
            assert(formHeaders["Content-Type"] == "application/x-www-form-urlencoded")
        }
        
        executeTest("HTTPHeaders dictionary literal") {
            let headers: HTTPHeaders = ["Authorization": "Bearer token"]
            assert(headers["Authorization"] == "Bearer token")
        }
    }
    
    private static func testNetworkError() {
        executeTest("NetworkError properties") {
            let connectivityError = NetworkError.noInternetConnection
            assert(connectivityError.isConnectivityError)
            assert(!connectivityError.isClientError)
            assert(connectivityError.isRetryable)
            
            let clientError = NetworkError.clientError(statusCode: 404, data: nil)
            assert(clientError.isClientError)
            assert(!clientError.isRetryable)
            assert(clientError.statusCode == 404)
        }
        
        executeTest("NetworkError from URLError") {
            let timeoutError = URLError(.timedOut)
            let networkError = NetworkError.from(timeoutError)
            assert(networkError.localizedDescription.contains("timeout") || 
                   networkError.localizedDescription.contains("timed"))
        }
    }
    
    private static func testHTTPRequest() async {
        await executeAsyncTest("HTTPRequest initialization") {
            let url = URL(string: "https://api.example.com/users")!
            let headers: HTTPHeaders = ["Authorization": "Bearer token"]
            let queryParams = ["limit": "10"]
            
            let request = HTTPRequest.get(url: url, headers: headers, queryParameters: queryParams)
            
            assert(request.method == .get)
            assert(request.url == url)
            assert(request.headers["Authorization"] == "Bearer token")
            assert(request.queryParameters["limit"] == "10")
        }
        
        await executeAsyncTest("HTTPRequest JSON convenience") {
            struct TestBody: Codable {
                let name: String
                let age: Int
            }
            
            let url = URL(string: "https://api.example.com/users")!
            let body = TestBody(name: "John", age: 30)
            
            do {
                let request = try HTTPRequest.json(method: .post, url: url, body: body)
                assert(request.method == .post)
                assert(request.headers["Content-Type"] == "application/json")
                assert(request.body != nil)
            } catch {
                assertionFailure("JSON request creation failed: \(error)")
            }
        }
        
        await executeAsyncTest("HTTPRequest validation") {
            let url = URL(string: "https://api.example.com/users")!
            
            // Valid request
            let validRequest = HTTPRequest.get(url: url)
            do {
                try validRequest.validate()
            } catch {
                assertionFailure("Valid request failed validation: \(error)")
            }
            
            // Invalid request (GET with body)
            let invalidRequest = HTTPRequest(method: .get, url: url, body: "test".data(using: .utf8))
            do {
                try invalidRequest.validate()
                assertionFailure("Invalid request should have failed validation")
            } catch {
                // Expected
            }
        }
    }
    
    private static func testHTTPResponse() {
        executeTest("HTTPResponse creation and properties") {
            let data = "test response".data(using: .utf8)!
            let url = URL(string: "https://api.example.com/test")!
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            
            let response = HTTPResponse<Data>.data(data: data, urlResponse: httpResponse)
            
            assert(response.statusCode == 200)
            assert(response.isSuccess)
            assert(!response.isClientError)
            assert(!response.isServerError)
            assert(response.headers["Content-Type"] == "application/json")
            assert(response.data == data)
        }
        
        executeTest("HTTPResponse status code categories") {
            let url = URL(string: "https://api.example.com/test")!
            
            // Success response
            let successResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let success = HTTPResponse<Data>.data(data: Data(), urlResponse: successResponse)
            assert(success.isSuccess)
            assert(!success.isClientError)
            assert(!success.isServerError)
            
            // Client error response
            let clientErrorResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
            let clientError = HTTPResponse<Data>.data(data: Data(), urlResponse: clientErrorResponse)
            assert(!clientError.isSuccess)
            assert(clientError.isClientError)
            assert(!clientError.isServerError)
            
            // Server error response
            let serverErrorResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
            let serverError = HTTPResponse<Data>.data(data: Data(), urlResponse: serverErrorResponse)
            assert(!serverError.isSuccess)
            assert(!serverError.isClientError)
            assert(serverError.isServerError)
        }
    }
    
    private static func testRetryPolicy() {
        executeTest("RetryPolicy default values") {
            let policy = RetryPolicy()
            assert(policy.maxRetries == 3)
            assert(policy.baseDelay == 1.0)
            assert(policy.maxDelay == 30.0)
            assert(policy.backoffMultiplier == 2.0)
            assert(policy.jitterEnabled == true)
        }
        
        executeTest("RetryPolicy exponential backoff") {
            let policy = RetryPolicy(jitterEnabled: false)
            assert(policy.delay(for: 0) == 1.0)
            assert(policy.delay(for: 1) == 2.0)
            assert(policy.delay(for: 2) == 4.0)
        }
        
        executeTest("RetryPolicy predefined policies") {
            let never = RetryPolicy.never
            assert(never.maxRetries == 0)
            
            let conservative = RetryPolicy.conservative
            assert(conservative.maxRetries == 1)
            assert(conservative.baseDelay == 2.0)
            
            let standard = RetryPolicy.standard
            assert(standard.maxRetries == 3)
            
            let aggressive = RetryPolicy.aggressive
            assert(aggressive.maxRetries == 5)
        }
        
        executeTest("RetryPolicy retry conditions") {
            let policy = RetryPolicy.standard
            
            let serverError = NetworkError.serverError(statusCode: 500, data: nil)
            let clientError = NetworkError.clientError(statusCode: 404, data: nil)
            
            assert(policy.shouldRetry(serverError, 0))
            assert(!policy.shouldRetry(clientError, 0))
        }
    }
    
    private static func testNetworkConfiguration() {
        executeTest("NetworkConfiguration default values") {
            let config = NetworkConfiguration.default
            assert(config.defaultTimeout == 60.0)
            assert(config.retryPolicy.maxRetries == 3)
        }
        
        executeTest("NetworkConfiguration builder pattern") {
            let config = NetworkConfiguration.builder
                .defaultTimeout(30.0)
                .retryPolicy(.conservative)
                .build()
            
            assert(config.defaultTimeout == 30.0)
            assert(config.retryPolicy.maxRetries == 1)
        }
    }
    
    // MARK: - Integration Tests (Online)
    
    private static func runIntegrationTests() async {
        let client = HTTPClient()
        
        await executeAsyncTest("Simple GET request") {
            let url = URL(string: "https://httpbin.org/get")!
            let request = HTTPRequest.get(url: url)
            
            do {
                let response = try await client.send(request)
                assert(response.statusCode == 200)
                assert(response.isSuccess)
                assert(!response.data.isEmpty)
            } catch {
                assertionFailure("GET request failed: \(error)")
            }
        }
        
        await executeAsyncTest("POST request with JSON") {
            struct TestPayload: Codable {
                let name: String
                let age: Int
            }
            
            let url = URL(string: "https://httpbin.org/post")!
            let payload = TestPayload(name: "John Doe", age: 30)
            
            do {
                let request = try HTTPRequest.json(method: .post, url: url, body: payload)
                let response = try await client.send(request)
                assert(response.statusCode == 200)
                assert(response.isSuccess)
                
                let responseString = response.stringValue ?? ""
                assert(responseString.contains("John Doe"))
                assert(responseString.contains("30"))
            } catch {
                assertionFailure("POST request failed: \(error)")
            }
        }
        
        await executeAsyncTest("Request with headers and query parameters") {
            let url = URL(string: "https://httpbin.org/get")!
            let headers: HTTPHeaders = ["User-Agent": "FloeNet-Test/1.0"]
            let queryParams = ["test": "value", "number": "42"]
            
            let request = HTTPRequest.get(url: url, headers: headers, queryParameters: queryParams)
            
            do {
                let response = try await client.send(request)
                assert(response.statusCode == 200)
                
                let responseString = response.stringValue ?? ""
                assert(responseString.contains("FloeNet-Test/1.0"))
                assert(responseString.contains("test"))
                assert(responseString.contains("value"))
                assert(responseString.contains("42"))
            } catch {
                assertionFailure("Request with headers/params failed: \(error)")
            }
        }
        
        await executeAsyncTest("JSON response decoding") {
            struct HTTPBinResponse: Codable {
                let url: String
                let headers: [String: String]
            }
            
            let url = URL(string: "https://httpbin.org/get")!
            let request = HTTPRequest.get(url: url)
            
            do {
                let response = try await client.send(request, expecting: HTTPBinResponse.self)
                assert(response.statusCode == 200)
                assert(response.value.url == url.absoluteString)
                assert(!response.value.headers.isEmpty)
            } catch {
                assertionFailure("JSON decoding failed: \(error)")
            }
        }
        
        await executeAsyncTest("HTTPClient convenience methods") {
            let url = URL(string: "https://httpbin.org/get")!
            
            do {
                let response = try await client.get(url: url)
                assert(response.statusCode == 200)
                assert(response.isSuccess)
            } catch {
                assertionFailure("Convenience GET failed: \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    private static func runPerformanceTests() async {
        let client = HTTPClient()
        
        await executeAsyncTest("Concurrent requests") {
            let url = URL(string: "https://httpbin.org/get")!
            let requestCount = 5 // Reduced for testing
            
            let startTime = Date()
            
            await withTaskGroup(of: Bool.self) { group in
                for i in 0..<requestCount {
                    group.addTask {
                        do {
                            let request = HTTPRequest.get(url: url, queryParameters: ["id": "\(i)"])
                            let response = try await client.send(request)
                            return response.statusCode == 200
                        } catch {
                            print("Request \(i) failed: \(error)")
                            return false
                        }
                    }
                }
                
                var successCount = 0
                for await success in group {
                    if success { successCount += 1 }
                }
                
                let elapsed = Date().timeIntervalSince(startTime)
                print("  ⏱️  Completed \(successCount)/\(requestCount) requests in \(String(format: "%.2f", elapsed))s")
                
                assert(successCount == requestCount)
                assert(elapsed < 30.0) // Should complete within 30 seconds
            }
        }
        
        executeTest("RetryPolicy delay calculation performance") {
            let policy = RetryPolicy.standard
            let iterations = 1000
            
            let startTime = Date()
            for i in 0..<iterations {
                _ = policy.delay(for: i % 10)
            }
            let elapsed = Date().timeIntervalSince(startTime)
            
            print("  ⏱️  \(iterations) delay calculations in \(String(format: "%.4f", elapsed))s")
            assert(elapsed < 1.0) // Should be very fast
        }
    }
    
    // MARK: - Error Scenario Tests
    
    private static func runErrorScenarioTests() async {
        let client = HTTPClient()
        
        await executeAsyncTest("404 Client Error") {
            let url = URL(string: "https://httpbin.org/status/404")!
            let request = HTTPRequest.get(url: url)
            
            do {
                _ = try await client.send(request)
                assertionFailure("404 request should have failed")
            } catch let error as NetworkError {
                assert(error.isClientError)
                assert(!error.isRetryable)
                assert(error.statusCode == 404)
            } catch {
                assertionFailure("Unexpected error type: \(error)")
            }
        }
        
        await executeAsyncTest("500 Server Error") {
            let url = URL(string: "https://httpbin.org/status/500")!
            let request = HTTPRequest.get(url: url)
            
            do {
                _ = try await client.send(request)
                assertionFailure("500 request should have failed")
            } catch let error as NetworkError {
                assert(error.isServerError)
                assert(error.isRetryable)
                assert(error.statusCode == 500)
            } catch {
                assertionFailure("Unexpected error type: \(error)")
            }
        }
        
        await executeAsyncTest("Request timeout") {
            let url = URL(string: "https://httpbin.org/delay/3")!
            let request = HTTPRequest.get(url: url, timeout: 1.0) // 1s timeout for 3s delay
            
            let startTime = Date()
            
            do {
                _ = try await client.send(request)
                assertionFailure("Timeout request should have failed")
            } catch {
                let elapsed = Date().timeIntervalSince(startTime)
                assert(elapsed < 2.0) // Should timeout before 2 seconds
                print("  ⏱️  Timeout occurred after \(String(format: "%.2f", elapsed))s")
            }
        }
        
        await executeAsyncTest("JSON decoding error") {
            let url = URL(string: "https://httpbin.org/html")! // Returns HTML, not JSON
            let request = HTTPRequest.get(url: url)
            
            struct TestStruct: Codable {
                let key: String
            }
            
            do {
                _ = try await client.send(request, expecting: TestStruct.self)
                assertionFailure("JSON decoding should have failed")
            } catch let error as NetworkError {
                if case .decodingFailed = error {
                    // Expected
                } else {
                    assertionFailure("Expected decodingFailed error, got: \(error)")
                }
            } catch {
                assertionFailure("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Test Utilities
    
    private static func executeTest(_ name: String, test: () throws -> Void) {
        do {
            try test()
            print("  ✅ \(name)")
            passedTests += 1
        } catch {
            print("  ❌ \(name): \(error)")
            failedTests += 1
        }
    }
    
    private static func executeAsyncTest(_ name: String, test: () async throws -> Void) async {
        do {
            try await test()
            print("  ✅ \(name)")
            passedTests += 1
        } catch {
            print("  ❌ \(name): \(error)")
            failedTests += 1
        }
    }
    
    private static func resetCounters() {
        passedTests = 0
        failedTests = 0
        skippedTests = 0
    }
    
    private static func printSummary() {
        print("🎯 Test Summary")
        print("===============")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("⏭️  Skipped: \(skippedTests)")
        print("📊 Total: \(passedTests + failedTests + skippedTests)")
        print()
        
        if failedTests == 0 {
            print("🎉 All tests passed! FloeNet is working correctly.")
        } else {
            print("⚠️  \(failedTests) test(s) failed. Please review the issues above.")
        }
        
        let successRate = Double(passedTests) / Double(passedTests + failedTests) * 100
        print("📈 Success Rate: \(String(format: "%.1f", successRate))%")
    }
} 