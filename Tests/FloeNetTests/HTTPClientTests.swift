import XCTest
@testable import FloeNet

@available(iOS 15.0, macOS 12.0, *)
final class HTTPClientTests: XCTestCase {
    
    var httpClient: HTTPClient!
    
    override func setUp() {
        super.setUp()
        httpClient = HTTPClient()
    }
    
    override func tearDown() {
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Basic Request Tests
    
    func testSimpleGETRequest() async throws {
        let url = URL(string: "https://httpbin.org/get")!
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        XCTAssertFalse(response.isClientError)
        XCTAssertFalse(response.isServerError)
        XCTAssertNotNil(response.data)
    }
    
    func testGETRequestWithHeaders() async throws {
        let url = URL(string: "https://httpbin.org/headers")!
        let headers: HTTPHeaders = [
            "Authorization": "Bearer test-token",
            "User-Agent": "FloeNet-Tests/1.0"
        ]
        let request = HTTPRequest.get(url: url, headers: headers)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        
        // Verify that our headers were sent
        let responseString = response.stringValue ?? ""
        XCTAssertTrue(responseString.contains("Bearer test-token"))
        XCTAssertTrue(responseString.contains("FloeNet-Tests/1.0"))
    }
    
    func testGETRequestWithQueryParameters() async throws {
        let url = URL(string: "https://httpbin.org/get")!
        let queryParams = [
            "param1": "value1",
            "param2": "value2",
            "special": "hello world!"
        ]
        let request = HTTPRequest.get(url: url, queryParameters: queryParams)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        
        let responseString = response.stringValue ?? ""
        XCTAssertTrue(responseString.contains("param1"))
        XCTAssertTrue(responseString.contains("value1"))
        XCTAssertTrue(responseString.contains("param2"))
        XCTAssertTrue(responseString.contains("value2"))
    }
    
    func testPOSTRequestWithJSONBody() async throws {
        struct TestPayload: Codable {
            let name: String
            let age: Int
            let active: Bool
        }
        
        let url = URL(string: "https://httpbin.org/post")!
        let payload = TestPayload(name: "John Doe", age: 30, active: true)
        let request = try HTTPRequest.json(method: .post, url: url, body: payload)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        
        // Verify JSON was sent correctly
        let responseString = response.stringValue ?? ""
        XCTAssertTrue(responseString.contains("John Doe"))
        XCTAssertTrue(responseString.contains("30"))
        XCTAssertTrue(responseString.contains("true"))
    }
    
    func testPOSTRequestWithRawData() async throws {
        let url = URL(string: "https://httpbin.org/post")!
        let bodyData = "Raw text data".data(using: .utf8)!
        let request = HTTPRequest.post(url: url, body: bodyData)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        
        let responseString = response.stringValue ?? ""
        XCTAssertTrue(responseString.contains("Raw text data"))
    }
    
    func testPUTRequest() async throws {
        struct UpdatePayload: Codable {
            let id: Int
            let title: String
        }
        
        let url = URL(string: "https://httpbin.org/put")!
        let payload = UpdatePayload(id: 1, title: "Updated Title")
        let request = try HTTPRequest.json(method: .put, url: url, body: payload)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
    }
    
    func testDELETERequest() async throws {
        let url = URL(string: "https://httpbin.org/delete")!
        let request = HTTPRequest.delete(url: url)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
    }
    
    // MARK: - Response Decoding Tests
    
    func testJSONResponseDecoding() async throws {
        let url = URL(string: "https://datausa.io/api/data?drilldowns=Nation&measures=Population")!
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.send(request, expecting: DataUSAResponse.self)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        XCTAssertNotNil(response.value)
        
        guard let populationData = response.value else {
            XCTFail("Failed to decode DataUSA response")
            return
        }
        
        XCTAssertFalse(populationData.data.isEmpty)
        XCTAssertEqual(populationData.data.first?.nation, "United States")
        XCTAssertTrue((populationData.data.first?.population ?? 0) > 300_000_000)
        
        XCTAssertFalse(populationData.source.isEmpty)
        XCTAssertEqual(populationData.source.first?.annotations.sourceName, "Census Bureau")
    }
    
    func testStringResponseDecoding() async throws {
        let url = URL(string: "https://datausa.io/api/data?drilldowns=Nation&measures=Population")!
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.sendString(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        XCTAssertNotNil(response.value)
        XCTAssertFalse(response.value?.isEmpty ?? true)
        XCTAssertTrue(response.value?.contains("United States") ?? false)
        XCTAssertTrue(response.value?.contains("Population") ?? false)
    }
    
    func testEmptyResponseHandling() async throws {
        let url = URL(string: "https://httpbin.org/status/204")!
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.sendEmpty(request)
        
        XCTAssertEqual(response.statusCode, 204)
        XCTAssertTrue(response.isSuccess)
        // Empty response should have EmptyResponse type
        XCTAssertNotNil(response.value)
    }
    
    // MARK: - Error Handling Tests
    
    func testClientErrorResponse() async throws {
        let url = URL(string: "https://httpbin.org/status/404")!
        let request = HTTPRequest.get(url: url)
        
        do {
            _ = try await httpClient.send(request)
            XCTFail("Expected NetworkError to be thrown")
        } catch let error as NetworkError {
            XCTAssertTrue(error.isClientError)
            XCTAssertFalse(error.isServerError)
            XCTAssertFalse(error.isRetryable)
            XCTAssertEqual(error.statusCode, 404)
        }
    }
    
    func testServerErrorResponse() async throws {
        let url = URL(string: "https://httpbin.org/status/500")!
        let request = HTTPRequest.get(url: url)
        
        do {
            _ = try await httpClient.send(request)
            XCTFail("Expected NetworkError to be thrown")
        } catch let error as NetworkError {
            XCTAssertFalse(error.isClientError)
            XCTAssertTrue(error.isServerError)
            XCTAssertTrue(error.isRetryable)
            XCTAssertEqual(error.statusCode, 500)
        }
    }
    
    func testInvalidURLHandling() async throws {
        let url = URL(string: "invalid-url")!
        let request = HTTPRequest.get(url: url)
        
        do {
            _ = try await httpClient.send(request)
            XCTFail("Expected NetworkError to be thrown")
        } catch let error as NetworkError {
            // Should be some form of network error
            XCTAssertNotNil(error)
        }
    }
    
    func testMalformedJSONDecoding() async throws {
        // This endpoint returns plain text, not JSON
        let url = URL(string: "https://httpbin.org/html")!
        let request = HTTPRequest.get(url: url)
        
        do {
            struct TestStruct: Codable {
                let key: String
            }
            _ = try await httpClient.send(request, expecting: TestStruct.self)
            XCTFail("Expected decoding error")
        } catch let error as NetworkError {
            if case .decodingError = error {
                // This is expected
            } else {
                XCTFail("Expected decodingError, got: \(error)")
            }
        }
    }
    
    // MARK: - Timeout Tests
    
    func testRequestTimeout() async throws {
        let url = URL(string: "https://httpbin.org/delay/2")!
        let request = HTTPRequest.get(url: url, timeout: 1.0) // 1 second timeout for 2 second delay
        
        let startTime = Date()
        
        do {
            _ = try await httpClient.send(request)
            XCTFail("Expected timeout error")
        } catch let error as NetworkError {
            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(elapsed, 1.5) // Should timeout before 1.5 seconds
            
            // Should be a timeout-related error
            XCTAssertTrue(error.localizedDescription.lowercased().contains("time") || 
                         error.localizedDescription.lowercased().contains("timeout"))
        }
    }
    
    // MARK: - HTTPClient Configuration Tests
    
    func testCustomHTTPClientConfiguration() async throws {
        let config = NetworkConfiguration.builder
            .timeout(30.0)
            .retryPolicy(.never)
            .build()
        
        let customClient = HTTPClient(configuration: config)
        
        let url = URL(string: "https://datausa.io/api/data?drilldowns=Nation&measures=Population")!
        let request = HTTPRequest.get(url: url)
        
        let response = try await customClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testHTTPClientConvenienceGET() async throws {
        let url = URL(string: "https://httpbin.org/get")!
        
        let response = try await httpClient.get(url: url)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
    }
    
    func testHTTPClientConveniencePOST() async throws {
        struct TestPayload: Codable {
            let message: String
        }
        
        let url = URL(string: "https://httpbin.org/post")!
        let payload = TestPayload(message: "Hello World")
        
        let response = try await httpClient.post(url: url, body: payload)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentRequests() async throws {
        let url = URL(string: "https://httpbin.org/get")!
        let requestCount = 10
        
        let startTime = Date()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<requestCount {
                group.addTask {
                    do {
                        let request = HTTPRequest.get(url: url, queryParameters: ["request": "\(i)"])
                        let response = try await self.httpClient.send(request)
                        XCTAssertEqual(response.statusCode, 200)
                    } catch {
                        XCTFail("Request \(i) failed: \(error)")
                    }
                }
            }
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        print("Completed \(requestCount) concurrent requests in \(elapsed) seconds")
        
        // Should complete reasonably quickly
        XCTAssertLessThan(elapsed, 30.0)
    }
    
    // MARK: - Memory Tests
    
    func testLargeResponseHandling() async throws {
        // HTTPBin has a limit, but we can test with a reasonably sized response
        let url = URL(string: "https://httpbin.org/base64/SFRUUEJpbiBpcyBhd2Vzb21l")!
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.send(request)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        XCTAssertNotNil(response.data)
        XCTAssertGreaterThan(response.data.count, 0)
    }
} 