//
//  NumbersService.swift
//  VoiceTel
//
//  Resource service for the Numbers tag.
//

import Foundation

/// Every operation on telephone numbers owned by the account.
public final class NumbersService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/numbers` — every TN on the account.
    public func list() async throws -> NumbersListData {
        try await transport.request(.get, path: "/v2.2/numbers", responseType: NumbersListData.self)
    }

    /// `POST /v2.2/numbers` — attach a TN to the account.
    public func add(_ body: NumberAddRequest) async throws -> NumberAddData {
        try await transport.request(.post, path: "/v2.2/numbers", body: body, responseType: NumberAddData.self)
    }

    /// `GET /v2.2/numbers/{number}` — fetch one TN.
    public func get(number: String) async throws -> NumberDetail {
        try await transport.request(.get, path: "/v2.2/numbers/\(encodePathSegment(number))", responseType: NumberDetail.self)
    }

    /// `DELETE /v2.2/numbers/{number}` — detach a TN. Returns 204 No Content.
    public func remove(number: String) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/numbers/\(encodePathSegment(number))")
    }

    /// `PATCH /v2.2/numbers/{number}` — transfer a TN to another account.
    public func move(number: String, body: NumberMoveRequest) async throws -> NumberMoveData {
        try await transport.request(.patch, path: "/v2.2/numbers/\(encodePathSegment(number))", body: body, responseType: NumberMoveData.self)
    }

    /// `POST /v2.2/numbers/{number}/release` — return a TN to the network. Returns 204 No Content.
    public func release(number: String) async throws {
        try await transport.requestVoid(.post, path: "/v2.2/numbers/\(encodePathSegment(number))/release")
    }

    /// `PUT /v2.2/numbers/{number}/route` — update a TN's outbound route.
    public func setRoute(number: String, body: NumberRouteRequest) async throws -> NumberRouteData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/route", body: body, responseType: NumberRouteData.self)
    }

    /// `PUT /v2.2/numbers/{number}/translation` — update DNIS translation.
    public func setTranslation(number: String, body: NumberTranslationRequest) async throws -> NumberTranslationData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/translation", body: body, responseType: NumberTranslationData.self)
    }

    /// `PUT /v2.2/numbers/{number}/cnam` — toggle inbound CNAM lookup.
    public func setCnam(number: String, body: NumberCnamRequest) async throws -> NumberCnamData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/cnam", body: body, responseType: NumberCnamData.self)
    }

    /// `PUT /v2.2/numbers/{number}/lidb` — update outbound caller name (LIDB).
    public func setLidb(number: String, body: NumberLidbRequest) async throws -> NumberLidbData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/lidb", body: body, responseType: NumberLidbData.self)
    }

    /// `GET /v2.2/numbers/{number}/directory-listing` — 411 listing state as published.
    public func getDirectoryListing(number: String) async throws -> DirectoryListingData {
        try await transport.request(.get, path: "/v2.2/numbers/\(encodePathSegment(number))/directory-listing", responseType: DirectoryListingData.self)
    }

    /// `PUT /v2.2/numbers/{number}/directory-listing` — add or replace the 411 listing.
    ///
    /// Accepted at once and applied in the background: returns HTTP 202 with
    /// `status` == `.pending` and the carrier `orderId`.
    public func setDirectoryListing(number: String, body: DirectoryListingRequest) async throws -> DirectoryListingData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/directory-listing", body: body, responseType: DirectoryListingData.self)
    }

    /// `DELETE /v2.2/numbers/{number}/directory-listing` — remove the listing,
    /// or cancel an add not yet applied.
    ///
    /// Accepted at once and applied in the background: returns HTTP 202 with
    /// `status` == `.removing` (and the carrier `orderId`), or
    /// `status` == `.notListed` with no `orderId` when a pending add was
    /// cancelled.
    public func removeDirectoryListing(number: String) async throws -> DirectoryListingData {
        try await transport.request(.delete, path: "/v2.2/numbers/\(encodePathSegment(number))/directory-listing", responseType: DirectoryListingData.self)
    }

    /// `GET /v2.2/numbers/{number}/fax` — read fax-to-email routing.
    public func getFax(number: String) async throws -> NumberFaxData {
        try await transport.request(.get, path: "/v2.2/numbers/\(encodePathSegment(number))/fax", responseType: NumberFaxData.self)
    }

    /// `PUT /v2.2/numbers/{number}/fax` — enable fax-to-email.
    public func setFax(number: String, body: NumberFaxRequest) async throws -> NumberFaxData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/fax", body: body, responseType: NumberFaxData.self)
    }

    /// `DELETE /v2.2/numbers/{number}/fax` — disable fax-to-email. Returns 204 No Content.
    public func removeFax(number: String) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/numbers/\(encodePathSegment(number))/fax")
    }

    /// `PUT /v2.2/numbers/{number}/forward` — enable call forwarding.
    public func setForward(number: String, body: NumberForwardRequest) async throws -> NumberForwardData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/forward", body: body, responseType: NumberForwardData.self)
    }

    /// `DELETE /v2.2/numbers/{number}/forward` — disable call forwarding. Returns 204 No Content.
    public func removeForward(number: String) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/numbers/\(encodePathSegment(number))/forward")
    }

    /// `GET /v2.2/numbers/{number}/sms` — read SMS routing.
    public func getSms(number: String) async throws -> NumberSmsData {
        try await transport.request(.get, path: "/v2.2/numbers/\(encodePathSegment(number))/sms", responseType: NumberSmsData.self)
    }

    /// `PUT /v2.2/numbers/{number}/sms` — configure SMS routing.
    public func setSms(number: String, body: NumberSmsRequest) async throws -> NumberSmsData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/sms", body: body, responseType: NumberSmsData.self)
    }

    /// `DELETE /v2.2/numbers/{number}/sms` — clear SMS routing. Returns 204 No Content.
    public func removeSms(number: String) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/numbers/\(encodePathSegment(number))/sms")
    }

    /// `GET /v2.2/numbers/{number}/messaging` — messaging state for one TN.
    public func getMessaging(number: String) async throws -> NumberMessagingState {
        try await transport.request(.get, path: "/v2.2/numbers/\(encodePathSegment(number))/messaging", responseType: NumberMessagingState.self)
    }

    /// `PATCH /v2.2/numbers/{number}/messaging` — update inbound/outbound routing.
    public func patchMessaging(number: String, body: NumberMessagingPatchRequest) async throws -> NumberMessagingPatchData {
        try await transport.request(.patch, path: "/v2.2/numbers/\(encodePathSegment(number))/messaging", body: body, responseType: NumberMessagingPatchData.self)
    }

    /// `PUT /v2.2/numbers/{number}/messaging-campaign` — bind a 10DLC campaign to a TN.
    public func assignCampaign(number: String, body: NumberCampaignAssignRequest) async throws -> NumberMessagingCampaignAssignData {
        try await transport.request(.put, path: "/v2.2/numbers/\(encodePathSegment(number))/messaging-campaign", body: body, responseType: NumberMessagingCampaignAssignData.self)
    }

    /// `DELETE /v2.2/numbers/{number}/messaging-campaign` — remove the campaign binding from a TN.
    /// `campaignId` is a required query parameter. Returns a body (200), not 204.
    public func unassignCampaign(number: String, campaignId: String) async throws -> NumberMessagingCampaignUnassignData {
        let q: [String: String?] = ["campaignId": campaignId]
        return try await transport.request(.delete, path: "/v2.2/numbers/\(encodePathSegment(number))/messaging-campaign", query: q, responseType: NumberMessagingCampaignUnassignData.self)
    }

    /// `DELETE /v2.2/numbers/messaging-campaign` — remove the campaign binding from many TNs.
    /// No request body: `numbers` (max 1000) and `campaignId` are required query
    /// parameters. Returns a body (200), not 204.
    public func bulkUnassignCampaign(numbers: [String], campaignId: String) async throws -> NumbersMessagingCampaignUnassignData {
        let q: [String: String?] = [
            "numbers": numbers.joined(separator: ","),
            "campaignId": campaignId
        ]
        return try await transport.request(.delete, path: "/v2.2/numbers/messaging-campaign", query: q, responseType: NumbersMessagingCampaignUnassignData.self)
    }

    /// `PATCH /v2.2/numbers/{number}/port-out-pin` — set the port-out PIN for a TN.
    public func setPortOutPin(number: String, body: PortOutPinUpdateRequest) async throws -> PortOutPinUpdateData {
        try await transport.request(.patch, path: "/v2.2/numbers/\(encodePathSegment(number))/port-out-pin", body: body, responseType: PortOutPinUpdateData.self)
    }
}
