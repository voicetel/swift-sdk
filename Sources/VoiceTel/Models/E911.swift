//
//  E911.swift
//  VoiceTel
//
//  Models for the e911 resource group.
//
//  Note the asymmetric `dn` formats: requests take a 10-digit TN; responses
//  return the 11-digit E.164 US form (country code 1 prepended).
//

import Foundation

/// Body for `POST /v2.2/e911/validations`.
public struct E911AddressRequest: Codable, Hashable, Sendable {
    public var address1: String
    public var address2: String?
    public var city: String
    /// Two-letter US state code.
    public var state: String
    public var zip: String

    public init(
        address1: String,
        address2: String? = nil,
        city: String,
        state: String,
        zip: String
    ) {
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.zip = zip
    }
}

/// Body for `POST /v2.2/e911` (validate + provision in one call).
public struct E911CreateRequest: Codable, Hashable, Sendable {
    /// 10-digit TN owned by the authenticated account.
    public var dn: String
    public var callername: String
    public var address1: String
    public var address2: String?
    public var city: String
    public var state: String
    public var zip: String

    public init(
        dn: String,
        callername: String,
        address1: String,
        address2: String? = nil,
        city: String,
        state: String,
        zip: String
    ) {
        self.dn = dn
        self.callername = callername
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.zip = zip
    }
}

/// Body for `PUT /v2.2/e911/{dn}`.
public struct E911ProvisionByIDRequest: Codable, Hashable, Sendable {
    public var callername: String
    /// From `POST /v2.2/e911/validations`.
    public var addressid: Int

    public init(callername: String, addressid: Int) {
        self.callername = callername
        self.addressid = addressid
    }
}

/// An e911 record bound to a TN.
public struct E911Entry: Codable, Hashable, Sendable {
    /// 11-digit E.164 US form (leading `1`).
    public var dn: String
    public var callername: String
    public var address1: String
    public var address2: String?
    public var city: String
    public var state: String
    public var zip: String
}

/// Result from `POST /v2.2/e911/validations`.
public struct E911ValidatedAddress: Codable, Hashable, Sendable {
    public var addressid: Int
    public var address1: String
    public var address2: String?
    public var city: String
    public var state: String
    public var zip: String
}

/// Response for `GET /v2.2/e911`.
public struct E911AllData: Codable, Hashable, Sendable {
    public var records: [E911Entry]
}

/// Response for `GET /v2.2/e911/{dn}`, `POST /v2.2/e911`, `PUT /v2.2/e911/{dn}`.
public struct E911RecordData: Codable, Hashable, Sendable {
    public var record: E911Entry
}

/// Response for `POST /v2.2/e911/validations`.
public struct E911ValidateData: Codable, Hashable, Sendable {
    public var address: E911ValidatedAddress
}
