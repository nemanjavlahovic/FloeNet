import Foundation
import Security
import CryptoKit

/// Security manager for network requests
public final class SecurityManager: Sendable {
    /// SSL certificate pinning configuration
    public struct SSLPinningConfiguration: Sendable {
        /// Pinning policy
        public enum Policy: Sendable {
            /// Pin specific certificates
            case certificate([Data])
            /// Pin public keys
            case publicKey([SecKey])
            /// Pin certificate authority
            case certificateAuthority([Data])
        }
        
        /// Pinning policy to use
        public let policy: Policy
        
        /// Whether to allow pinning bypass in debug builds
        public let allowDebugBypass: Bool
        
        /// Custom validation handler
        public let customValidator: (@Sendable (SecTrust, String) -> Bool)?
        
        public init(
            policy: Policy,
            allowDebugBypass: Bool = false,
            customValidator: (@Sendable (SecTrust, String) -> Bool)? = nil
        ) {
            self.policy = policy
            self.allowDebugBypass = allowDebugBypass
            self.customValidator = customValidator
        }
    }
    
    /// HTTPS enforcement configuration
    public struct HTTPSConfiguration: Sendable {
        /// HTTPS enforcement level
        public enum Level: Sendable {
            /// No enforcement (allow HTTP)
            case none
            /// Warn on HTTP usage
            case warn
            /// Block HTTP requests
            case strict
            /// Allow HTTP only for specific hosts
            case allowList(Set<String>)
        }
        
        /// Enforcement level
        public let level: Level
        
        /// Custom HTTP handler
        public let httpHandler: (@Sendable (URL) -> Bool)?
        
        public init(
            level: Level = .strict,
            httpHandler: (@Sendable (URL) -> Bool)? = nil
        ) {
            self.level = level
            self.httpHandler = httpHandler
        }
        
        /// Strict HTTPS only
        public static let strict = HTTPSConfiguration(level: .strict)
        
        /// Allow HTTP for localhost/development
        public static let development = HTTPSConfiguration(
            level: .allowList(["localhost", "127.0.0.1", "0.0.0.0"])
        )
    }
    
    /// Request signing configuration
    public struct RequestSigningConfiguration: Sendable {
        /// Signing algorithm
        public enum Algorithm: Sendable {
            case hmacSHA256(key: Data)
            case ed25519(privateKey: Data)
            case rsa(privateKey: SecKey)
        }
        
        /// Signing algorithm
        public let algorithm: Algorithm
        
        /// Header name for signature
        public let signatureHeader: String
        
        /// Additional headers to include in signature
        public let includedHeaders: Set<String>
        
        /// Whether to include request body in signature
        public let includeBody: Bool
        
        /// Custom signature formatter
        public let signatureFormatter: (@Sendable (Data) -> String)?
        
        public init(
            algorithm: Algorithm,
            signatureHeader: String = "X-Signature",
            includedHeaders: Set<String> = ["Date", "Content-Type"],
            includeBody: Bool = true,
            signatureFormatter: (@Sendable (Data) -> String)? = nil
        ) {
            self.algorithm = algorithm
            self.signatureHeader = signatureHeader
            self.includedHeaders = includedHeaders
            self.includeBody = includeBody
            self.signatureFormatter = signatureFormatter
        }
    }
    
    /// Security configuration
    public struct Configuration: Sendable {
        /// SSL pinning configuration
        public let sslPinning: SSLPinningConfiguration?
        
        /// HTTPS enforcement configuration
        public let httpsEnforcement: HTTPSConfiguration
        
        /// Request signing configuration
        public let requestSigning: RequestSigningConfiguration?
        
        /// Whether to validate hostname
        public let validateHostname: Bool
        
        /// Custom certificate validation
        public let customCertificateValidation: (@Sendable (SecTrust, String) -> Bool)?
        
        /// Security event handler
        public let securityEventHandler: (@Sendable (SecurityEvent) -> Void)?
        
        public init(
            sslPinning: SSLPinningConfiguration? = nil,
            httpsEnforcement: HTTPSConfiguration = .strict,
            requestSigning: RequestSigningConfiguration? = nil,
            validateHostname: Bool = true,
            customCertificateValidation: (@Sendable (SecTrust, String) -> Bool)? = nil,
            securityEventHandler: (@Sendable (SecurityEvent) -> Void)? = nil
        ) {
            self.sslPinning = sslPinning
            self.httpsEnforcement = httpsEnforcement
            self.requestSigning = requestSigning
            self.validateHostname = validateHostname
            self.customCertificateValidation = customCertificateValidation
            self.securityEventHandler = securityEventHandler
        }
        
        /// Development configuration (relaxed security)
        public static let development = Configuration(
            httpsEnforcement: .development,
            validateHostname: false
        )
        
        /// Production configuration (strict security)
        public static let production = Configuration(
            httpsEnforcement: .strict,
            validateHostname: true
        )
    }
    
