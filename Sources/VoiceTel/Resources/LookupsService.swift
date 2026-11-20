//
//  LookupsService.swift
//  VoiceTel
//
//  Resource service for the Lookups tag (CNAM, carrier & LRN dips).
//

import Foundation

/// Per-lookup billed services: CNAM, carrier & line type, and LRN dips.
///
/// Each call is billed — rate them per call rather than fanning out blindly.
public final class LookupsService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/cnam/{number}` — CNAM dip on a 10-digit TN.
    public func cnam(number: String) async throws -> CnamData {
        try await transport.request(.get, path: "/v2.2/cnam/\(encodePathSegment(number))", responseType: CnamData.self)
    }

    /// `GET /v2.2/carrier/{number}` — carrier & line-type lookup.
    ///
    /// Carrier details come back with the upstream carrier's own field names
    /// (`mobile_country_code`, `mobile_network_code`, `error_code`). Billed
    /// per lookup at the account's CNAM rate.
    public func carrier(number: String) async throws -> CarrierData {
        try await transport.request(.get, path: "/v2.2/carrier/\(encodePathSegment(number))", responseType: CarrierData.self)
    }

    /// `GET /v2.2/lrn/{number}/{ani}` — LRN dip.
    ///
    /// `ani` is used for billing/auth — it is not echoed back in the lookup result.
    public func lrn(number: String, ani: String) async throws -> LrnLookupData {
        try await transport.request(.get, path: "/v2.2/lrn/\(encodePathSegment(number))/\(encodePathSegment(ani))", responseType: LrnLookupData.self)
    }
}
