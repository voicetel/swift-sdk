//
//  LookupsService.swift
//  VoiceTel
//
//  Resource service for the Lookups tag (CNAM + LRN dips).
//

import Foundation

/// Per-lookup billed services: CNAM and LRN dips.
///
/// Each call is billed — rate them per call rather than fanning out blindly.
public final class LookupsService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/cnam/{number}` — CNAM dip on a 10-digit TN.
    public func cnam(number: String) async throws -> CnamData {
        try await transport.request(.get, path: "/v2.2/cnam/\(number)", responseType: CnamData.self)
    }

    /// `GET /v2.2/lrn/{number}/{ani}` — LRN dip.
    ///
    /// `ani` is used for billing/auth — it is not echoed back in the lookup result.
    public func lrn(number: String, ani: String) async throws -> LrnLookupData {
        try await transport.request(.get, path: "/v2.2/lrn/\(number)/\(ani)", responseType: LrnLookupData.self)
    }
}
