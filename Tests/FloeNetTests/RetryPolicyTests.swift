import XCTest
@testable import FloeNet

final class RetryPolicyTests: XCTestCase {
    
    // MARK: - Basic Policy Tests
    
    func testDefaultRetryPolicy() {
        let policy = RetryPolicy()
        
        XCTAssertEqual(policy.maxRetries, 3)
        XCTAssertEqual(policy.baseDelay, 1.0)
        XCTAssertEqual(policy.maxDelay, 30.0)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
        XCTAssertTrue(policy.jitterEnabled)
    }
    
    func testCustomRetryPolicy() {
        let policy = RetryPolicy(
            maxRetries: 5,
            baseDelay: 0.5,
            maxDelay: 60.0,
            backoffMultiplier: 1.5,
            jitterEnabled: false,
            shouldRetry: { error, attempt in
                return error.isServerError && attempt < 2
            }
        )
        
        XCTAssertEqual(policy.maxRetries, 5)
        XCTAssertEqual(policy.baseDelay, 0.5)
        XCTAssertEqual(policy.maxDelay, 60.0)
        XCTAssertEqual(policy.backoffMultiplier, 1.5)
        XCTAssertFalse(policy.jitterEnabled)
    }
    
    // MARK: - Predefined Policies Tests
    
    func testNeverRetryPolicy() {
        let policy = RetryPolicy.never
        
        XCTAssertEqual(policy.maxRetries, 0)
        
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        XCTAssertFalse(policy.shouldRetry(serverError, 0))
    }
    
    func testConservativeRetryPolicy() {
        let policy = RetryPolicy.conservative
        
        XCTAssertEqual(policy.maxRetries, 1)
        XCTAssertEqual(policy.baseDelay, 2.0)
        XCTAssertEqual(policy.maxDelay, 2.0)
        XCTAssertEqual(policy.backoffMultiplier, 1.0)
        
        // Test delay calculation (should be constant at 2.0)
        let delay0 = policy.delay(for: 0)
        let delay1 = policy.delay(for: 1)
        
        if policy.jitterEnabled {
            // With jitter, should be within range
            XCTAssertGreaterThanOrEqual(delay0, 1.0)
            XCTAssertLessThanOrEqual(delay0, 3.0)
            XCTAssertGreaterThanOrEqual(delay1, 1.0)
            XCTAssertLessThanOrEqual(delay1, 3.0)
        } else {
            XCTAssertEqual(delay0, 2.0)
            XCTAssertEqual(delay1, 2.0)
        }
    }
    
    func testStandardRetryPolicy() {
        let policy = RetryPolicy.standard
        
        XCTAssertEqual(policy.maxRetries, 3)
        XCTAssertEqual(policy.baseDelay, 1.0)
        XCTAssertEqual(policy.maxDelay, 30.0)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
    }
    
    func testAggressiveRetryPolicy() {
        let policy = RetryPolicy.aggressive
        
        XCTAssertEqual(policy.maxRetries, 5)
        XCTAssertEqual(policy.baseDelay, 0.5)
        XCTAssertEqual(policy.maxDelay, 60.0)
        XCTAssertEqual(policy.backoffMultiplier, 1.5)
    }
    
    func testServerErrorsOnlyPolicy() {
        let policy = RetryPolicy.serverErrorsOnly
        
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        let clientError = NetworkError.clientError(statusCode: 404, data: nil)
        let connectivityError = NetworkError.noInternetConnection
        let decodingError = NetworkError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Test")))
        
        XCTAssertTrue(policy.shouldRetry(serverError, 0))
        XCTAssertFalse(policy.shouldRetry(clientError, 0))
        XCTAssertTrue(policy.shouldRetry(connectivityError, 0))
        XCTAssertFalse(policy.shouldRetry(decodingError, 0))
    }
    
