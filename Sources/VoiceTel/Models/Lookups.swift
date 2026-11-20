//
//  Lookups.swift
//  VoiceTel
//
//  Models for the Lookups resource group (CNAM, carrier & LRN dips).
//

import Foundation

/// Response for `GET /v2.2/cnam/{number}`.
public struct CnamData: Codable, Hashable, Sendable {
    public var cnam: String?
    public var number: String
}

/// Carrier and line-type details, with the field names used by the underlying
/// carrier lookup (hence `snake_case` on the wire — preserved verbatim here).
public struct CarrierInfo: Codable, Hashable, Sendable {
    /// Carrier or network name.
    public var name: String?
    /// Line type, such as `"voip"`, `"landline"`, or `"mobile"`.
    public var type: String?
    /// Mobile country code, on mobile numbers.
    public var mobile_country_code: String?
    /// Mobile network code, on mobile numbers.
    public var mobile_network_code: String?
    /// Error code when carrier details could not be determined.
    public var error_code: Int?
}

/// Response for `GET /v2.2/carrier/{number}` — carrier & line-type lookup.
///
/// Billed per lookup at the account's CNAM rate.
public struct CarrierData: Codable, Hashable, Sendable {
    /// The number that was queried.
    public var number: String
    /// Carrier and line-type details for the number.
    public var carrier: CarrierInfo
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