    /// Security events
    public enum SecurityEvent: Sendable {
        case sslPinningFailure(host: String, reason: String)
        case httpsViolation(url: URL)
        case certificateValidationFailure(host: String)
        case requestSigningFailure(error: Error)
        case securityPolicyViolation(description: String)
    }
    
    private let configuration: Configuration
    
    /// Initialize security manager
    /// - Parameter configuration: Security configuration
    public init(configuration: Configuration = .production) {
        self.configuration = configuration
    }
    
    /// Validate HTTPS enforcement for a URL
    /// - Parameter url: URL to validate
    /// - Throws: NetworkError if HTTPS enforcement fails
    public func validateHTTPS(for url: URL) throws {
        guard url.scheme?.lowercased() == "http" else { return }
        
        switch configuration.httpsEnforcement.level {
        case .none:
            return
            
        case .warn:
            reportSecurityEvent(.httpsViolation(url: url))
            
        case .strict:
            reportSecurityEvent(.httpsViolation(url: url))
            throw NetworkError.securityError("HTTPS required. HTTP requests are not allowed.")
            
        case .allowList(let allowedHosts):
            guard let host = url.host else {
                throw NetworkError.securityError("Invalid URL host")
            }
            
            if !allowedHosts.contains(host) {
                reportSecurityEvent(.httpsViolation(url: url))
                throw NetworkError.securityError("HTTP not allowed for host: \(host)")
            }
        }
        
        // Check custom handler
        if let httpHandler = configuration.httpsEnforcement.httpHandler {
            if !httpHandler(url) {
                reportSecurityEvent(.httpsViolation(url: url))
                throw NetworkError.securityError("HTTP request rejected by custom handler")
            }
        }
    }
    
    /// Sign a request if request signing is configured
    /// - Parameter request: HTTP request to sign
    /// - Returns: Modified request with signature
    /// - Throws: NetworkError if signing fails
    public func signRequest(_ request: HTTPRequest) throws -> HTTPRequest {
        guard let signingConfig = configuration.requestSigning else {
            return request
        }
        
        do {
            let signature = try createSignature(for: request, config: signingConfig)
            let formattedSignature = signingConfig.signatureFormatter?(signature) ?? signature.base64EncodedString()
            
            var modifiedRequest = request
            modifiedRequest.headers.add(name: signingConfig.signatureHeader, value: formattedSignature)
            
            return modifiedRequest
        } catch {
            reportSecurityEvent(.requestSigningFailure(error: error))
            throw NetworkError.securityError("Request signing failed: \(error.localizedDescription)")
        }
    }
    
    /// Validate SSL certificate for a given host
    /// - Parameters:
    ///   - trust: Security trust object
    ///   - host: Hostname being validated
    /// - Returns: Whether the certificate is valid
    public func validateCertificate(_ trust: SecTrust, for host: String) -> Bool {
        // Custom certificate validation
        if let customValidator = configuration.customCertificateValidation {
            return customValidator(trust, host)
        }
        
        // Hostname validation
        if configuration.validateHostname {
            var result = SecTrustResultType.invalid
            let status = SecTrustEvaluate(trust, &result)
            
            guard status == errSecSuccess else {
                reportSecurityEvent(.certificateValidationFailure(host: host))
                return false
            }
            
            guard result == .unspecified || result == .proceed else {
                reportSecurityEvent(.certificateValidationFailure(host: host))
                return false
            }
        }
        
        // SSL pinning validation
        if let pinningConfig = configuration.sslPinning {
            return validateSSLPinning(trust, host: host, config: pinningConfig)
        }
        
        return true
    }
    
    /// Create URL session delegate for security validation
    /// - Returns: URL session delegate
    public func createURLSessionDelegate() -> SecurityURLSessionDelegate {
        return SecurityURLSessionDelegate(securityManager: self)
    }
}

// MARK: - Private Implementation
private extension SecurityManager {
    func createSignature(for request: HTTPRequest, config: RequestSigningConfiguration) throws -> Data {
        // Create canonical request string
        var canonicalComponents: [String] = []
        
        // Add method and URL
        canonicalComponents.append(request.method.rawValue.uppercased())
        canonicalComponents.append(request.url.absoluteString)
        
        // Add specified headers
        for headerName in config.includedHeaders.sorted() {
            if let value = request.headers[headerName] {
                canonicalComponents.append("\(headerName.lowercased()):\(value)")
            }
        }
        
        // Add body if specified
        if config.includeBody, let body = request.body {
            canonicalComponents.append(body.base64EncodedString())
        }
        
        let canonicalRequest = canonicalComponents.joined(separator: "\n")
        let requestData = canonicalRequest.data(using: .utf8) ?? Data()
        
        // Sign based on algorithm
        switch config.algorithm {
        case .hmacSHA256(let key):
            return try signWithHMAC(requestData, key: key)
            
        case .ed25519(let privateKey):
            return try signWithEd25519(requestData, privateKey: privateKey)
            
        case .rsa(let privateKey):
            return try signWithRSA(requestData, privateKey: privateKey)
        }
    }
    
