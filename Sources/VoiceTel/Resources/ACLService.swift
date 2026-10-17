//
//  ACLService.swift
//  VoiceTel
//
//  Resource service for the ACL tag.
//

import Foundation

/// Manages the IP allowlist (CIDR entries) bound to the account.
public final class ACLService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/acl` — current allowlist.
    public func list() async throws -> AclListData {
        try await transport.request(.get, path: "/v2.2/acl", responseType: AclListData.self)
    }

    /// `POST /v2.2/acl` — append one or more CIDR entries.
    public func add(_ body: AclModifyRequest) async throws -> AclAddData {
        try await transport.request(.post, path: "/v2.2/acl", body: body, responseType: AclAddData.self)
    }

    /// `DELETE /v2.2/acl` — remove one or more CIDR entries.
    /// No request body: the entries are sent as the required `cidrs` query
    /// parameter (comma-separated). Returns a body (200) — not 204 No Content.
    public func remove(cidrs: [String]) async throws -> AclRemoveData {
        let q: [String: String?] = ["cidrs": cidrs.joined(separator: ",")]
        return try await transport.request(.delete, path: "/v2.2/acl", query: q, responseType: AclRemoveData.self)
    }
}
