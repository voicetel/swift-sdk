//
//  E911Service.swift
//  VoiceTel
//
//  Resource service for the e911 tag.
//

import Foundation

/// Manages e911 records and address validation.
///
/// **Note:** asymmetric `dn` formats — requests take a 10-digit TN; responses
/// return the 11-digit E.164 US form (country code 1 prepended).
public final class E911Service: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/e911` — every e911 record on the account.
    public func list() async throws -> E911AllData {
        try await transport.request(.get, path: "/v2.2/e911", responseType: E911AllData.self)
    }

    /// `POST /v2.2/e911` — validate + provision in one call.
    public func create(_ body: E911CreateRequest) async throws -> E911RecordData {
        try await transport.request(.post, path: "/v2.2/e911", body: body, responseType: E911RecordData.self)
    }

    /// `POST /v2.2/e911/validations` — validate an address.
    /// Returns an `addressid` for use with ``provision(dn:body:)``.
    public func validate(_ body: E911AddressRequest) async throws -> E911ValidateData {
        try await transport.request(.post, path: "/v2.2/e911/validations", body: body, responseType: E911ValidateData.self)
    }

    /// `GET /v2.2/e911/{dn}` — fetch the e911 record for `dn`.
    public func get(dn: String) async throws -> E911RecordData {
        try await transport.request(.get, path: "/v2.2/e911/\(dn)", responseType: E911RecordData.self)
    }

    /// `PUT /v2.2/e911/{dn}` — provision e911 for `dn` using a previously-validated address.
    public func provision(dn: String, body: E911ProvisionByIDRequest) async throws -> E911RecordData {
        try await transport.request(.put, path: "/v2.2/e911/\(dn)", body: body, responseType: E911RecordData.self)
    }

    /// `DELETE /v2.2/e911/{dn}` — remove the e911 record for `dn`. Returns 204 No Content.
    public func remove(dn: String) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/e911/\(dn)")
    }
}