    func signWithHMAC(_ data: Data, key: Data) throws -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(signature)
    }
    
    func signWithEd25519(_ data: Data, privateKey: Data) throws -> Data {
        guard privateKey.count == 32 else {
            throw NetworkError.securityError("Invalid Ed25519 private key length")
        }
        
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
        let signature = try key.signature(for: data)
        return signature
    }
    
    func signWithRSA(_ data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?
        
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) else {
            let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown RSA signing error"
            throw NetworkError.securityError("RSA signing failed: \(errorDescription)")
        }
        
        return signature as Data
    }
    
    func validateSSLPinning(_ trust: SecTrust, host: String, config: SSLPinningConfiguration) -> Bool {
        // Allow debug bypass in debug builds
        #if DEBUG
        if config.allowDebugBypass {
            return true
        }
        #endif
        
        // Custom validator first
        if let customValidator = config.customValidator {
            return customValidator(trust, host)
        }
        
        switch config.policy {
        case .certificate(let pinnedCertificates):
            return validateCertificatePinning(trust, pinnedCertificates: pinnedCertificates, host: host)
            
        case .publicKey(let pinnedKeys):
            return validatePublicKeyPinning(trust, pinnedKeys: pinnedKeys, host: host)
            
        case .certificateAuthority(let pinnedCAs):
            return validateCertificateAuthorityPinning(trust, pinnedCAs: pinnedCAs, host: host)
        }
    }
    
    func validateCertificatePinning(_ trust: SecTrust, pinnedCertificates: [Data], host: String) -> Bool {
        let certificateCount = SecTrustGetCertificateCount(trust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, i) else { continue }
            
            let certificateData = SecCertificateCopyData(certificate)
            let data = CFDataGetBytePtr(certificateData)
            let length = CFDataGetLength(certificateData)
            let certificateBytes = Data(bytes: data!, count: length)
            
            if pinnedCertificates.contains(certificateBytes) {
                return true
            }
        }
        
        reportSecurityEvent(.sslPinningFailure(host: host, reason: "Certificate not in pinned set"))
        return false
    }
    
    func validatePublicKeyPinning(_ trust: SecTrust, pinnedKeys: [SecKey], host: String) -> Bool {
        let certificateCount = SecTrustGetCertificateCount(trust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, i),
                  let publicKey = SecCertificateCopyKey(certificate) else { continue }
            
            for pinnedKey in pinnedKeys {
                if CFEqual(publicKey, pinnedKey) {
                    return true
                }
            }
        }
        
        reportSecurityEvent(.sslPinningFailure(host: host, reason: "Public key not in pinned set"))
        return false
    }
    
    func validateCertificateAuthorityPinning(_ trust: SecTrust, pinnedCAs: [Data], host: String) -> Bool {
        let certificateCount = SecTrustGetCertificateCount(trust)
        
        // Check if any certificate in the chain is signed by a pinned CA
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, i) else { continue }
            
            let certificateData = SecCertificateCopyData(certificate)
            let data = CFDataGetBytePtr(certificateData)
            let length = CFDataGetLength(certificateData)
            let certificateBytes = Data(bytes: data!, count: length)
            
            if pinnedCAs.contains(certificateBytes) {
                return true
            }
        }
        
        reportSecurityEvent(.sslPinningFailure(host: host, reason: "Certificate authority not in pinned set"))
        return false
    }
    
    func reportSecurityEvent(_ event: SecurityEvent) {
        configuration.securityEventHandler?(event)
    }
}

// MARK: - URL Session Delegate
public final class SecurityURLSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    private let securityManager: SecurityManager
    
    internal init(securityManager: SecurityManager) {
        self.securityManager = securityManager
    }
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        if securityManager.validateCertificate(serverTrust, for: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Security Utilities
extension SecurityManager {
    /// Load certificate from bundle
    /// - Parameter name: Certificate filename (without extension)
    /// - Returns: Certificate data
    public static func loadCertificate(named name: String, bundle: Bundle = .main) -> Data? {
        guard let path = bundle.path(forResource: name, ofType: "cer") ?? bundle.path(forResource: name, ofType: "crt"),
              let data = NSData(contentsOfFile: path) else {
            return nil
        }
        return data as Data
    }
    
    /// Extract public key from certificate data
    /// - Parameter certificateData: Certificate data
    /// - Returns: Public key
    public static func extractPublicKey(from certificateData: Data) -> SecKey? {
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            return nil
        }
        return SecCertificateCopyKey(certificate)
    }
    
    /// Generate HMAC key
    /// - Parameter length: Key length in bytes (default: 32)
    /// - Returns: Random key data
    public static func generateHMACKey(length: Int = 32) -> Data {
        var keyData = Data(count: length)
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        return result == errSecSuccess ? keyData : Data()
    }
} 