import Foundation
import FloeNet

/// Example demonstrating basic FloeNet usage
struct BasicUsageExample {
    
    /// Example of making a simple GET request
    static func simpleGetRequest() async {
        print("📡 Making a simple GET request...")
        
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/get")!
        
        do {
            let response = try await client.get(url: url)
            print("✅ Success! Status: \(response.statusCode)")
            print("📄 Response: \(response.stringValue ?? "No data")")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Example of making a POST request with JSON
    static func jsonPostRequest() async {
        print("📡 Making a POST request with JSON...")
        
        struct User: Codable {
            let name: String
            let email: String
        }
        
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/post")!
        let user = User(name: "John Doe", email: "john@example.com")
        
        do {
            let response = try await client.post(url: url, body: user)
            print("✅ Success! Status: \(response.statusCode)")
            print("📄 Response: \(response.stringValue ?? "No data")")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Example of using the convenience Floe API
    static func convenienceAPI() async {
        print("📡 Using convenience Floe API...")
        
        let url = URL(string: "https://httpbin.org/get")!
        
        do {
            let response = try await Floe.get(url: url)
            print("✅ Success! Status: \(response.statusCode)")
            print("📄 Response: \(response.stringValue ?? "No data")")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Example of custom request building
    static func customRequest() async {
        print("📡 Building a custom request...")
        
        let url = URL(string: "https://httpbin.org/headers")!
        let headers: HTTPHeaders = [
            "Authorization": "Bearer token123",
            "User-Agent": "FloeNet/1.0"
        ]
        let queryParams = ["format": "json", "limit": "10"]
        
        let request = HTTPRequest.get(
            url: url,
            headers: headers,
            queryParameters: queryParams,
            timeout: 30.0
        )
        
        let client = HTTPClient()
        
        do {
            let response = try await client.send(request)
            print("✅ Success! Status: \(response.statusCode)")
            print("📄 Response: \(response.stringValue ?? "No data")")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    /// Example of error handling
    static func errorHandling() async {
        print("📡 Demonstrating error handling...")
        
        let client = HTTPClient()
        let url = URL(string: "https://httpbin.org/status/404")!
        
        let result = await client.sendRequest(HTTPRequest.get(url: url))
        
        switch result {
        case .success(let response):
            print("✅ Success! Status: \(response.statusCode)")
        case .failure(let error):
            print("❌ Error: \(error.localizedDescription)")
            
            if error.isClientError {
                print("🔍 This is a client error (4xx)")
            }
            
            if let statusCode = error.statusCode {
                print("📊 Status code: \(statusCode)")
            }
        }
    }
    
    /// Run all examples
    static func runAllExamples() async {
        print("🚀 FloeNet Basic Usage Examples")
        print("================================")
        print()
        
        await simpleGetRequest()
        print()
        
        await jsonPostRequest()
        print()
        
        await convenienceAPI()
        print()
        
        await customRequest()
        print()
        
        await errorHandling()
        print()
        
        print("🎉 All examples completed!")
    }
}

// Uncomment to run examples:
// Task {
//     await BasicUsageExample.runAllExamples()
// } 