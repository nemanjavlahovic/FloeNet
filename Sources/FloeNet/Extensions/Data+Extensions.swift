import Foundation

extension Data {
    /// Decode JSON data to a Decodable type
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - decoder: JSON decoder to use (default: JSONDecoder())
    /// - Returns: Decoded object
    /// - Throws: NetworkError.decodingError if decoding fails
    public func decode<T: Decodable>(
        to type: T.Type,
        using decoder: JSONDecoder = JSONDecoder()
    ) throws -> T {
        do {
            return try decoder.decode(type, from: self)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    /// Convert data to JSON object
    /// - Returns: JSON object (Dictionary, Array, or primitive)
    /// - Throws: NetworkError if data is not valid JSON
    public func toJSONObject() throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: self, options: [])
        } catch {
            throw NetworkError.decodingError(DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON data")
            ))
        }
    }
    
    /// Convert data to pretty-printed JSON string
    /// - Returns: Formatted JSON string
    /// - Throws: NetworkError if data is not valid JSON
    public func toPrettyJSONString() throws -> String {
        let jsonObject = try toJSONObject()
        let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        
        guard let jsonString = String(data: prettyData, encoding: .utf8) else {
            throw NetworkError.invalidResponse
        }
        
        return jsonString
    }
    
    /// Check if data is valid JSON
    /// - Returns: true if data is valid JSON, false otherwise
    public var isValidJSON: Bool {
        do {
            _ = try JSONSerialization.jsonObject(with: self, options: [])
            return true
        } catch {
            return false
        }
    }
    
    /// Get human-readable size string
    /// - Returns: Formatted size string (e.g., "1.5 KB", "2.3 MB")
    public var sizeString: String {
        let bytes = count
        
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", Double(bytes) / (1024 * 1024 * 1024))
        }
    }
    
    /// Convert data to UTF-8 string
    /// - Returns: UTF-8 string representation or nil if conversion fails
    public var utf8String: String? {
        return String(data: self, encoding: .utf8)
    }
    
    /// Convert data to hex string
    /// - Returns: Hexadecimal representation of the data
    public var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
    
    /// Check if data appears to be binary (contains non-printable characters)
    /// - Returns: true if data appears to be binary, false if it appears to be text
    public var isBinary: Bool {
        guard !isEmpty else { return false }
        
        let sampleSize = Swift.min(count, 512)
        let sample = prefix(sampleSize)
        
        for byte in sample {
            if byte < 32 && byte != 9 && byte != 10 && byte != 13 {
                return true
            }
        }
        
        return false
    }
    
    /// Validate data size against limits
    /// - Parameters:
    ///   - minSize: Minimum allowed size (nil for no minimum)
    ///   - maxSize: Maximum allowed size (nil for no maximum)
    /// - Throws: NetworkError if size is outside allowed range
    public func validateSize(minSize: Int? = nil, maxSize: Int? = nil) throws {
        let size = count
        
        if let minSize = minSize, size < minSize {
            throw NetworkError.invalidResponse
        }
        
        if let maxSize = maxSize, size > maxSize {
            throw NetworkError.responseTooLarge
        }
    }
}

// MARK: - JSON Encoding Support
extension Encodable {
    /// Encode object to JSON Data
    /// - Parameter encoder: JSON encoder to use (default: JSONEncoder())
    /// - Returns: JSON data representation
    /// - Throws: NetworkError.encodingError if encoding fails
    public func toJSONData(using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        do {
            return try encoder.encode(self)
        } catch let encodingError as EncodingError {
            throw NetworkError.encodingError(encodingError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    /// Encode object to pretty-printed JSON string
    /// - Returns: Formatted JSON string
    /// - Throws: NetworkError if encoding fails
    public func toPrettyJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try toJSONData(using: encoder)
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NetworkError.encodingError(EncodingError.invalidValue(
                self,
                EncodingError.Context(codingPath: [], debugDescription: "Failed to convert JSON data to string")
            ))
        }
        
        return jsonString
    }
}

// MARK: - Dictionary Extensions for URL Parameters
extension Dictionary where Key == String, Value == String {
    /// Convert dictionary to URL query string
    /// - Returns: URL-encoded query string
    public var queryString: String {
        return compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return nil
            }
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
    }
    
    /// Convert dictionary to Data for form-encoded body
    /// - Returns: Form-encoded data
    public var formEncodedData: Data {
        return queryString.data(using: .utf8) ?? Data()
    }
} 