    func testCustomRetryCondition() {
        let policy = RetryPolicy.custom(
            maxRetries: 2,
            baseDelay: 1.0,
            condition: { error, attempt in
                // Only retry rate limit errors
                return error.statusCode == 429 && attempt < 2
            }
        )
        
        let rateLimitError = NetworkError.httpError(statusCode: 429, data: nil)
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        
        XCTAssertTrue(policy.shouldRetry(rateLimitError, 0))
        XCTAssertTrue(policy.shouldRetry(rateLimitError, 1))
        XCTAssertFalse(policy.shouldRetry(rateLimitError, 2))
        XCTAssertFalse(policy.shouldRetry(serverError, 0))
    }
    
    // MARK: - Delay Calculation Tests
    
    func testExponentialBackoffWithoutJitter() {
        let policy = RetryPolicy(
            maxRetries: 4,
            baseDelay: 1.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0,
            jitterEnabled: false
        )
        
        // Test exponential backoff: 1, 2, 4, 8
        XCTAssertEqual(policy.delay(for: 0), 1.0)
        XCTAssertEqual(policy.delay(for: 1), 2.0)
        XCTAssertEqual(policy.delay(for: 2), 4.0)
        XCTAssertEqual(policy.delay(for: 3), 8.0)
    }
    
    func testExponentialBackoffWithMaxDelay() {
        let policy = RetryPolicy(
            maxRetries: 10,
            baseDelay: 1.0,
            maxDelay: 5.0,
            backoffMultiplier: 2.0,
            jitterEnabled: false
        )
        
        // Should cap at maxDelay
        XCTAssertEqual(policy.delay(for: 0), 1.0)
        XCTAssertEqual(policy.delay(for: 1), 2.0)
        XCTAssertEqual(policy.delay(for: 2), 4.0)
        XCTAssertEqual(policy.delay(for: 3), 5.0) // Capped at maxDelay
        XCTAssertEqual(policy.delay(for: 4), 5.0) // Still capped
    }
    
    func testJitterRange() {
        let policy = RetryPolicy(
            maxRetries: 3,
            baseDelay: 2.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0,
            jitterEnabled: true
        )
        
        // Test jitter is within expected range (0.5 to 1.5 multiplier)
        let attempts = 100
        var delays: [TimeInterval] = []
        
        for _ in 0..<attempts {
            let delay = policy.delay(for: 0) // baseDelay = 2.0
            delays.append(delay)
        }
        
        let minExpected = 2.0 * 0.5 // 1.0
        let maxExpected = 2.0 * 1.5 // 3.0
        
        for delay in delays {
            XCTAssertGreaterThanOrEqual(delay, minExpected)
            XCTAssertLessThanOrEqual(delay, maxExpected)
        }
        
        // Ensure we have some variation (not all the same)
        let uniqueDelays = Set(delays.map { ($0 * 1000).rounded() / 1000 }) // Round to 3 decimal places
        XCTAssertGreaterThan(uniqueDelays.count, 1, "Jitter should produce varied delays")
    }
    
    func testDifferentBackoffMultipliers() {
        let linearPolicy = RetryPolicy(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            backoffMultiplier: 1.0,
            jitterEnabled: false
        )
        
        let moderatePolicy = RetryPolicy(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            backoffMultiplier: 1.5,
            jitterEnabled: false
        )
        
        // Linear backoff (multiplier = 1.0)
        XCTAssertEqual(linearPolicy.delay(for: 0), 1.0)
        XCTAssertEqual(linearPolicy.delay(for: 1), 1.0)
        XCTAssertEqual(linearPolicy.delay(for: 2), 1.0)
        
        // Moderate backoff (multiplier = 1.5)
        XCTAssertEqual(moderatePolicy.delay(for: 0), 1.0)
        XCTAssertEqual(moderatePolicy.delay(for: 1), 1.5)
        XCTAssertEqual(moderatePolicy.delay(for: 2), 2.25)
    }
    
    // MARK: - Retry Condition Tests
    
