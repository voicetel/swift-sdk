//
//  VoiceTelClient.swift
//  VoiceTel
//
//  Copyright (c) 2026 VoiceTel Communications.
//  Licensed under the MIT License.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Entry point for the VoiceTel REST API.
///
/// `VoiceTelClient` is a class (not a struct) so a single instance can be
/// shared across resource services and so that ``login(username:password:)``
/// can install the freshly-issued bearer in place.
///
/// ```swift
/// let client = VoiceTelClient(apiKey: "...")
/// let me = try await client.account.get()
/// print(me.cash ?? 0)
/// ```
///
/// Or, with username + password:
///
/// ```swift
/// let client = VoiceTelClient()
/// _ = try await client.login(username: "1000000001", password: "hunter2")
/// let numbers = try await client.numbers.list()
/// ```
public final class VoiceTelClient: @unchecked Sendable {

    // MARK: - Stored

    let transport: Transport

    /// Resource service for the `Account` tag (profile, CDRs, billing, recovery, etc.).
    public private(set) lazy var account: AccountService = AccountService(transport: transport)

    /// Resource service for the `ACL` tag (IP allowlist).
    public private(set) lazy var acl: ACLService = ACLService(transport: transport)

    /// Resource service for the `Authentication` tag (auth mode, password rotation).
    public private(set) lazy var authentication: AuthenticationService = AuthenticationService(transport: transport)

    /// Resource service for the `e911` tag (emergency address provisioning).
    public private(set) lazy var e911: E911Service = E911Service(transport: transport)

    /// Resource service for the `Gateways` tag (SIP outbound trunks).
    public private(set) lazy var gateways: GatewaysService = GatewaysService(transport: transport)

    /// Resource service for the `iNumbering` tag (inventory, orders, ports).
    public private(set) lazy var iNumbering: INumberingService = INumberingService(transport: transport)

    /// Resource service for the `Lookups` tag (CNAM and LRN dips).
    public private(set) lazy var lookups: LookupsService = LookupsService(transport: transport)

    /// Resource service for the `Messaging` tag (SMS/MMS, brands, campaigns).
    public private(set) lazy var messaging: MessagingService = MessagingService(transport: transport)

    /// Resource service for the `Numbers` tag (per-TN routing & features).
    public private(set) lazy var numbers: NumbersService = NumbersService(transport: transport)

    /// Resource service for the `Support` tag (ticketing).
    public private(set) lazy var support: SupportService = SupportService(transport: transport)

    // MARK: - Construction

    /// Constructs a client.
    ///
    /// - Parameters:
    ///   - baseURL: Override the API endpoint. Defaults to ``VoiceTel/defaultBaseURL``.
    ///   - apiKey: Bearer token. Omit to use ``login(username:password:)`` later.
    ///   - session: Custom `URLSession`. Defaults to one with a 30-second timeout.
    ///   - userAgent: Override the `User-Agent` header.
    ///   - maxRetries: Retries on 429/5xx (transport will make `maxRetries + 1` attempts). Default `2`.
    public init(
        baseURL: String = VoiceTel.defaultBaseURL,
        apiKey: String? = nil,
        session: URLSession? = nil,
        userAgent: String = VoiceTel.defaultUserAgent,
        maxRetries: Int = 2
    ) {
        let resolvedSession: URLSession
        if let session = session {
            resolvedSession = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            resolvedSession = URLSession(configuration: config)
        }
        self.transport = Transport(
            baseURL: baseURL,
            apiKey: apiKey,
            session: resolvedSession,
            userAgent: userAgent,
            maxRetries: maxRetries
        )
    }

    // MARK: - Properties

    /// Currently configured API endpoint.
    public var baseURL: String { transport.configuredBaseURL }

    /// Currently installed bearer token (`nil` before ``login(username:password:)``).
    public var apiKey: String? { transport.apiKey }

    /// Replaces the bearer token used on subsequent requests.
    public func setAPIKey(_ key: String?) {
        transport.setApiKey(key)
    }

    // MARK: - Login

    /// Exchanges username + password for a 32-hex API key and installs it on this client.
    ///
    /// The exchange counts against the 6 req/hour/IP rate limit shared by every
    /// account/* endpoint (CDR, MRC, payments, registration, api-key).
    @discardableResult
    public func login(username: String, password: String) async throws -> String {
        let body = LoginRequest(username: username, password: password)
        let data: AccountApiKeyData = try await transport.request(
            .post,
            path: "/v2.2/account/api-key",
            body: body,
            requireAuth: false,
            responseType: AccountApiKeyData.self
        )
        guard !data.apiKey.isEmpty else {
            throw APIError(
                kind: .authentication,
                statusCode: 200,
                message: "api-key response did not contain data.apikey"
            )
        }
        transport.setApiKey(data.apiKey)
        return data.apiKey
    }
}

private struct LoginRequest: Encodable {
    let username: String
    let password: String
}
