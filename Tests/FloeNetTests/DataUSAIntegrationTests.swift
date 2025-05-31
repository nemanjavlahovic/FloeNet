import XCTest
@testable import FloeNet

/// Integration tests using the real DataUSA API to demonstrate FloeNet's capabilities
/// with real-world JSON APIs
@available(iOS 15.0, macOS 12.0, *)
final class DataUSAIntegrationTests: XCTestCase {
    
    private var httpClient: HTTPClient!
    
    override func setUp() {
        super.setUp()
        httpClient = HTTPClient()
    }
    
    override func tearDown() {
        httpClient = nil
        super.tearDown()
    }
    
    func testDataUSAPopulationAPI() async throws {
        let url = TestUtilities.TestURLs.dataUSAPopulation
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.send(request, expecting: DataUSAResponse.self)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.isSuccess)
        XCTAssertNotNil(response.value)
        
        guard let populationData = response.value else {
            XCTFail("Failed to decode DataUSA response")
            return
        }
        
        // Verify we have population data
        XCTAssertFalse(populationData.data.isEmpty, "Should have population data")
        
        // Check first entry (most recent year)
        let latestData = populationData.data.first!
        XCTAssertEqual(latestData.nation, "United States")
        XCTAssertTrue(latestData.population > 300_000_000, "US population should be > 300M")
        XCTAssertFalse(latestData.year.isEmpty)
        
        // Verify metadata
        XCTAssertFalse(populationData.source.isEmpty, "Should have source metadata")
        let source = populationData.source.first!
        XCTAssertEqual(source.annotations.sourceName, "Census Bureau")
        XCTAssertTrue(source.measures.contains("Population"))
        
        print("✅ Retrieved \(populationData.data.count) years of US population data")
        print("📈 Latest: \(latestData.year) - \(latestData.population.formatted()) people")
    }
    
    func testDataUSAWithRequestBuilder() async throws {
        // Demonstrate RequestBuilder pattern with DataUSA API
        let response = try await RequestBuilder()
            .url(TestUtilities.TestURLs.dataUSABase)
            .get()
            .query("drilldowns", "Nation")
            .query("measures", "Population")
            .header("User-Agent", "FloeNet-Test/1.0")
            .timeout(30.0)
            .send(with: httpClient, expecting: DataUSAResponse.self)
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertNotNil(response.value)
        
        let populationData = response.value!
        XCTAssertFalse(populationData.data.isEmpty)
        XCTAssertEqual(populationData.data.first?.nation, "United States")
        
        print("✅ RequestBuilder + DataUSA API working correctly")
    }
    
    func testDataUSAResponseValidation() async throws {
        let response = try await httpClient.get(url: TestUtilities.TestURLs.dataUSAPopulation)
        
        // Validate response headers
        XCTAssertTrue(response.isSuccess)
        XCTAssertNotNil(response.contentType)
        XCTAssertTrue(response.contentType?.contains("json") == true)
        
        // Validate response body
        XCTAssertFalse(response.data.isEmpty)
        
        let responseString = response.stringValue ?? ""
        XCTAssertTrue(responseString.contains("United States"))
        XCTAssertTrue(responseString.contains("Population"))
        XCTAssertTrue(responseString.contains("Census Bureau"))
        
        print("✅ DataUSA API response validation successful")
    }
    
    func testConcurrentDataUSARequests() async throws {
        // Test multiple concurrent requests to DataUSA API
        let requestCount = 3
        let results = try await withThrowingTaskGroup(of: DataUSAResponse.self, returning: [DataUSAResponse].self) { group in
            
            for i in 0..<requestCount {
                group.addTask { [self] in
                    let request = HTTPRequest.get(
                        url: TestUtilities.TestURLs.dataUSAPopulation,
                        headers: ["X-Request-ID": "concurrent-test-\(i)"]
                    )
                    let response = try await httpClient.send(request, expecting: DataUSAResponse.self)
                    return response.value!
                }
            }
            
            var results: [DataUSAResponse] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        
        XCTAssertEqual(results.count, requestCount)
        
        // All requests should return the same data
        let firstResult = results.first!
        for result in results {
            XCTAssertEqual(result.data.count, firstResult.data.count)
            XCTAssertEqual(result.data.first?.nation, "United States")
        }
        
        print("✅ \(requestCount) concurrent DataUSA API requests completed successfully")
    }
} 