    func testDefaultRetryConditions() {
        let policy = RetryPolicy.standard
        
        // Retryable errors
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        let connectivityError = NetworkError.noInternetConnection
        let timeoutError = NetworkError.requestTimeout
        let rateLimitError = NetworkError.httpError(statusCode: 429, data: nil)
        
        XCTAssertTrue(policy.shouldRetry(serverError, 0))
        XCTAssertTrue(policy.shouldRetry(connectivityError, 0))
        XCTAssertTrue(policy.shouldRetry(timeoutError, 0))
        XCTAssertTrue(policy.shouldRetry(rateLimitError, 0))
        
        // Non-retryable errors
        let clientError = NetworkError.clientError(statusCode: 404, data: nil)
        let decodingError = NetworkError.decodingError(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Test")))
        let invalidRequest = NetworkError.invalidRequest("Test")
        
        XCTAssertFalse(policy.shouldRetry(clientError, 0))
        XCTAssertFalse(policy.shouldRetry(decodingError, 0))
        XCTAssertFalse(policy.shouldRetry(invalidRequest, 0))
    }
    
    func testRetryAttemptLimits() {
        let policy = RetryPolicy.standard // maxRetries = 3
        
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        
        // Should retry within limits
        XCTAssertTrue(policy.shouldRetry(serverError, 0))
        XCTAssertTrue(policy.shouldRetry(serverError, 1))
        XCTAssertTrue(policy.shouldRetry(serverError, 2))
        
        // Default implementation doesn't check attempt count, only error type
        // The HTTPClient should enforce the maxRetries limit
        XCTAssertTrue(policy.shouldRetry(serverError, 3))
        XCTAssertTrue(policy.shouldRetry(serverError, 10))
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroMaxRetries() {
        let policy = RetryPolicy(maxRetries: 0)
        
        let serverError = NetworkError.serverError(statusCode: 500, data: nil)
        // The shouldRetry function still evaluates the error, maxRetries is enforced by HTTPClient
        XCTAssertTrue(policy.shouldRetry(serverError, 0))
    }
    
    func testVeryLargeDelays() {
        let policy = RetryPolicy(
            maxRetries: 10,
            baseDelay: 100.0,
            maxDelay: 1000.0,
            backoffMultiplier: 3.0,
            jitterEnabled: false
        )
        
        // Should handle large delays without overflow
        let delay0 = policy.delay(for: 0)
        let delay1 = policy.delay(for: 1)
        let delay2 = policy.delay(for: 2)
        
        XCTAssertEqual(delay0, 100.0)
        XCTAssertEqual(delay1, 300.0)
        XCTAssertEqual(delay2, 900.0)
        
        let delay3 = policy.delay(for: 3)
        XCTAssertEqual(delay3, 1000.0) // Capped at maxDelay
    }
    
    func testZeroBaseDelay() {
        let policy = RetryPolicy(
            maxRetries: 3,
            baseDelay: 0.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0,
            jitterEnabled: false
        )
        
        // All delays should be 0
        XCTAssertEqual(policy.delay(for: 0), 0.0)
        XCTAssertEqual(policy.delay(for: 1), 0.0)
        XCTAssertEqual(policy.delay(for: 2), 0.0)
    }
    
    func testVerySmallBackoffMultiplier() {
        let policy = RetryPolicy(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            backoffMultiplier: 0.5,
            jitterEnabled: false
        )
        
        // Delays should decrease with small multiplier
        XCTAssertEqual(policy.delay(for: 0), 1.0)
        XCTAssertEqual(policy.delay(for: 1), 0.5)
        XCTAssertEqual(policy.delay(for: 2), 0.25)
    }
    
    // MARK: - Performance Tests
    
    func testDelayCalculationPerformance() {
        let policy = RetryPolicy.standard
        
        measure {
            for attempt in 0..<1000 {
                _ = policy.delay(for: attempt % 10)
            }
        }
    }
    
    func testRetryConditionPerformance() {
        let policy = RetryPolicy.standard
        let errors = [
            NetworkError.serverError(statusCode: 500, data: nil),
            NetworkError.clientError(statusCode: 404, data: nil),
            NetworkError.noInternetConnection,
            NetworkError.requestTimeout
        ]
        
        measure {
            for i in 0..<1000 {
                let error = errors[i % errors.count]
                _ = policy.shouldRetry(error, i % 5)
            }
        }
    }
} 