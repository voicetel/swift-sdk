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
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE. Used when adding a number.
    public var route: Int?

    public init(number: String, route: Int? = nil) {
        self.number = number
        self.route = route
    }
}

/// Body for `PUT /v2.2/numbers/{number}/route`.
public struct NumberRouteRequest: Codable, Hashable, Sendable {
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE. Set with `PUT /v2.2/numbers/{number}/route`.
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
    public var destination: String

    public init(destination: String) {
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
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route:
    /// 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML,
    /// 8 SDN, 9 MOBILE.
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

// MARK: - Directory listing (411)

/// Listing type of a ``DirectoryListing`` as published: `B` (business) or
/// `R` (residence).
public enum DirectoryListingType: String, Codable, Hashable, Sendable {
    /// Business — the name travels in ``DirectoryListing/name``.
    case business = "B"
    /// Residence — the name travels in `firstName` / `lastName`.
    case residence = "R"
}

/// Listing type for ``DirectoryListingRequest``: `business` or `residence`.
/// (The server also accepts the shorthand `B` / `R`.)
public enum DirectoryListingRequestType: String, Codable, Hashable, Sendable {
    case business
    case residence
}

/// Listing status of a ``DirectoryListingData``.
public enum DirectoryListingStatus: String, Codable, Hashable, Sendable {
    /// Published.
    case listed
    /// None.
    case notListed = "not_listed"
    /// An add or change is being applied.
    case pending
    /// A removal is being applied.
    case removing
    /// The number cannot be listed.
    case unavailable
}

/// A 411 directory listing as published (or, on PUT, as submitted).
///
/// `type` `B` carries the business name in ``name``; `R` carries
/// `firstName` / `lastName`. All address fields may be empty strings.
/// `complex` marks a multi-line listing, which is read-only through the API.
public struct DirectoryListing: Codable, Hashable, Sendable {
    /// `B` (business) or `R` (residence).
    public var type: DirectoryListingType
    /// Business name (type `B`).
    public var name: String?
    /// Resident's first name (type `R`).
    public var firstName: String?
    /// Resident's last name (type `R`).
    public var lastName: String?
    /// Street number.
    public var streetNumber: String?
    /// Street name.
    public var streetName: String?
    /// Street type, e.g. `St`, `Ave`.
    public var streetType: String?
    /// Street direction: `N`, `S`, `E`, `W`, `NE`, `NW`, `SE` or `SW`.
    public var streetSuffix: String?
    /// Suite or unit.
    public var location: String?
    /// City.
    public var city: String?
    /// Two-letter US state or territory code.
    public var state: String?
    /// 5-digit ZIP.
    public var zip: String?
    /// `true` for a multi-line listing; read-only through the API.
    public var complex: Bool?
}

/// Body for `PUT /v2.2/numbers/{number}/directory-listing` — add or replace
/// the listing.
///
/// A business sets ``name``; a residence sets `firstName` and `lastName`.
/// The street is optional — give `streetNumber` and `streetName` together, or
/// neither. `city`, `state` and `zip` are required.
public struct DirectoryListingRequest: Codable, Hashable, Sendable {
    /// `business` or `residence`.
    public var type: DirectoryListingRequestType
    /// Business name; required for business. Letters, numbers, spaces and
    /// `& ' . , # / -`; at most 60 characters.
    public var name: String?
    /// Resident's first name; required for residence. At most 30 characters.
    public var firstName: String?
    /// Resident's last name; required for residence. At most 30 characters.
    public var lastName: String?
    /// Up to 10 letters or digits; give it together with `streetName`, or neither.
    public var streetNumber: String?
    /// Street name; give it together with `streetNumber`, or neither. At most
    /// 40 characters.
    public var streetName: String?
    /// A word such as `St`, `Ave` or `Rd`. At most 10 characters.
    public var streetType: String?
    /// Street direction (`""`, `N`, `S`, `E`, `W`, `NE`, `NW`, `SE`, `SW`);
    /// requires a street name.
    public var streetSuffix: String?
    /// Suite or unit; requires a street name. At most 30 characters.
    public var location: String?
    /// City the listing is at. Required.
    public var city: String
    /// Two-letter US state or territory code. Required.
    public var state: String
    /// 5-digit ZIP (a ZIP+4 is accepted and stored as the 5-digit ZIP). Required.
    public var zip: String

    public init(
        type: DirectoryListingRequestType,
        name: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        streetNumber: String? = nil,
        streetName: String? = nil,
        streetType: String? = nil,
        streetSuffix: String? = nil,
        location: String? = nil,
        city: String,
        state: String,
        zip: String
    ) {
        self.type = type
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.streetNumber = streetNumber
        self.streetName = streetName
        self.streetType = streetType
        self.streetSuffix = streetSuffix
        self.location = location
        self.city = city
        self.state = state
        self.zip = zip
    }
}

/// Response for `GET`/`PUT`/`DELETE /v2.2/numbers/{number}/directory-listing`.
///
/// PUT and DELETE are accepted (202) and applied in the background: `status`
/// is `pending` / `removing` (or `notListed` when a pending add was
/// cancelled) and `orderId` carries the carrier order reference. GET reports
/// the state as published, with `eligible` telling whether a listing can be
/// added.
public struct DirectoryListingData: Codable, Hashable, Sendable {
    public var number: String
    /// `listed`: published. `notListed`: none. `pending`: an add or change is
    /// being applied. `removing`: a removal is being applied. `unavailable`:
    /// the number cannot be listed.
    public var status: DirectoryListingStatus
    /// Whether a listing can be added to this number (GET).
    public var eligible: Bool?
    /// The published listing, or `nil`.
    public var listing: DirectoryListing?
    /// A submitted listing not yet published, or `nil`.
    public var pending: DirectoryListing?
    /// Reference of the submitted change (PUT and DELETE), or `nil`.
    public var orderId: String?
}


// MARK: - Responses

/// Per-number routing/feature state returned by `GET /v2.2/numbers` and
/// `GET /v2.2/numbers/{number}`.
public struct NumberDetail: Codable, Hashable, Sendable {
    public var number: String
    public var translated: String
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE. Per-number route in the list.
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

/// Enablement-job state. One of `"queued"`, `"hosting"`, `"assigning"`,
/// `"routing"`, `"done"`, or `"failed"`.
public typealias MessagingEnablementJobState = String

/// State of an asynchronous (path C) enablement.
///
/// Attached to a campaign assignment (status `"pending"`) or surfaced by
/// `GET /v2.2/numbers/{number}/messaging` while provisioning is in flight.
public struct MessagingEnablementJob: Codable, Hashable, Sendable {
    public var campaignId: String
    /// `queued -> hosting -> assigning -> routing -> done`, or `failed`
    /// (see ``message``). The number keeps its previous routing until done.
    public var state: MessagingEnablementJobState
    /// Latest progress note, or the reason for failure.
    public var message: String
    /// ISO 8601 timestamp the job was created.
    public var createdAt: String
    /// ISO 8601 timestamp of the latest progress update.
    public var updatedAt: String
}

/// Messaging-routing state for one number.
public struct NumberMessagingState: Codable, Hashable, Sendable {
    public var number: String
    public var onAccount: Bool?
    public var enabled: Bool
    public var carrier: Int
    public var routeIn: Int
    public var resource: String
    /// `"A"`, `"B"`, `"C"`, or `nil`.
    public var network: String?
    public var campaign: CampaignBinding?
    /// Async path-C enablement in progress for this number; `nil` when none.
    public var pending: MessagingEnablementJob?
}

/// Response for `POST /v2.2/numbers`.
public struct NumberAddData: Codable, Hashable, Sendable {
    public var number: String
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE. Returned after adding a number.
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
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE. Route on the destination account after the move.
    public var route: Int
}

/// Response for `PUT /v2.2/numbers/{number}/route`.
public struct NumberRouteData: Codable, Hashable, Sendable {
    public var number: String
    /// A gateway id on this account (`GET /v2.2/gateways`) or a global route: 1 USER, 2 T30, 3 VOICE_BRIDGE, 4 DID (default), 5 T38, 6 VOICEML, 8 SDN, 9 MOBILE. Echo of the applied route.
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
///
/// Result of binding a single number to a 10DLC campaign: status `"enabled"`
/// (path B, bound synchronously), `"already"` (the number was already bound to
/// this campaign — idempotent no-op), or `"pending"` (path C, provisioned
/// asynchronously — poll `GET /v2.2/numbers/{number}/messaging` (`pending`)
/// until the job's state is `done` or `failed`).
public struct NumberMessagingCampaignAssignData: Codable, Hashable, Sendable {
    public var number: String
    public var campaignId: String
    /// `"enabled"`, `"already"`, or `"pending"`.
    public var status: String
    /// `19` = path B, `1` = path C. For a pending path-C enablement the
    /// number keeps its current routing until provisioning completes.
    public var carrier: Int
    /// `"B"`, `"C"`, or `nil`.
    public var network: String?
    /// `CAMP003` = path B, `BANDW` = path C.
    public var upstreamCnpId: String?
    /// `"A"`, `"B"`, or `nil`.
    public var previousNetwork: String?
    /// `true` if a prior binding was disabled.
    public var previousNetworkCleared: Bool
    /// `true` when the number was already bound to this campaign on the
    /// target messaging path; records are reconciled and no new network
    /// order is placed.
    public var alreadyAssigned: Bool
    /// Network order id created for a path-B assignment; string or integer
    /// on the wire. `nil` for path C (see ``job``), idempotent no-ops, and
    /// assignments confirmed without a new order.
    public var orderId: JSONValue?
    /// Non-fatal condition detected during the assignment (for example a
    /// stale registration on the other messaging path whose removal has
    /// been requested).
    public var warning: String?
    /// Human-readable note for a pending enablement.
    public var message: String?
    /// Async path-C enablement job; `nil` unless status is `"pending"`.
    public var job: MessagingEnablementJob?
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
///
/// The call is idempotent: a PIN is locked for 30 days once set, so a number
/// that already has one returns it unchanged with `changed == false`.
public struct PortOutPinUpdateData: Codable, Hashable, Sendable {
    /// Ten-digit telephone number whose PIN is reported.
    public var number: String
    /// The port-out PIN now on file for this number (the value just set, or
    /// the existing value if the number was already locked).
    public var portOutPin: String
    /// `true` if this request set the PIN; `false` if the number already had
    /// one, which is locked for 30 days once set and is returned unchanged.
    public var changed: Bool
}
