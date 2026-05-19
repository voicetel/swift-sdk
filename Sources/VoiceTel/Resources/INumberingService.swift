//
//  INumberingService.swift
//  VoiceTel
//
//  Resource service for the iNumbering tag (inventory + orders + ports).
//

import Foundation

/// Covers inventory searches, orders, and port-ins.
public final class INumberingService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/inventory` — search available TNs.
    public func searchInventory(query q: InventoryQuery = InventoryQuery()) async throws -> InventorySearchData {
        let params: [String: String?] = [
            "npa": q.npa.map(String.init),
            "nxx": q.nxx.map(String.init),
            "state": q.state,
            "ratecenter": q.rateCenter,
            "contains": q.contains,
            "endswith": q.endsWith,
            "limit": q.limit.map(String.init)
        ]
        return try await transport.request(.get, path: "/v2.2/inventory", query: params, responseType: InventorySearchData.self)
    }

    /// `GET /v2.2/inventory/coverage` — aggregated availability buckets.
    public func coverage(query q: CoverageQuery = CoverageQuery()) async throws -> InventoryCoverageData {
        let params: [String: String?] = [
            "state": q.state,
            "ratecenter": q.rateCenter
        ]
        return try await transport.request(.get, path: "/v2.2/inventory/coverage", query: params, responseType: InventoryCoverageData.self)
    }

    /// `POST /v2.2/orders` — purchase new TNs.
    public func order(_ body: OrderCreateRequest) async throws -> OrderCreateData {
        try await transport.request(.post, path: "/v2.2/orders", body: body, responseType: OrderCreateData.self)
    }

    /// `GET /v2.2/ports` — every port-in record on the account.
    public func ports() async throws -> PortListData {
        try await transport.request(.get, path: "/v2.2/ports", responseType: PortListData.self)
    }

    /// `GET /v2.2/ports/{id}` — detail for one port-in by id.
    public func port(id: Int) async throws -> PortDetailData {
        try await transport.request(.get, path: "/v2.2/ports/\(id)", responseType: PortDetailData.self)
    }

    /// `POST /v2.2/ports` — submit a port-in order.
    public func submitPort(_ body: PortSubmitRequest) async throws -> PortSubmitData {
        try await transport.request(.post, path: "/v2.2/ports", body: body, responseType: PortSubmitData.self)
    }

    /// `GET /v2.2/ports/availability/{number}` — port-availability check.
    public func portAvailability(number: String) async throws -> PortAvailabilityData {
        try await transport.request(.get, path: "/v2.2/ports/availability/\(number)", responseType: PortAvailabilityData.self)
    }
}
