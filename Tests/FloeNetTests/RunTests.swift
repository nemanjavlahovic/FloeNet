import Foundation
import FloeNet

/// Quick test execution script
/// Uncomment the Task block below and run this file to test FloeNet functionality

/*
@available(iOS 15.0, macOS 12.0, *)
extension Task where Success == Never, Failure == Never {
    static func runFloeNetTests() async {
        print("🚀 Starting FloeNet Test Execution")
        print("==================================")
        print()
        
        // First run the simple basic tests
        print("📋 Basic Function Tests:")
        BasicTests.runAllTests()
        print()
        
        // Then run the comprehensive test suite
        print("🧪 Comprehensive Test Suite:")
        await TestRunner.runAllTests()
    }
}

// Uncomment the line below to run tests:
// Task { await Task.runFloeNetTests() }
*/

/// Instructions for running tests:
/// 
/// 1. **Via Xcode:**
///    - Open the FloeNet project in Xcode
///    - Uncomment the Task line above
///    - Run this file or build the project
///
/// 2. **Via Swift Package Manager:**
///    - Run: `swift test` from the project root
///    - This will run the XCTest suite (HTTPClientTests, RetryPolicyTests, etc.)
///
/// 3. **Via command line (quick tests):**
///    - Uncomment the BasicTests.runAllTests() line in this file
///    - Run: `swift run` (if you have an executable target)
///
/// 4. **Individual component testing:**
///    - Import FloeNet in a playground or test app
///    - Call BasicTests.runAllTests() or TestRunner.runAllTests()
///
/// **Test Categories Available:**
///
/// 📦 **Unit Tests (Offline):**
/// - HTTPMethod functionality
/// - HTTPHeaders case-insensitive handling
/// - NetworkError classification
/// - HTTPRequest validation and creation
/// - HTTPResponse parsing
/// - RetryPolicy calculations
/// - NetworkConfiguration building
///
/// 🌐 **Integration Tests (Online - requires internet):**
/// - Real HTTP requests to httpbin.org
/// - GET, POST, PUT, DELETE operations
/// - JSON encoding/decoding
/// - Header and query parameter handling
/// - Response type conversion
///
/// ⚡ **Performance Tests:**
/// - Concurrent request handling
/// - Memory usage validation
/// - Retry policy computation speed
/// - Large response handling
///
/// ❌ **Error Scenario Tests:**
/// - 4xx client errors
/// - 5xx server errors
/// - Network timeout handling
/// - JSON decoding failures
/// - Invalid URL handling
///
/// **Expected Results:**
/// ✅ All basic functionality should pass
/// ✅ Integration tests require internet connection
/// ✅ Performance tests should complete quickly
/// ✅ Error scenarios should fail gracefully with proper error types

public struct TestInstructions {
    
    public static func printQuickStart() {
        print("""
        🚀 FloeNet Quick Test Guide
        ===========================
        
        To quickly verify FloeNet works:
        
        1️⃣  Run basic offline tests:
           BasicTests.runAllTests()
        
        2️⃣  Run comprehensive tests (requires internet):
           await TestRunner.runAllTests()
        
        3️⃣  Run XCTest suite:
           swift test
        
        4️⃣  Test individual components:
           - HTTPClientTests (⚠️  requires internet)
           - RetryPolicyTests
           - FloeNetTests (existing basic tests)
        
        ✨ Quick verification in a playground:
        
        ```swift
        import FloeNet
        
        // Test basic functionality
        BasicTests.runAllTests()
        
        // Test with real network (async context needed)
        Task {
            await TestRunner.runAllTests()
        }
        
        // Manual quick test
        Task {
            let client = HTTPClient()
            let url = URL(string: "https://httpbin.org/get")!
            let response = try await client.get(url: url)
            print("Status: \\(response.statusCode)")
            print("✅ FloeNet is working!")
        }
        ```
        """)
    }
} 