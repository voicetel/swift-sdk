//
//  Lookups.swift
//  VoiceTel
//
//  Models for the Lookups resource group (CNAM + LRN dips).
//

import Foundation

/// Response for `GET /v2.2/cnam/{number}`.
public struct CnamData: Codable, Hashable, Sendable {
    public var cnam: String?
    public var number: String
}

/// LRN dip result.
///
/// Returned both as top-level data on `GET /v2.2/cnam/{number}` (when no ANI
/// is supplied) and nested inside ``LrnLookupData`` when the
/// `/lrn/{n}/{ani}` form is used.
public struct LrnData: Codable, Hashable, Sendable {
    public var lrn: String?
    public var state: String?
    public var city: String?
    /// Rate center.
    public var rc: String?
    public var lata: String?
    public var ocn: String?
    public var lec: String?
    public var lecType: String?
    public var jurisdiction: String?
    /// `Y`/`N` — local to the ANI's rate center.
    public var local: String?
}

/// Response for `GET /v2.2/lrn/{number}/{ani}`.
public struct LrnLookupData: Codable, Hashable, Sendable {
    public var ani: String
    public var destination: String
    public var lrn: LrnData
}
