//
//  AccountService.swift
//  VoiceTel
//
//  Resource service for the Account tag.
//

import Foundation

/// Operations under the `Account` tag.
///
/// **Rate limit:** `cdr`, `recurringCharges`, `payments`, `registration`, and
/// ``VoiceTelClient/login(username:password:)`` share a 6 req/hour/IP cap.
public final class AccountService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/account` — authenticated account profile.
    public func get() async throws -> AccountData {
        try await transport.request(.get, path: "/v2.2/account", responseType: AccountData.self)
    }

    /// `PUT /v2.2/account` — partial update.
    public func update(_ body: AccountPutRequest) async throws -> AccountPutData {
        try await transport.request(.put, path: "/v2.2/account", body: body, responseType: AccountPutData.self)
    }

    /// `POST /v2.2/account` — admin-only sub-account creation.
    public func add(_ body: AccountAddRequest) async throws -> AccountAddData {
        try await transport.request(.post, path: "/v2.2/account", body: body, responseType: AccountAddData.self)
    }

    /// `POST /v2.2/accounts` — public self-service signup.
    public func signup(_ body: AccountSignupRequest) async throws -> AccountSignupData {
        try await transport.request(.post, path: "/v2.2/accounts", body: body, responseType: AccountSignupData.self)
    }

    /// `GET /v2.2/account/cdr` — call detail records in `[start, end]` Unix seconds.
    /// Rate-limited.
    public func cdr(start: Int? = nil, end: Int? = nil) async throws -> AccountCdrData {
        let q: [String: String?] = [
            "start": start.map(String.init),
            "end": end.map(String.init)
        ]
        return try await transport.request(.get, path: "/v2.2/account/cdr", query: q, responseType: AccountCdrData.self)
    }

    /// `GET /v2.2/account/credits` — full credit history, newest first.
    public func credits() async throws -> AccountCreditsData {
        try await transport.request(.get, path: "/v2.2/account/credits", responseType: AccountCreditsData.self)
    }

    /// `GET /v2.2/account/recurring-charges` — active monthly-recurring charges. Rate-limited.
    public func recurringCharges() async throws -> AccountMrcData {
        try await transport.request(.get, path: "/v2.2/account/recurring-charges", responseType: AccountMrcData.self)
    }

    /// `GET /v2.2/account/payments` — full payment history, newest first. Rate-limited.
    public func payments() async throws -> AccountPaymentsData {
        try await transport.request(.get, path: "/v2.2/account/payments", responseType: AccountPaymentsData.self)
    }

    /// `GET /v2.2/account/registration` — current SIP registration. Rate-limited.
    public func registration() async throws -> AccountRegistrationData {
        try await transport.request(.get, path: "/v2.2/account/registration", responseType: AccountRegistrationData.self)
    }

    /// `POST /v2.2/account/recovery` — start the password-recovery flow (no auth required).
    public func recover(_ body: AccountRecoverRequest) async throws -> AccountRecoverData {
        try await transport.request(.post, path: "/v2.2/account/recovery", body: body, requireAuth: false, responseType: AccountRecoverData.self)
    }
}
