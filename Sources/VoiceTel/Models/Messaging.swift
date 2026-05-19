//
//  Messaging.swift
//  VoiceTel
//
//  Models for the Messaging resource group.
//

import Foundation

/// Body for `POST /v2.2/messages`.
///
/// `mediaUrls` being non-nil switches the message type to MMS and unlocks `subject`.
///
/// **Wire-field note:** the API uses `fromNumber` / `toNumber` literally — these
/// names are preserved on the wire via the property names themselves.
public struct MessageSendRequest: Codable, Hashable, Sendable {
    /// 10-digit TN on the authenticated account.
    public var fromNumber: String
    /// 10-digit destination TN.
    public var toNumber: String
    /// UTF-8 message body.
    public var text: String
    /// MMS only.
    public var subject: String?
    /// Presence makes this an MMS.
    public var mediaUrls: [String]?

    public init(
        fromNumber: String,
        toNumber: String,
        text: String,
        subject: String? = nil,
        mediaUrls: [String]? = nil
    ) {
        self.fromNumber = fromNumber
        self.toNumber = toNumber
        self.text = text
        self.subject = subject
        self.mediaUrls = mediaUrls
    }
}

/// Body for `POST /v2.2/messaging/brands`.
public struct MessagingBrandCreateRequest: Codable, Hashable, Sendable {
    /// Starts with `B`, alphanumeric.
    public var messagingBrandId: String
    public var messagingBrandName: String
    public var messagingBrandDescription: String?

    public init(
        messagingBrandId: String,
        messagingBrandName: String,
        messagingBrandDescription: String? = nil
    ) {
        self.messagingBrandId = messagingBrandId
        self.messagingBrandName = messagingBrandName
        self.messagingBrandDescription = messagingBrandDescription
    }
}

/// Body for `POST /v2.2/messaging/campaigns`.
///
/// `campaignClassName` and `campaignStartDate` are auto-populated if omitted.
public struct MessagingCampaignCreateRequest: Codable, Hashable, Sendable {
    public var messagingBrandId: String
    public var externalCampaignId: String
    public var campaignDescription: String
    public var campaignClassName: String?
    /// ISO 8601.
    public var campaignStartDate: String?

    public init(
        messagingBrandId: String,
        externalCampaignId: String,
        campaignDescription: String,
        campaignClassName: String? = nil,
        campaignStartDate: String? = nil
    ) {
        self.messagingBrandId = messagingBrandId
        self.externalCampaignId = externalCampaignId
        self.campaignDescription = campaignDescription
        self.campaignClassName = campaignClassName
        self.campaignStartDate = campaignStartDate
    }
}

/// Per-record value inside a ``MessageRecord``. Shape depends on the requested
/// message type:
/// - `sms`/`mms`: `sourceNumber`, `destinationNumber`, `direction`, `rate`, `message`
/// - `dlr`: `sourceNumber`, `destinationNumber`
public struct MessageRecordValue: Codable, Hashable, Sendable {
    public var sourceNumber: String?
    public var destinationNumber: String?
    /// `"in"` or `"out"` (sms/mms only).
    public var direction: String?
    /// Billed rate per message (string for precision).
    public var rate: String?
    /// Far-end number (sms/mms only).
    public var number: Int?
    /// Message body (sms/mms only).
    public var message: String?
}

/// One row in ``MessageHistoryData/messages``.
public struct MessageRecord: Codable, Hashable, Sendable {
    public var id: String
    public var key: [MessageKeyComponent]
    public var value: MessageRecordValue
}

/// Element of a ``MessageRecord/key`` array. The wire array mixes strings and ints.
public enum MessageKeyComponent: Codable, Hashable, Sendable {
    case string(String)
    case int(Int)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            self = .string("")
        }
    }
}

/// Response for `GET /v2.2/messages`.
public struct MessageHistoryData: Codable, Hashable, Sendable {
    public var number: String
    /// `"sms"`, `"mms"`, or `"dlr"`.
    public var type: String
    public var fromTs: Int
    public var toTs: Int
    public var messages: [MessageRecord]
}

/// Response for `POST /v2.2/messages`.
public struct MessageSendData: Codable, Hashable, Sendable {
    /// Provider transaction id.
    public var id: String
    /// `"sms"` or `"mms"`.
    public var type: String
    public var fromNumber: String
    public var toNumber: String
    /// Billed SMS segments; `1` for MMS.
    public var parts: Int
    public var subject: String?
    public var mediaUrls: [String]?
}

/// Status payload for brand registration.
public struct BrandRegistrationResult: Codable, Hashable, Sendable {
    /// HTTP status code as string; `"200"` on success.
    public var statusCode: String
    /// `"Success"` on success.
    public var status: String
}

/// Response for `POST /v2.2/messaging/brands`.
public struct MessagingBrandCreateData: Codable, Hashable, Sendable {
    public var result: BrandRegistrationResult
}

/// Status payload for campaign registration.
public struct CampaignRegistrationResult: Codable, Hashable, Sendable {
    public var statusCode: String
    public var status: String
}

/// Response for `POST /v2.2/messaging/campaigns`.
public struct MessagingCampaignCreateData: Codable, Hashable, Sendable {
    public var result: CampaignRegistrationResult
}

/// A single campaign and its currently-bound numbers.
public struct CampaignStatusItem: Codable, Hashable, Sendable {
    public var id: String
    /// CSP status: `ACTIVE`, `CAMPAIGN_DCA_COMPLETE`, etc.
    public var status: String
    public var numbers: [String]
}

/// Response for `GET /v2.2/messaging/campaigns`.
public struct MessagingCampaignStatusData: Codable, Hashable, Sendable {
    public var campaigns: [CampaignStatusItem]
}

/// Optional query filters for ``MessagingService/history(options:)``.
public struct HistoryOptions: Hashable, Sendable {
    /// 10-digit TN whose history to fetch.
    public var number: String?
    /// Unix timestamp range start.
    public var start: Int?
    /// Unix timestamp range end.
    public var end: Int?
    /// `"sms"`, `"mms"`, or `"dlr"`.
    public var type: String?

    public init(
        number: String? = nil,
        start: Int? = nil,
        end: Int? = nil,
        type: String? = nil
    ) {
        self.number = number
        self.start = start
        self.end = end
        self.type = type
    }
}
