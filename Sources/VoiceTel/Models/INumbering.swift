//
//  INumbering.swift
//  VoiceTel
//
//  Models for the iNumbering resource group (inventory + orders + ports).
//

import Foundation

/// One TN entry inside an ``OrderCreateRequest``.
///
/// May be a plain TN string (set ``value``) or a `{number, route}` object
/// (set ``spec``). Exactly one of the two should be set; `encode(to:)`
/// enforces this.
public struct OrderNumber: Codable, Hashable, Sendable {
    public var value: String?
    public var spec: OrderNumberSpec?

    public init(value: String) {
        self.value = value
        self.spec = nil
    }

    public init(spec: OrderNumberSpec) {
        self.value = nil
        self.spec = spec
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let spec = spec {
            try container.encode(spec)
        } else if let value = value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self.value = str
            self.spec = nil
        } else if let spec = try? container.decode(OrderNumberSpec.self) {
            self.spec = spec
            self.value = nil
        } else {
            self.value = nil
            self.spec = nil
        }
    }
}

/// `{number, route}` object form for ``OrderNumber``.
public struct OrderNumberSpec: Codable, Hashable, Sendable {
    public var number: String
    public var route: Int?

    public init(number: String, route: Int? = nil) {
        self.number = number
        self.route = route
    }
}

/// Body for `POST /v2.2/orders`.
///
/// `numbers` may contain 1..100 entries, each a plain TN string or a
/// `{number, route}` object.
public struct OrderCreateRequest: Codable, Hashable, Sendable {
    public var numbers: [OrderNumber]

    public init(numbers: [OrderNumber]) {
        self.numbers = numbers
    }
}

/// LIDB feature for a port-in TN.
public struct PortFeatureLidb: Codable, Hashable, Sendable {
    /// Outbound caller name; max 15 chars.
    public var name: String

    public init(name: String) {
        self.name = name
    }
}

/// Routing feature for a port-in TN.
public struct PortFeatureRouting: Codable, Hashable, Sendable {
    public var gatewayId: Int

    public init(gatewayId: Int) {
        self.gatewayId = gatewayId
    }
}

/// SMS feature for a port-in TN.
public struct PortFeatureSms: Codable, Hashable, Sendable {
    public var campaignId: String?

    public init(campaignId: String? = nil) {
        self.campaignId = campaignId
    }
}

/// Per-TN feature configuration applied after the port completes.
public struct PortFeature: Codable, Hashable, Sendable {
    public var number: String
    public var routing: PortFeatureRouting?
    public var lidb: PortFeatureLidb?
    public var sms: PortFeatureSms?

    public init(
        number: String,
        routing: PortFeatureRouting? = nil,
        lidb: PortFeatureLidb? = nil,
        sms: PortFeatureSms? = nil
    ) {
        self.number = number
        self.routing = routing
        self.lidb = lidb
        self.sms = sms
    }
}

/// Body for `POST /v2.2/ports`.
///
/// `streetPrefix` / `streetSuffix` are one of `"N"`, `"NE"`, `"E"`, `"SE"`,
/// `"S"`, `"SW"`, `"W"`, `"NW"`.
public struct PortSubmitRequest: Codable, Hashable, Sendable {
    /// 10-digit TNs (toll-free not supported).
    public var did: [String]
    /// Exactly as on losing carrier bill.
    public var name: String
    /// `"business"` or `"residential"`.
    public var nameType: String
    /// Billing TN on losing carrier bill.
    public var lcBtn: String
    /// Account number on bill.
    public var lcAccountNumber: String
    public var streetNumber: String
    public var street: String
    /// USPS abbreviation: `ST`, `AVE`, `BLVD`, …
    public var streetType: String
    public var city: String
    /// Two-letter US state code.
    public var state: String
    public var zip: String
    public var country: String
    /// Full name authorised to sign LOA.
    public var authPerson: String
    public var streetPrefix: String?
    public var streetSuffix: String?
    public var floor: String?
    public var room: String?
    public var building: String?
    /// Unit designator like `"APT 3"` or `"STE 200"`.
    public var unitValue: String?
    /// ISO 8601; blank = standard SLA.
    public var desiredDueDate: String?
    /// Port-out PIN from losing carrier.
    public var pin: String?
    public var features: [PortFeature]?

