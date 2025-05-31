import XCTest
@testable import FloeNet

final class RequestBuilderTests: XCTestCase {
    
    // MARK: - Basic Builder Tests
    
    func testBasicBuilder() throws {
        let url = URL(string: "https://api.example.com/users")!
        
        let request = try RequestBuilder()
            .url(url)
            .get()
            .build()
        
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, url)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertTrue(request.queryParameters.isEmpty)
        XCTAssertNil(request.body)
        XCTAssertNil(request.timeout)
    }
    
    func testBuilderWithURL() throws {
        let url = URL(string: "https://api.example.com/users")!
        
        let request = try RequestBuilder(url: url)
            .post()
            .build()
        
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url, url)
    }
    
    func testBuilderWithURLString() throws {
        let urlString = "https://api.example.com/users"
        
        let request = try RequestBuilder(url: urlString)
            .put()
            .build()
        
        XCTAssertEqual(request.method, .put)
        XCTAssertEqual(request.url.absoluteString, urlString)
    }
    
    func testInvalidURLString() {
        XCTAssertThrowsError(try RequestBuilder(url: "invalid-url")) { error in
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - HTTP Method Tests
    
    func testHTTPMethods() throws {
        let url = URL(string: "https://api.example.com")!
        
        let getRequest = try RequestBuilder(url: url).get().build()
        XCTAssertEqual(getRequest.method, .get)
        
        let postRequest = try RequestBuilder(url: url).post().build()
        XCTAssertEqual(postRequest.method, .post)
        
        let putRequest = try RequestBuilder(url: url).put().build()
        XCTAssertEqual(putRequest.method, .put)
        
        let patchRequest = try RequestBuilder(url: url).patch().build()
        XCTAssertEqual(patchRequest.method, .patch)
        
        let deleteRequest = try RequestBuilder(url: url).delete().build()
        XCTAssertEqual(deleteRequest.method, .delete)
    }
    
    func testCustomMethod() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .method(.options)
            .build()
        
        XCTAssertEqual(request.method, .options)
    }
    
    // MARK: - Header Tests
    
    func testSingleHeader() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .header("Authorization", "Bearer token")
            .build()
        
        XCTAssertEqual(request.headers["Authorization"], "Bearer token")
    }
    
    func testMultipleHeaders() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .header("Authorization", "Bearer token")
            .header("User-Agent", "TestApp/1.0")
            .build()
        
        XCTAssertEqual(request.headers["Authorization"], "Bearer token")
        XCTAssertEqual(request.headers["User-Agent"], "TestApp/1.0")
    }
    
    func testHeadersDictionary() throws {
        let url = URL(string: "https://api.example.com")!
        let headerDict = [
            "Authorization": "Bearer token",
            "User-Agent": "TestApp/1.0"
        ]
        
        let request = try RequestBuilder(url: url)
            .headers(headerDict)
            .build()
        
        XCTAssertEqual(request.headers["Authorization"], "Bearer token")
        XCTAssertEqual(request.headers["User-Agent"], "TestApp/1.0")
    }
    
    func testBearerToken() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .bearerToken("test-token")
            .build()
        
        XCTAssertEqual(request.headers["Authorization"], "Bearer test-token")
    }
    
    func testBasicAuth() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .basicAuth(username: "user", password: "pass")
            .build()
        
        let expectedCredentials = Data("user:pass".utf8).base64EncodedString()
        XCTAssertEqual(request.headers["Authorization"], "Basic \(expectedCredentials)")
    }
    
    func testContentTypeHeaders() throws {
        let url = URL(string: "https://api.example.com")!
        
        let jsonRequest = try RequestBuilder(url: url)
            .jsonContentType()
            .build()
        XCTAssertEqual(jsonRequest.headers["Content-Type"], "application/json")
        
        let formRequest = try RequestBuilder(url: url)
            .formContentType()
            .build()
        XCTAssertEqual(formRequest.headers["Content-Type"], "application/x-www-form-urlencoded")
    }
    
    // MARK: - Query Parameter Tests
    
    func testSingleQueryParameter() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .query("limit", "10")
            .build()
        
        XCTAssertEqual(request.queryParameters["limit"], "10")
    }
    
    func testMultipleQueryParameters() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .query("limit", "10")
            .query("offset", "20")
            .build()
        
        XCTAssertEqual(request.queryParameters["limit"], "10")
        XCTAssertEqual(request.queryParameters["offset"], "20")
    }
    
    func testQueryParameterTypes() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .query("limit", 10)
            .query("active", true)
            .query("inactive", false)
            .build()
        
        XCTAssertEqual(request.queryParameters["limit"], "10")
        XCTAssertEqual(request.queryParameters["active"], "true")
        XCTAssertEqual(request.queryParameters["inactive"], "false")
    }
    
    func testQueryParametersDictionary() throws {
        let url = URL(string: "https://api.example.com")!
        let params = [
            "limit": "10",
            "offset": "20"
        ]
        
        let request = try RequestBuilder(url: url)
            .query(params)
            .build()
        
        XCTAssertEqual(request.queryParameters["limit"], "10")
        XCTAssertEqual(request.queryParameters["offset"], "20")
    }
    
    func testQueryParametersAnyDictionary() throws {
        let url = URL(string: "https://api.example.com")!
        let params: [String: Any] = [
            "limit": 10,
            "active": true,
            "name": "test"
        ]
        
        let request = try RequestBuilder(url: url)
            .query(params)
            .build()
        
        XCTAssertEqual(request.queryParameters["limit"], "10")
        XCTAssertEqual(request.queryParameters["active"], "true")
        XCTAssertEqual(request.queryParameters["name"], "test")
    }
    
    // MARK: - Body Tests
    
    func testDataBody() throws {
        let url = URL(string: "https://api.example.com")!
        let data = "test data".data(using: .utf8)!
        
        let request = try RequestBuilder(url: url)
            .body(data)
            .build()
        
        XCTAssertEqual(request.body, data)
    }
    
    func testStringBody() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .body("test string")
            .build()
        
        XCTAssertEqual(request.body, "test string".data(using: .utf8))
    }
    
    func testJSONBody() throws {
        let url = URL(string: "https://api.example.com")!
        let user = TestUser(id: 1, name: "John", email: "john@example.com")
        
        let request = try RequestBuilder(url: url)
            .jsonBody(user)
            .build()
        
        XCTAssertNotNil(request.body)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        
        // Verify the JSON can be decoded back
        let decodedUser = try JSONDecoder().decode(TestUser.self, from: request.body!)
        XCTAssertEqual(decodedUser, user)
    }
    
    func testFormBody() throws {
        let url = URL(string: "https://api.example.com")!
        let parameters = [
            "username": "john",
            "password": "secret"
        ]
        
        let request = try RequestBuilder(url: url)
            .formBody(parameters)
            .build()
        
        XCTAssertNotNil(request.body)
        XCTAssertEqual(request.headers["Content-Type"], "application/x-www-form-urlencoded")
        
        let bodyString = String(data: request.body!, encoding: .utf8)!
        XCTAssertTrue(bodyString.contains("username=john"))
        XCTAssertTrue(bodyString.contains("password=secret"))
    }
    
    // MARK: - Timeout Tests
    
    func testTimeout() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .timeout(30.0)
            .build()
        
        XCTAssertEqual(request.timeout, 30.0)
    }
    
    func testTimeoutSeconds() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .timeout(seconds: 45)
            .build()
        
        XCTAssertEqual(request.timeout, 45.0)
    }
    
    func testQuickTimeout() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .quickTimeout()
            .build()
        
        XCTAssertEqual(request.timeout, 30.0)
    }
    
    func testSlowTimeout() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: url)
            .slowTimeout()
            .build()
        
        XCTAssertEqual(request.timeout, 120.0)
    }
    
    // MARK: - Path Configuration Tests
    
    func testPathAppending() throws {
        let baseURL = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder(url: baseURL)
            .path("users")
            .path("123")
            .build()
        
        XCTAssertEqual(request.url.absoluteString, "https://api.example.com/users/123")
    }
    
    // MARK: - Static Factory Methods Tests
    
    func testStaticGetMethod() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder.get(url).build()
        
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, url)
    }
    
    func testStaticGetMethodWithString() throws {
        let urlString = "https://api.example.com"
        
        let request = try RequestBuilder.get(urlString).build()
        
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, urlString)
    }
    
    func testStaticPostMethod() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder.post(url).build()
        
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url, url)
    }
    
    func testStaticPutMethod() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder.put(url).build()
        
        XCTAssertEqual(request.method, .put)
        XCTAssertEqual(request.url, url)
    }
    
    func testStaticDeleteMethod() throws {
        let url = URL(string: "https://api.example.com")!
        
        let request = try RequestBuilder.delete(url).build()
        
        XCTAssertEqual(request.method, .delete)
        XCTAssertEqual(request.url, url)
    }
    
    // MARK: - Build Error Tests
    
    func testBuildWithoutURL() {
        XCTAssertThrowsError(try RequestBuilder().build()) { error in
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Complex Builder Combination Tests
    
    func testCompleteRequestBuilding() throws {
        let url = URL(string: "https://api.example.com")!
        let user = TestUser(id: 1, name: "John", email: "john@example.com")
        
        let request = try RequestBuilder(url: url)
            .post()
            .path("users")
            .bearerToken("test-token")
            .header("User-Agent", "TestApp/1.0")
            .query("include", "profile")
            .query("format", "json")
            .jsonBody(user)
            .timeout(30.0)
            .build()
        
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.absoluteString, "https://api.example.com/users")
        XCTAssertEqual(request.headers["Authorization"], "Bearer test-token")
        XCTAssertEqual(request.headers["User-Agent"], "TestApp/1.0")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertEqual(request.queryParameters["include"], "profile")
        XCTAssertEqual(request.queryParameters["format"], "json")
        XCTAssertEqual(request.timeout, 30.0)
        XCTAssertNotNil(request.body)
    }
    
    // MARK: - Send Methods Tests (with Mock Client)
    
    func testSendWithMockClient() async throws {
        let mockClient = MockHTTPClient()
        let url = URL(string: "https://api.example.com/users")!
        let testUser = TestUser(id: 1, name: "John", email: "john@example.com")
        
        // Setup mock response
        mockClient.stub(url: url, response: try .json(testUser))
        
        // Build and send request
        let response = try await RequestBuilder(url: url)
            .get()
            .send(with: mockClient)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(mockClient.verify(.url(url)))
    }
    
    func testSendWithExpectingType() async throws {
        let mockClient = MockHTTPClient()
        let url = URL(string: "https://api.example.com/users")!
        let testUser = TestUser(id: 1, name: "John", email: "john@example.com")
        
        // Setup mock response
        mockClient.stub(url: url, response: try .json(testUser))
        
        // Build and send request with type expectation
        let response = try await RequestBuilder(url: url)
            .get()
            .send(with: mockClient, expecting: TestUser.self)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.data, testUser)
        XCTAssertTrue(mockClient.verify(.url(url)))
    }
} 