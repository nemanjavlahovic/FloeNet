import Foundation
import FloeNet

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@main
struct FloeNetTestRunner {
    static func main() async {
        print("🧪 FloeNet Test Runner")
        print("======================")
        print()
        
        // Run basic offline tests first
        print("📦 Phase 1: Basic Component Tests (Offline)")
        print("--------------------------------------------")
        BasicTests.runAllTests()
        print()
        
        // Check if we can run online tests
        print("🌐 Phase 2: Integration Tests (Online)")
        print("---------------------------------------")
        
        // Simple connectivity check
        if await checkInternetConnectivity() {
            print("✅ Internet connection detected, running online tests...")
            await runOnlineTests()
        } else {
            print("⚠️  No internet connection, skipping online tests")
            print("   To run full tests, ensure internet connectivity and run again")
        }
        
        print()
        print("🎯 Test Runner Complete!")
        print("For more comprehensive testing, run: swift test")
        print("For XCTest-based tests, ensure macOS/iOS development environment")
    }
    
    static func checkInternetConnectivity() async -> Bool {
        do {
            let client = HTTPClient()
            let url = URL(string: "https://httpbin.org/status/200")!
            let request = HTTPRequest.get(url: url, timeout: 5.0)
            
            let response = try await client.send(request)
            return response.statusCode == 200
        } catch {
            return false
        }
    }
    
    static func runOnlineTests() async {
        await testBasicGETRequest()
        await testPOSTWithJSON()
        await testErrorHandling()
        await testRetryBehavior()
    }
    
    static func testBasicGETRequest() async {
        print("Testing: Basic GET request...")
        
        do {
            let client = HTTPClient()
            let url = URL(string: "https://httpbin.org/get")!
            let request = HTTPRequest.get(url: url)
            
            let response = try await client.send(request)
            
            if response.statusCode == 200 && response.isSuccess {
                print("  ✅ Basic GET request successful")
            } else {
                print("  ❌ Basic GET request failed: Status \(response.statusCode)")
            }
        } catch {
            print("  ❌ Basic GET request failed: \(error)")
        }
    }
    
    static func testPOSTWithJSON() async {
        print("Testing: POST request with JSON...")
        
        struct TestPayload: Codable {
            let name: String
            let value: Int
        }
        
        do {
            let client = HTTPClient()
            let url = URL(string: "https://httpbin.org/post")!
            let payload = TestPayload(name: "FloeNet Test", value: 42)
            let request = try HTTPRequest.json(method: .post, url: url, body: payload)
            
            let response = try await client.send(request)
            
            if response.statusCode == 200 {
                let responseString = response.stringValue ?? ""
                if responseString.contains("FloeNet Test") && responseString.contains("42") {
                    print("  ✅ POST with JSON successful")
                } else {
                    print("  ❌ POST response doesn't contain expected data")
                }
            } else {
                print("  ❌ POST request failed: Status \(response.statusCode)")
            }
        } catch {
            print("  ❌ POST with JSON failed: \(error)")
        }
    }
    
    static func testErrorHandling() async {
        print("Testing: Error handling...")
        
        do {
            let client = HTTPClient()
            let url = URL(string: "https://httpbin.org/status/404")!
            let request = HTTPRequest.get(url: url)
            
            _ = try await client.send(request)
            print("  ❌ 404 request should have failed")
        } catch let error as NetworkError {
            if error.isClientError && error.statusCode == 404 {
                print("  ✅ Error handling working correctly (404 detected)")
            } else {
                print("  ❌ Wrong error type: \(error)")
            }
        } catch {
            print("  ❌ Unexpected error type: \(error)")
        }
    }
    
    static func testRetryBehavior() async {
        print("Testing: Retry policy behavior...")
        
        // Test retry policy configuration
        let policy = RetryPolicy.standard
        
        if policy.maxRetries == 3 && 
           policy.baseDelay == 1.0 && 
           policy.delay(for: 0) == 1.0 {
            print("  ✅ Retry policy configuration correct")
        } else {
            print("  ❌ Retry policy configuration incorrect")
        }
        
        // Test with a server that returns 500 (should retry)
        do {
            let config = NetworkConfiguration.builder
                .retryPolicy(.conservative) // Only 1 retry for testing
                .build()
            
            let client = HTTPClient(configuration: config)
            let url = URL(string: "https://httpbin.org/status/500")!
            let request = HTTPRequest.get(url: url)
            
            _ = try await client.send(request)
            
            print("  ❌ 500 request should have failed after retries")
        } catch let error as NetworkError {
            if error.isServerError {
                print("  ✅ Retry behavior working (server error after retries)")
            } else {
                print("  ❌ Wrong error after retries: \(error)")
            }
        } catch {
            print("  ❌ Unexpected error during retry test: \(error)")
        }
    }
} 