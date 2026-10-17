//
//  MessagingService.swift
//  VoiceTel
//
//  Resource service for the Messaging tag.
//

import Foundation

/// SMS/MMS sending plus 10DLC brand & campaign registration.
public final class MessagingService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/messages` — message history for a number. `options.number` is required.
    public func history(options: HistoryOptions) async throws -> MessageHistoryData {
        let q: [String: String?] = [
            "number": options.number,
            "from": options.from.map(String.init),
            "to": options.to.map(String.init),
            "type": options.type
        ]
        return try await transport.request(.get, path: "/v2.2/messages", query: q, responseType: MessageHistoryData.self)
    }

    /// `POST /v2.2/messages` — send an SMS or MMS.
    public func send(_ body: MessageSendRequest) async throws -> MessageSendData {
        try await transport.request(.post, path: "/v2.2/messages", body: body, responseType: MessageSendData.self)
    }

    /// `POST /v2.2/messaging/brands` — register a 10DLC brand.
    public func createBrand(_ body: MessagingBrandCreateRequest) async throws -> MessagingBrandCreateData {
        try await transport.request(.post, path: "/v2.2/messaging/brands", body: body, responseType: MessagingBrandCreateData.self)
    }

    /// `GET /v2.2/messaging/campaigns` — current 10DLC campaign statuses for the
    /// given campaign ids (comma-separated on the wire, max 100). Required.
    public func campaignStatus(ids: [String]) async throws -> MessagingCampaignStatusData {
        let q: [String: String?] = [
            "ids": ids.joined(separator: ",")
        ]
        return try await transport.request(.get, path: "/v2.2/messaging/campaigns", query: q, responseType: MessagingCampaignStatusData.self)
    }

    /// `POST /v2.2/messaging/campaigns` — register a 10DLC campaign.
    public func createCampaign(_ body: MessagingCampaignCreateRequest) async throws -> MessagingCampaignCreateData {
        try await transport.request(.post, path: "/v2.2/messaging/campaigns", body: body, responseType: MessagingCampaignCreateData.self)
    }

    /// `GET /v2.2/numbers/messaging` — messaging state for the given numbers.
    ///
    /// The `numbers` query parameter is required by the API (comma-separated on
    /// the wire, max 1000).
    public func numbersState(numbers: [String]) async throws -> NumbersMessagingListData {
        let q: [String: String?] = [
            "numbers": numbers.joined(separator: ",")
        ]
        return try await transport.request(.get, path: "/v2.2/numbers/messaging", query: q, responseType: NumbersMessagingListData.self)
    }

    /// `GET /v2.2/messaging/health` — account-wide messaging health overview.
    ///
    /// Mirrors the portal Messaging tab: summary counts (numbers, messaging on,
    /// healthy, needing attention, in progress), campaigns with carrier-review
    /// progress, numbers needing attention (each with a plain-language title, detail
    /// and the actions that fix it), 14 days of delivery counts, and the alert-email
    /// setting. Updated hourly.
    ///
    /// The API spec defines no response schema for this endpoint, so the decoded JSON
    /// is returned as a loosely-typed ``JSONValue``.
    public func health() async throws -> JSONValue {
        try await transport.request(.get, path: "/v2.2/messaging/health", responseType: JSONValue.self)
    }

    /// `GET /v2.2/messaging/health/alerts` — the alert-email setting: whether new
    /// messaging problems are emailed to the account.
    ///
    /// The spec defines no response schema, so the decoded JSON is returned as a
    /// loosely-typed ``JSONValue``.
    public func healthAlerts() async throws -> JSONValue {
        try await transport.request(.get, path: "/v2.2/messaging/health/alerts", responseType: JSONValue.self)
    }

    /// `PUT /v2.2/messaging/health/alerts` — turn alert emails on or off.
    ///
    /// When enabled, the account is emailed as new messaging problems are found (at
    /// most one digest about every 20 hours). The spec defines no response schema, so
    /// the decoded JSON is returned as a loosely-typed ``JSONValue``.
    public func setHealthAlerts(enabled: Bool) async throws -> JSONValue {
        try await transport.request(.put, path: "/v2.2/messaging/health/alerts", body: ["enabled": enabled], responseType: JSONValue.self)
    }

    /// `POST /v2.2/messaging/health/check` — live health check of one number.
    ///
    /// Reports in service, messaging enabled, campaign approved, assigned to the
    /// campaign by the messaging provider, delivery failures in the last 24 hours, and
    /// enablement in progress. Limited to 30 checks per hour per account. The spec
    /// defines no response schema, so the decoded JSON is returned as a loosely-typed
    /// ``JSONValue``.
    public func healthCheck(number: String) async throws -> JSONValue {
        try await transport.request(.post, path: "/v2.2/messaging/health/check", body: ["number": number], responseType: JSONValue.self)
    }

    /// `GET /v2.2/messaging/health/samples` — recent messages blocked as spam.
    ///
    /// Up to 3 recent outbound messages from the number that carriers blocked as spam
    /// (time, masked recipient, text, reason), to help review content. The spec defines
    /// no response schema, so the decoded JSON is returned as a loosely-typed
    /// ``JSONValue``.
    public func healthSamples(number: String) async throws -> JSONValue {
        let q: [String: String?] = ["number": number]
        return try await transport.request(.get, path: "/v2.2/messaging/health/samples", query: q, responseType: JSONValue.self)
    }
}
