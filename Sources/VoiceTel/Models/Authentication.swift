//
//  Authentication.swift
//  VoiceTel
//
//  Models for the Authentication resource group.
//

import Foundation

/// SIP/HTTP authentication-mode constants for ``AuthPutRequest/authType`` and
/// ``AuthGetData/authType``:
///
/// - `0` = Digest
/// - `1` = IP Auth
/// - `2` = Digest OR IP
/// - `3` = Digest AND IP
public enum AuthType {
    public static let digest = 0
    public static let ipAuth = 1
    public static let digestOrIP = 2
    public static let digestAndIP = 3
}

/// Body for `PUT /v2.2/auth`. Optional fields are `nil` to leave unchanged.
public struct AuthPutRequest: Codable, Hashable, Sendable {
    public var authType: Int?
    /// 6-10 alphanumeric chars; at least one letter and one number.
    public var password: String?

    public init(authType: Int? = nil, password: String? = nil) {
        self.authType = authType
        self.password = password
    }
}

/// Response for `GET /v2.2/auth`.
public struct AuthGetData: Codable, Hashable, Sendable {
    public var authType: Int
    public var authTypeDescription: String
    public var acl: [CidrEntry]
}

/// One field's change in an `AuthPutData.updated` row.
public struct AuthUpdatedEntry: Codable, Hashable, Sendable {
    /// `"authType"` or `"password"`.
    public var field: String
    /// Present when echoing is safe (`authType`); omitted for `password`.
    public var value: Int?
}

/// Response for `PUT /v2.2/auth`.
public struct AuthPutData: Codable, Hashable, Sendable {
    public var updated: [AuthUpdatedEntry]
}

/// Data payload returned in a 409 from `PUT /v2.2/auth`.
public struct AuthPutConflictData: Codable, Hashable, Sendable {
    public var updated: [AuthUpdatedEntry]?
}
