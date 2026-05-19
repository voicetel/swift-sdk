//
//  GatewaysService.swift
//  VoiceTel
//
//  Resource service for the Gateways tag.
//

import Foundation

/// Manages outbound termination gateways on the account.
public final class GatewaysService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/gateways` — every gateway on the account.
    public func list() async throws -> GatewaysListData {
        try await transport.request(.get, path: "/v2.2/gateways", responseType: GatewaysListData.self)
    }

    /// `POST /v2.2/gateways` — create a new gateway.
    public func add(_ body: GatewayAddRequest) async throws -> GatewayEntry {
        try await transport.request(.post, path: "/v2.2/gateways", body: body, responseType: GatewayEntry.self)
    }

    /// `GET /v2.2/gateways/{id}` — fetch a single gateway by id.
    public func get(id: Int) async throws -> GatewayEntry {
        try await transport.request(.get, path: "/v2.2/gateways/\(id)", responseType: GatewayEntry.self)
    }

    /// `PUT /v2.2/gateways/{id}` — partial update.
    public func update(id: Int, body: GatewayUpdateRequest) async throws -> GatewayEntry {
        try await transport.request(.put, path: "/v2.2/gateways/\(id)", body: body, responseType: GatewayEntry.self)
    }

    /// `DELETE /v2.2/gateways/{id}` — delete a gateway. Returns 204 No Content.
    public func remove(id: Int) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/gateways/\(id)")
    }

    /// `GET /v2.2/gateways/{id}/numbers` — every number routed through `id`.
    public func numbers(id: Int) async throws -> GatewayNumbersData {
        try await transport.request(.get, path: "/v2.2/gateways/\(id)/numbers", responseType: GatewayNumbersData.self)
    }
}
