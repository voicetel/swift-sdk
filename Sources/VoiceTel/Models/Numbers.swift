//
//  Numbers.swift
//  VoiceTel
//
//  Models for the Numbers resource group.
//

import Foundation

// MARK: - Requests

/// Body for `POST /v2.2/numbers`.
public struct NumberAddRequest: Codable, Hashable, Sendable {
    public var number: String
    /// Gateway route ID; defaults to `4` (DID).
    public var route: Int?

    public init(number: String, route: Int? = nil) {
        self.number = number
        self.route = route
    }
}

/// Body for `PUT /v2.2/numbers/{number}/route`.
public struct NumberRouteRequest: Codable, Hashable, Sendable {
    public var route: Int

    public init(route: Int) {
        self.route = route
    }
}

/// Body for `PUT /v2.2/numbers/{number}/cnam`.
public struct NumberCnamRequest: Codable, Hashable, Sendable {
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
}

/// Body for `PUT /v2.2/numbers/{number}/lidb`.
public struct NumberLidbRequest: Codable, Hashable, Sendable {
    /// Outbound caller name; max 15 alphanumeric chars.
    public var cnam: String
    public var customerOrderReference: String?

    public init(cnam: String, customerOrderReference: String? = nil) {
        self.cnam = cnam
        self.customerOrderReference = customerOrderReference
    }
}

/// Body for `PUT /v2.2/numbers/{number}/fax`.
public struct NumberFaxRequest: Codable, Hashable, Sendable {
    public var email: String

    public init(email: String) {
        self.email = email
    }
}

/// Body for `PUT /v2.2/numbers/{number}/forward`.
public struct NumberForwardRequest: Codable, Hashable, Sendable {
    /// 10-digit destination number.
    public var destination: Int

    public init(destination: Int) {
        self.destination = destination
    }
}

/// Body for `PUT /v2.2/numbers/{number}/translation`.
public struct NumberTranslationRequest: Codable, Hashable, Sendable {
    /// Digits and `#` only.
    public var translation: String

    public init(translation: String) {
        self.translation = translation
    }
}

/// Body for `PUT /v2.2/numbers/{number}/sms`.
public struct NumberSmsRequest: Codable, Hashable, Sendable {
    /// `"email"`, `"webhook"`, or `"sip"`.
    public var type: String
    /// Email / webhook URL / IP per ``type``.
    public var resource: String

    public init(type: String, resource: String) {
        self.type = type
        self.resource = resource
    }
}

/// Body for `PATCH /v2.2/numbers/{number}/messaging`.
///
/// At least one of `routeIn` or `routeOut` must be set.
public struct NumberMessagingPatchRequest: Codable, Hashable, Sendable {
    /// numbers_sms row id; `0` to detach.
    public var routeIn: Int?
    /// Outbound carrier id.
    public var routeOut: Int?

    public init(routeIn: Int? = nil, routeOut: Int? = nil) {
        self.routeIn = routeIn
        self.routeOut = routeOut
    }
}

/// Body for `PUT /v2.2/numbers/{number}/messaging-campaign`.
public struct NumberCampaignAssignRequest: Codable, Hashable, Sendable {
    /// 7-character TCR campaign id, alphanumeric uppercase.
    public var campaignId: String

    public init(campaignId: String) {
        self.campaignId = campaignId
    }
}

/// Body for `PATCH /v2.2/numbers/{number}`.
public struct NumberMoveRequest: Codable, Hashable, Sendable {
    /// Destination account id.
    public var accountId: Int
    public var route: Int

    public init(accountId: Int, route: Int) {
        self.accountId = accountId
        self.route = route
    }
}

/// Body for `PATCH /v2.2/numbers/{number}/port-out-pin`.
public struct PortOutPinUpdateRequest: Codable, Hashable, Sendable {
    /// 4-digit numeric.
    public var pin: String

    public init(pin: String) {
        self.pin = pin
    }
}

/// Body for `DELETE /v2.2/numbers/messaging-campaign`.
public struct BulkUnassignRequest: Codable, Hashable, Sendable {
    public var numbers: [String]

    public init(numbers: [String]) {
        self.numbers = numbers
    }
}

// MARK: - Responses

/// Per-number routing/feature state returned by `GET /v2.2/numbers` and
/// `GET /v2.2/numbers/{number}`.
public struct NumberDetail: Codable, Hashable, Sendable {
    public var number: String
    public var translated: String
    public var route: Int
    public var gateway: String?
    public var cnam: Bool
    public var forward: Bool
    public var forwardTo: String?
    public var carrier: Int
    public var smsEnabled: Bool
    public var faxEnabled: Bool
}

/// Currently-bound campaign on a number, with CSP status.
public struct CampaignBinding: Codable, Hashable, Sendable {
    public var id: String
    /// `"A"` or `"B"`.
    public var network: String
    /// `ACTIVE`, `EXPIRED`, `SUSPENDED`, …
    public var status: String
    public var upstreamCnpId: String
}

