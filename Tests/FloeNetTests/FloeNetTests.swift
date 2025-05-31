import XCTest
@testable import FloeNet

final class FloeNetTests: XCTestCase {
    
    // MARK: - HTTPMethod Tests
    
    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.head.rawValue, "HEAD")
        XCTAssertEqual(HTTPMethod.options.rawValue, "OPTIONS")
        XCTAssertEqual(HTTPMethod.trace.rawValue, "TRACE")
        XCTAssertEqual(HTTPMethod.connect.rawValue, "CONNECT")
    }
    
    func testHTTPMethodBodySupport() {
        XCTAssertFalse(HTTPMethod.get.allowsRequestBody)
        XCTAssertTrue(HTTPMethod.post.allowsRequestBody)
        XCTAssertTrue(HTTPMethod.put.allowsRequestBody)
        XCTAssertTrue(HTTPMethod.patch.allowsRequestBody)
        XCTAssertFalse(HTTPMethod.delete.allowsRequestBody)
        XCTAssertFalse(HTTPMethod.head.allowsRequestBody)
    }
    
    func testHTTPMethodIdempotency() {
        XCTAssertTrue(HTTPMethod.get.isIdempotent)
        XCTAssertFalse(HTTPMethod.post.isIdempotent)
        XCTAssertTrue(HTTPMethod.put.isIdempotent)
        XCTAssertFalse(HTTPMethod.patch.isIdempotent)
        XCTAssertTrue(HTTPMethod.delete.isIdempotent)
    }
    
    // MARK: - HTTPHeaders Tests
    
    func testHTTPHeadersInitialization() {
        let headers = HTTPHeaders()
        XCTAssertNil(headers["Content-Type"])
        
        let headersWithDict = HTTPHeaders(["Content-Type": "application/json"])
        XCTAssertEqual(headersWithDict["Content-Type"], "application/json")
        XCTAssertEqual(headersWithDict["content-type"], "application/json")
    }
    
    func testHTTPHeadersCaseInsensitivity() {
        var headers = HTTPHeaders()
        headers["Content-Type"] = "application/json"
        
        XCTAssertEqual(headers["content-type"], "application/json")
        XCTAssertEqual(headers["CONTENT-TYPE"], "application/json")
        XCTAssertEqual(headers["Content-Type"], "application/json")
    }
    
    func testHTTPHeadersCommonHeaders() {
        let jsonHeaders = HTTPHeaders.json
        XCTAssertEqual(jsonHeaders["Content-Type"], "application/json")
        
        let formHeaders = HTTPHeaders.formURLEncoded
        XCTAssertEqual(formHeaders["Content-Type"], "application/x-www-form-urlencoded")
        
        let acceptHeaders = HTTPHeaders.acceptJSON
        XCTAssertEqual(acceptHeaders["Accept"], "application/json")
    }
    
    func testHTTPHeadersDictionaryLiteral() {
        let headers: HTTPHeaders = ["Authorization": "Bearer token", "Accept": "application/json"]
        XCTAssertEqual(headers["Authorization"], "Bearer token")
        XCTAssertEqual(headers["Accept"], "application/json")
    }
    
    // MARK: - NetworkError Tests
    
    func testNetworkErrorProperties() {
        let connectivityError = NetworkError.noInternetConnection
        XCTAssertTrue(connectivityError.isConnectivityError)
        XCTAssertFalse(connectivityError.isClientError)
        XCTAssertFalse(connectivityError.isServerError)
        XCTAssertTrue(connectivityError.isRetryable)
        
        let clientError = NetworkError.clientError(statusCode: 404, data: nil)
        XCTAssertFalse(clientError.isConnectivityError)
        XCTAssertTrue(clientError.isClientError)
        XCTAssertFalse(clientError.isServerError)
        XCTAssertFalse(clientError.isRetryable)
        XCTAssertEqual(clientError.statusCode, 404)
        
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        XCTAssertFalse(serverError.isConnectivityError)
        XCTAssertFalse(serverError.isClientError)
        XCTAssertTrue(serverError.isServerError)
        XCTAssertTrue(serverError.isRetryable)
        XCTAssertEqual(serverError.statusCode, 500)
        
        let rateLimitError = NetworkError.httpError(statusCode: 429, data: nil)
        XCTAssertTrue(rateLimitError.isRetryable)
    }
    
    func testNetworkErrorFromURLError() {
        let timeoutError = URLError(.timedOut)
        let networkError = NetworkError.from(timeoutError)
        XCTAssertEqual(networkError.localizedDescription, "Request timed out")
        
        let connectionError = URLError(.notConnectedToInternet)
        let connectionNetworkError = NetworkError.from(connectionError)
        XCTAssertEqual(connectionNetworkError.localizedDescription, "No internet connection available")
    }
    
    // MARK: - HTTPRequest Tests
    
    func testHTTPRequestInitialization() throws {
        let url = URL(string: "https://api.example.com/users")!
        let headers: HTTPHeaders = ["Authorization": "Bearer token"]
        let queryParams = ["limit": "10", "page": "1"]
        let bodyData = "test".data(using: .utf8)
        
        let request = HTTPRequest(
            method: .post,
            url: url,
            headers: headers,
            queryParameters: queryParams,
            body: bodyData,
            timeout: 30.0
        )
        
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.headers["Authorization"], "Bearer token")
        XCTAssertEqual(request.queryParameters["limit"], "10")
        XCTAssertEqual(request.body, bodyData)
        XCTAssertEqual(request.timeout, 30.0)
    }
    
    func testHTTPRequestConvenienceInitializers() {
        let url = URL(string: "https://api.example.com/users")!
        
        let getRequest = HTTPRequest.get(url: url)
        XCTAssertEqual(getRequest.method, .get)
        XCTAssertEqual(getRequest.url, url)
        XCTAssertNil(getRequest.body)
        
        let postRequest = HTTPRequest.post(url: url, body: "test".data(using: .utf8))
        XCTAssertEqual(postRequest.method, .post)
        XCTAssertEqual(postRequest.url, url)
        XCTAssertNotNil(postRequest.body)
    }
    
    func testHTTPRequestJSONConvenience() throws {
        struct TestBody: Codable {
            let name: String
            let age: Int
        }
        
        let url = URL(string: "https://api.example.com/users")!
        let body = TestBody(name: "John", age: 30)
        
        let request = try HTTPRequest.json(method: .post, url: url, body: body)
        
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url, url)
        XCTAssertNotNil(request.body)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }
    
    func testHTTPRequestValidation() throws {
        let url = URL(string: "https://api.example.com/users")!
        
        let validRequest = HTTPRequest.get(url: url)
        XCTAssertNoThrow(try validRequest.validate())
        
        let invalidRequest = HTTPRequest(method: .get, url: url, body: "test".data(using: .utf8))
        XCTAssertThrowsError(try invalidRequest.validate()) { error in
            guard case NetworkError.invalidRequest = error else {
                XCTFail("Expected invalidRequest error")
                return
            }
        }
        
        let timeoutRequest = HTTPRequest(method: .get, url: url, timeout: -1)
        XCTAssertThrowsError(try timeoutRequest.validate()) { error in
            guard case NetworkError.invalidRequest = error else {
                XCTFail("Expected invalidRequest error")
                return
            }
        }
    }
    
    func testHTTPRequestURLRequestConversion() throws {
        let url = URL(string: "https://api.example.com/users")!
        let headers: HTTPHeaders = ["Authorization": "Bearer token"]
        let queryParams = ["limit": "10"]
        
        let request = HTTPRequest.get(url: url, headers: headers, queryParameters: queryParams, timeout: 30.0)
        let urlRequest = try request.urlRequest()
        
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        XCTAssertEqual(urlRequest.timeoutInterval, 30.0)
        XCTAssertTrue(urlRequest.url!.absoluteString.contains("limit=10"))
    }
    
    // MARK: - HTTPResponse Tests
    
    func testHTTPResponseInitialization() {
        let data = "test response".data(using: .utf8)!
        let url = URL(string: "https://api.example.com/test")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        
        let response = HTTPResponse<Data>.data(data: data, urlResponse: httpResponse)
        
        XCTAssertEqual(response.data, data)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers["Content-Type"], "application/json")
        XCTAssertEqual(response.value, data)
        XCTAssertTrue(response.isSuccess)
        XCTAssertFalse(response.isClientError)
        XCTAssertFalse(response.isServerError)
    }
    
    func testHTTPResponseValidation() throws {
        let data = Data()
        let url = URL(string: "https://api.example.com/test")!
        
        // Success response should not throw
        let successResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let response200 = HTTPResponse<Data>.data(data: data, urlResponse: successResponse)
        XCTAssertNoThrow(try response200.validate())
        
        // Error response should throw
        let errorResponse = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let response404 = HTTPResponse<Data>.data(data: data, urlResponse: errorResponse)
        XCTAssertThrowsError(try response404.validate()) { error in
            guard case NetworkError.clientError = error else {
                XCTFail("Expected clientError")
                return
            }
        }
    }
    
    func testHTTPResponseConvenienceProperties() {
        let data = "test response".data(using: .utf8)!
        let url = URL(string: "https://api.example.com/test")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "application/json",
                "Content-Length": "13"
            ]
        )!
        
        let response = HTTPResponse<Data>.data(data: data, urlResponse: httpResponse)
        
        XCTAssertEqual(response.stringValue, "test response")
        XCTAssertEqual(response.size, 13)
        XCTAssertEqual(response.contentType, "application/json")
        XCTAssertEqual(response.contentLength, "13")
    }
}