    public init(
        did: [String],
        name: String,
        nameType: String,
        lcBtn: String,
        lcAccountNumber: String,
        streetNumber: String,
        street: String,
        streetType: String,
        city: String,
        state: String,
        zip: String,
        country: String,
        authPerson: String,
        streetPrefix: String? = nil,
        streetSuffix: String? = nil,
        floor: String? = nil,
        room: String? = nil,
        building: String? = nil,
        unitValue: String? = nil,
        desiredDueDate: String? = nil,
        pin: String? = nil,
        features: [PortFeature]? = nil
    ) {
        self.did = did
        self.name = name
        self.nameType = nameType
        self.lcBtn = lcBtn
        self.lcAccountNumber = lcAccountNumber
        self.streetNumber = streetNumber
        self.street = street
        self.streetType = streetType
        self.city = city
        self.state = state
        self.zip = zip
        self.country = country
        self.authPerson = authPerson
        self.streetPrefix = streetPrefix
        self.streetSuffix = streetSuffix
        self.floor = floor
        self.room = room
        self.building = building
        self.unitValue = unitValue
        self.desiredDueDate = desiredDueDate
        self.pin = pin
        self.features = features
    }
}

/// One TN available for assignment.
public struct InventoryItem: Codable, Hashable, Sendable {
    public var number: String
    public var rateCenter: String
    public var city: String
    /// Two-letter state/province.
    public var province: String
    public var lata: String
}

/// One aggregated availability bucket.
///
/// Which fields are populated depends on the `countBy` dimension on the query.
public struct InventoryCoverageItem: Codable, Hashable, Sendable {
    public var count: Int
    public var npa: String?
    public var nxx: String?
    public var block: String?
    public var city: String?
    public var rcAbbre: String?
    public var lata: String?
    public var locState: String?
}

/// One row in the port-status list.
public struct PortSummary: Codable, Hashable, Sendable {
    public var status: String
    public var id: String?
    public var pid: String?
    /// Firm Order Commitment date (YYYYMMDD).
    public var foc: String?
    public var createdAt: String?
    public var message: String?
    public var supportUrl: String?
}

/// Full record for a single port-in.
public struct PortDetail: Codable, Hashable, Sendable {
    public var status: String
    public var id: String?
    public var pid: String?
    public var name: String?
    public var email: String?
    public var foc: String?
    public var createdAt: String?
    public var numbers: [String]?
    public var message: String?
}

/// Response for `GET /v2.2/inventory`.
public struct InventorySearchData: Codable, Hashable, Sendable {
    public var numbers: [InventoryItem]
}

/// Response for `GET /v2.2/inventory/coverage`.
public struct InventoryCoverageData: Codable, Hashable, Sendable {
    public var coverage: [InventoryCoverageItem]
}

/// One row in ``OrderCreateData/failed``.
public struct OrderFailedEntry: Codable, Hashable, Sendable {
    public var number: String
    public var reason: String
}

/// Response for `POST /v2.2/orders`.
public struct OrderCreateData: Codable, Hashable, Sendable {
    public var orderId: String
    public var amountCharged: Double
    public var numbersOrdered: [String]
    public var failed: [OrderFailedEntry]?
}

/// Response for `GET /v2.2/ports`.
public struct PortListData: Codable, Hashable, Sendable {
    public var ports: [PortSummary]
}

/// Response for `GET /v2.2/ports/{id}`.
public struct PortDetailData: Codable, Hashable, Sendable {
    public var port: PortDetail
}

/// Response for `POST /v2.2/ports`.
public struct PortSubmitData: Codable, Hashable, Sendable {
    /// 5-character port order ID.
    public var pid: String
    /// Support ticket ID.
    public var ticket: Int
    public var message: String
    /// LOA download URL.
    public var loaUrl: String
    /// Port-status URL.
    public var portUrl: String
}

/// Response for `GET /v2.2/ports/availability/{number}`.
///
/// `localRoutingNumber` and `rateCenterTier` are new in v2.2.10.
public struct PortAvailabilityData: Codable, Hashable, Sendable {
    public var number: String
    public var portable: Bool
    /// Service-provider name; `nil` when unknown.
    public var losingCarrier: String?
    /// LRN of destination switch (v2.2.10+).
    public var localRoutingNumber: String?
    /// Rate-center tier classification (v2.2.10+).
    public var rateCenterTier: String?
    /// `nil` when portable.
    public var reason: String?
}

/// Query filters for ``INumberingService/searchInventory(query:)``.
public struct InventoryQuery: Hashable, Sendable {
    public var npa: Int?
    public var nxx: Int?
    public var state: String?
    public var rateCenter: String?
    public var contains: String?
    public var endsWith: String?
    public var limit: Int?

    public init(
        npa: Int? = nil,
        nxx: Int? = nil,
        state: String? = nil,
        rateCenter: String? = nil,
        contains: String? = nil,
        endsWith: String? = nil,
        limit: Int? = nil
    ) {
        self.npa = npa
        self.nxx = nxx
        self.state = state
        self.rateCenter = rateCenter
        self.contains = contains
        self.endsWith = endsWith
        self.limit = limit
    }
}

/// Query filters for ``INumberingService/coverage(query:)``.
public struct CoverageQuery: Hashable, Sendable {
    public var state: String?
    public var rateCenter: String?

    public init(state: String? = nil, rateCenter: String? = nil) {
        self.state = state
        self.rateCenter = rateCenter
    }
}
