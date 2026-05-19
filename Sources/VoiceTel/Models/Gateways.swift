//
//  Gateways.swift
//  VoiceTel
//
//  Models for the Gateways resource group.
//

import Foundation

/// Body for `POST /v2.2/gateways`.
public struct GatewayAddRequest: Codable, Hashable, Sendable {
    /// IP/hostname with optional `:port`; must be routable public IPv4.
    public var gateway: String
    /// Digits to prepend on outbound calls.
    public var prefix: String?
    /// Max concurrent calls. Default `23`, range `1..1000`.
    public var limit: Int?

    public init(gateway: String, prefix: String? = nil, limit: Int? = nil) {
        self.gateway = gateway
        self.prefix = prefix
        self.limit = limit
    }
}

/// Body for `PUT /v2.2/gateways/{id}`.
public struct GatewayUpdateRequest: Codable, Hashable, Sendable {
    public var gateway: String?
    public var prefix: String?
    public var limit: Int?

    public init(gateway: String? = nil, prefix: String? = nil, limit: Int? = nil) {
        self.gateway = gateway
        self.prefix = prefix
        self.limit = limit
    }
}

/// A single gateway row.
///
/// `limit` is optional so that "unset on system routes" (`nil`) is distinguishable
/// from `0` (which is never valid).
public struct GatewayEntry: Codable, Hashable, Sendable {
    public var id: Int?
    public var gateway: String?
    public var prefix: String?
    /// `nil` for system routes.
    public var limit: Int?
    public var system: Bool?
}

/// One number bound to a gateway (response for `GET /v2.2/gateways/{id}/numbers`).
public struct GatewayNumberSummary: Codable, Hashable, Sendable {
    public var number: String
    public var translated: String
    public var forward: Bool
    /// Nullable: `nil` when forwarding is disabled.
    public var forwardTo: String?
    public var cnam: Bool
    /// Outbound messaging carrier id; `0` = none.
    public var carrier: Int
    public var smsEnabled: Bool
    public var faxEnabled: Bool
}

/// Response for `GET /v2.2/gateways`.
public struct GatewaysListData: Codable, Hashable, Sendable {
    public var gateways: [GatewayEntry]
}

/// Response for `GET /v2.2/gateways/{id}/numbers`.
public struct GatewayNumbersData: Codable, Hashable, Sendable {
    public var numbers: [GatewayNumberSummary]
}
