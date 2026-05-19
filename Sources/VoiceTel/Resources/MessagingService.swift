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

    /// `GET /v2.2/messages` — message history with optional filters.
    public func history(options: HistoryOptions = HistoryOptions()) async throws -> MessageHistoryData {
        let q: [String: String?] = [
            "number": options.number,
            "start": options.start.map(String.init),
            "end": options.end.map(String.init),
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

    /// `GET /v2.2/messaging/campaigns` — current 10DLC campaign statuses.
    public func campaignStatus() async throws -> MessagingCampaignStatusData {
        try await transport.request(.get, path: "/v2.2/messaging/campaigns", responseType: MessagingCampaignStatusData.self)
    }

    /// `POST /v2.2/messaging/campaigns` — register a 10DLC campaign.
    public func createCampaign(_ body: MessagingCampaignCreateRequest) async throws -> MessagingCampaignCreateData {
        try await transport.request(.post, path: "/v2.2/messaging/campaigns", body: body, responseType: MessagingCampaignCreateData.self)
    }

    /// `GET /v2.2/numbers/messaging` — messaging state for many numbers at once.
    ///
    /// Pass an empty array for "all numbers on the account".
    public func numbersState(numbers: [String] = []) async throws -> NumbersMessagingListData {
        let q: [String: String?] = [
            "numbers": numbers.isEmpty ? nil : numbers.joined(separator: ",")
        ]
        return try await transport.request(.get, path: "/v2.2/numbers/messaging", query: q, responseType: NumbersMessagingListData.self)
    }
}