/// Messaging-routing state for one number.
public struct NumberMessagingState: Codable, Hashable, Sendable {
    public var number: String
    public var onAccount: Bool?
    public var enabled: Bool
    public var carrier: Int
    public var routeIn: Int
    public var resource: String
    /// `"A"`, `"B"`, or `nil`.
    public var network: String?
    public var campaign: CampaignBinding?
}

/// Response for `POST /v2.2/numbers`.
public struct NumberAddData: Codable, Hashable, Sendable {
    public var number: String
    public var route: Int
}

/// Response for `PUT /v2.2/numbers/{number}/cnam`.
public struct NumberCnamData: Codable, Hashable, Sendable {
    public var number: String
    public var cnam: Bool
}

/// Response for `GET`/`PUT /v2.2/numbers/{number}/fax`.
public struct NumberFaxData: Codable, Hashable, Sendable {
    public var number: String
    public var email: String
}

/// Response for `PUT /v2.2/numbers/{number}/forward`.
public struct NumberForwardData: Codable, Hashable, Sendable {
    public var number: String
    /// 10-digit TN, or `nil` when disabled.
    public var forwardTo: String?
}

/// Response for `PUT /v2.2/numbers/{number}/lidb`.
public struct NumberLidbData: Codable, Hashable, Sendable {
    public var number: String
    /// Sanitised caller name (max 15).
    public var cnam: String
    /// Echoed or auto-generated.
    public var customerOrderReference: String
    /// `"Success"` or failure detail.
    public var carrierStatus: String
}

/// Response for `PATCH /v2.2/numbers/{number}/messaging`.
public struct NumberMessagingPatchData: Codable, Hashable, Sendable {
    public var number: String
    /// Subset of `{"routeIn", "routeOut"}`.
    public var updated: [String]
}

/// Response for `PATCH /v2.2/numbers/{number}`.
public struct NumberMoveData: Codable, Hashable, Sendable {
    public var number: String
    public var accountId: Int
    public var route: Int
}

/// Response for `PUT /v2.2/numbers/{number}/route`.
public struct NumberRouteData: Codable, Hashable, Sendable {
    public var number: String
    public var route: Int
}

/// Response for `GET`/`PUT /v2.2/numbers/{number}/sms`.
public struct NumberSmsData: Codable, Hashable, Sendable {
    public var number: String
    /// `"email"`, `"webhook"`, `"sip"`, or `"unknown"`.
    public var type: String
    public var resource: String
}

/// Response for `PUT /v2.2/numbers/{number}/translation`.
public struct NumberTranslationData: Codable, Hashable, Sendable {
    public var number: String
    public var translation: String
}

/// Response for `PUT /v2.2/numbers/{number}/messaging-campaign`.
public struct NumberMessagingCampaignAssignData: Codable, Hashable, Sendable {
    public var number: String
    public var campaignId: String
    /// `17` = path A, `19` = path B.
    public var carrier: Int
    /// `"A"`, `"B"`, or `nil`.
    public var network: String?
    /// `SFL9UTQ` = path A, `SB8TWLO` = path B.
    public var upstreamCnpId: String?
    /// `"A"`, `"B"`, `"unknown"`, or `nil`.
    public var previousNetwork: String?
    /// `true` if a prior binding was disabled.
    public var previousNetworkCleared: Bool
}

/// Response for `DELETE /v2.2/numbers/{number}/messaging-campaign`.
public struct NumberMessagingCampaignUnassignData: Codable, Hashable, Sendable {
    public var number: String
    public var campaignId: String
    public var network: String?
    public var upstreamCnpId: String?
    /// Always `true` on 200.
    public var unassigned: Bool
}

/// One row in ``NumbersMessagingCampaignUnassignData/failed``.
public struct CampaignUnassignFailure: Codable, Hashable, Sendable {
    public var number: String
    public var reason: String
}

/// Response for `DELETE /v2.2/numbers/messaging-campaign` (bulk unassign).
public struct NumbersMessagingCampaignUnassignData: Codable, Hashable, Sendable {
    public var campaignId: String
    public var network: String?
    public var upstreamCnpId: String?
    public var unassignedNumbers: [String]
    public var failed: [CampaignUnassignFailure]?
}

/// Response for `GET /v2.2/numbers`.
public struct NumbersListData: Codable, Hashable, Sendable {
    public var numbers: [NumberDetail]
}

/// Response for `GET /v2.2/numbers/messaging`.
public struct NumbersMessagingListData: Codable, Hashable, Sendable {
    public var numbers: [NumberMessagingState]
}

/// Response for `PATCH /v2.2/numbers/{number}/port-out-pin`.
public struct PortOutPinUpdateData: Codable, Hashable, Sendable {
    public var number: String
    public var portOutPin: String
}
