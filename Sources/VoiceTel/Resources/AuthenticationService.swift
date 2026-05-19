//
//  AuthenticationService.swift
//  VoiceTel
//
//  Resource service for the Authentication tag.
//

import Foundation

/// Manages SIP/HTTP authentication settings (mode + password).
public final class AuthenticationService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/auth` — current auth mode + allowlist.
    public func get() async throws -> AuthGetData {
        try await transport.request(.get, path: "/v2.2/auth", responseType: AuthGetData.self)
    }

    /// `PUT /v2.2/auth` — set auth mode and/or password.
    public func update(_ body: AuthPutRequest) async throws -> AuthPutData {
        try await transport.request(.put, path: "/v2.2/auth", body: body, responseType: AuthPutData.self)
    }
}
