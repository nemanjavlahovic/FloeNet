import Foundation

/// Simple test functions that can be run to validate our implementation
public struct BasicTests {
    
    /// Test HTTPMethod functionality
    public static func testHTTPMethod() {
        print("Testing HTTPMethod...")
        
        assert(HTTPMethod.get.rawValue == "GET")
        assert(HTTPMethod.post.rawValue == "POST")
        assert(HTTPMethod.put.rawValue == "PUT")
        assert(HTTPMethod.delete.rawValue == "DELETE")
        
        assert(!HTTPMethod.get.allowsRequestBody)
        assert(HTTPMethod.post.allowsRequestBody)
        assert(HTTPMethod.put.allowsRequestBody)
        assert(!HTTPMethod.delete.allowsRequestBody)
        
        assert(HTTPMethod.get.isIdempotent)
        assert(!HTTPMethod.post.isIdempotent)
        assert(HTTPMethod.put.isIdempotent)
        assert(HTTPMethod.delete.isIdempotent)
        
        print("✅ HTTPMethod tests passed")
    }
    
    /// Test HTTPHeaders functionality
    public static func testHTTPHeaders() {
        print("Testing HTTPHeaders...")
        
        var headers = HTTPHeaders()
        assert(headers["Content-Type"] == nil)
        
        headers["Content-Type"] = "application/json"
        assert(headers["content-type"] == "application/json")
        assert(headers["CONTENT-TYPE"] == "application/json")
        
        let jsonHeaders = HTTPHeaders.json
        assert(jsonHeaders["Content-Type"] == "application/json")
        
        print("✅ HTTPHeaders tests passed")
    }
    
    /// Test NetworkError functionality
    public static func testNetworkError() {
        print("Testing NetworkError...")
        
        let connectivityError = NetworkError.noInternetConnection
        assert(connectivityError.isConnectivityError)
        assert(!connectivityError.isClientError)
        assert(!connectivityError.isServerError)
        assert(connectivityError.isRetryable)
        
        let clientError = NetworkError.clientError(statusCode: 404, data: nil)
        assert(!clientError.isConnectivityError)
        assert(clientError.isClientError)
        assert(!clientError.isServerError)
        assert(!clientError.isRetryable)
        assert(clientError.statusCode == 404)
        
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        assert(!serverError.isConnectivityError)
        assert(!serverError.isClientError)
        assert(serverError.isServerError)
        assert(serverError.isRetryable)
        assert(serverError.statusCode == 500)
        
        print("✅ NetworkError tests passed")
    }
    
    /// Test HTTPRequest functionality
    public static func testHTTPRequest() throws {
        print("Testing HTTPRequest...")
        
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
        
        assert(request.method == .post)
        assert(request.url == url)
        assert(request.headers["Authorization"] == "Bearer token")
        assert(request.queryParameters["limit"] == "10")
        assert(request.body == bodyData)
        assert(request.timeout == 30.0)
        
        let getRequest = HTTPRequest.get(url: url)
        assert(getRequest.method == .get)
        assert(getRequest.url == url)
        assert(getRequest.body == nil)
        
        let validRequest = HTTPRequest.get(url: url)
        try validRequest.validate()
        
        print("✅ HTTPRequest tests passed")
    }
    
    /// Test HTTPResponse functionality
    public static func testHTTPResponse() {
        print("Testing HTTPResponse...")
        
        let data = "test response".data(using: .utf8)!
        let url = URL(string: "https://api.example.com/test")!
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        
        let response = HTTPResponse<Data>.data(data: data, urlResponse: httpResponse)
        
        assert(response.data == data)
        assert(response.statusCode == 200)
        assert(response.headers["Content-Type"] == "application/json")
        assert(response.value == data)
        assert(response.isSuccess)
        assert(!response.isClientError)
        assert(!response.isServerError)
        
        print("✅ HTTPResponse tests passed")
    }
    
    /// Run all tests
    public static func runAllTests() {
        print("🧪 Running FloeNet Basic Tests...")
        print()
        
        do {
            testHTTPMethod()
            testHTTPHeaders()
            testNetworkError()
            try testHTTPRequest()
            testHTTPResponse()
            
            print()
            print("🎉 All tests passed!")
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
} 