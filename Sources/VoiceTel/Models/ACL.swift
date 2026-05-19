//
//  ACL.swift
//  VoiceTel
//
//  Models for the ACL resource group.
//

import Foundation

/// Body for `POST /v2.2/acl` (add) and `DELETE /v2.2/acl` (remove).
public struct AclModifyRequest: Codable, Hashable, Sendable {
    public var acl: [CidrEntry]

    public init(acl: [CidrEntry]) {
        self.acl = acl
    }
}

/// Response for `GET /v2.2/acl`.
public struct AclListData: Codable, Hashable, Sendable {
    public var acl: [CidrEntry]
}

/// Response for `POST /v2.2/acl`.
public struct AclAddData: Codable, Hashable, Sendable {
    public var added: [CidrEntry]
}

/// Response for `DELETE /v2.2/acl`.
public struct AclRemoveData: Codable, Hashable, Sendable {
    public var removed: [CidrEntry]
}

/// A CIDR that was rejected, with the reason.
///
/// `reason` is one of:
/// - `"DB Insert failed"`
/// - `"DB delete failed"`
/// - `"Invalid mask: must be /8, /16, /24, or /32"`
/// - `"CIDR range must be routable"`
public struct AclFailedEntry: Codable, Hashable, Sendable {
    public var cidr: String
    public var reason: String
}

/// Data payload included in a 409 from `POST`/`DELETE /v2.2/acl`.
///
/// Surfaces partial success: entries that succeeded alongside ones that failed.
public struct AclConflictData: Codable, Hashable, Sendable {
    public var added: [CidrEntry]?
    public var removed: [CidrEntry]?
    public var failed: [AclFailedEntry]?
}
