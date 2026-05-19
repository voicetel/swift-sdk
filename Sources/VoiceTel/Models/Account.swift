//
//  Account.swift
//  VoiceTel
//
//  Models for the Account resource group.
//

import Foundation

/// Per-service rates exposed on an account.
public struct AccountRates: Codable, Hashable, Sendable {
    public var cnam: Double?
    public var intlMax: Double?
    public var nibble: Double?
    public var lrn: Double?
    public var fax: Double?
    public var tfAdj: Double?
    public var did: Double?
    public var mms: Double?
    public var sms: Double?

    public init(
        cnam: Double? = nil,
        intlMax: Double? = nil,
        nibble: Double? = nil,
        lrn: Double? = nil,
        fax: Double? = nil,
        tfAdj: Double? = nil,
        did: Double? = nil,
        mms: Double? = nil,
        sms: Double? = nil
    ) {
        self.cnam = cnam
        self.intlMax = intlMax
        self.nibble = nibble
        self.lrn = lrn
        self.fax = fax
        self.tfAdj = tfAdj
        self.did = did
        self.mms = mms
        self.sms = sms
    }
}

/// Per-service feature flags. `true` = enabled on this account.
public struct AccountServices: Codable, Hashable, Sendable {
    public var e911: Bool?
    public var cnam: Bool?
    public var bypassMedia: Bool?
    public var intl: Bool?
    public var rcid: Bool?
    public var mms: Bool?
    public var dialer: Bool?
    public var sms: Bool?

    public init(
        e911: Bool? = nil,
        cnam: Bool? = nil,
        bypassMedia: Bool? = nil,
        intl: Bool? = nil,
        rcid: Bool? = nil,
        mms: Bool? = nil,
        dialer: Bool? = nil,
        sms: Bool? = nil
    ) {
        self.e911 = e911
        self.cnam = cnam
        self.bypassMedia = bypassMedia
        self.intl = intl
        self.rcid = rcid
        self.mms = mms
        self.dialer = dialer
        self.sms = sms
    }
}

/// Account profile returned by `GET /v2.2/account`.
public struct AccountData: Codable, Hashable, Sendable {
    public var username: String?
    public var name: String?
    public var email: String?
    public var enabled: Bool?
    public var created: String?
    public var cash: Double?
    public var callerId: String?
    public var timezone: String?
    public var authType: Int?
    public var ccs: Int?
    public var notify: Bool?
    public var notifyThreshold: Int?
    public var rates: AccountRates?
    public var services: AccountServices?
}

/// A single credit-history entry.
public struct CreditEntry: Codable, Hashable, Sendable {
    public var date: String
    public var paid: Bool
    public var amount: Double
}

/// A single payment-history entry.
///
/// `status` is one of `"Completed"`, `"Pending"`, `"Reversed"`, `"Refunded"`, `"Failed"`,
/// `"Denied"`, `"Canceled_Reversal"`.
public struct PaymentEntry: Codable, Hashable, Sendable {
    public var transactionId: String?
    public var date: String
    public var payerEmail: String?
    public var status: String
    public var amount: Double
}

/// Per-call billing summary inside a CDR row.
///
/// Numeric fields stay as strings to preserve full precision on the wire.
public struct CdrEntryValue: Codable, Hashable, Sendable {
    /// Billed duration in seconds.
    public var dur: String?
    /// Destination 10-digit TN.
    public var dst: String?
    /// Billed amount in USD.
    public var ba: String?
    /// Nibble rate in USD/min.
    public var nr: String?
    /// URL-encoded display name (CNAM at call time).
    public var cn: String?
    /// IPv4 of the leg.
    public var ip: String?
    /// Caller ID 10-digit TN.
    public var cid: String?
}

/// One row in ``AccountCdrData``.
public struct CdrEntry: Codable, Hashable, Sendable {
    public var id: String
    /// `[accountUsername, startEpochUnixSeconds]`.
    public var key: [String]
    public var value: CdrEntryValue
}

/// Response for `GET /v2.2/account/cdr`.
public struct AccountCdrData: Codable, Hashable, Sendable {
    public var cdr: [CdrEntry]
    /// Echo of the `start` query param.
    public var start: Int
    /// Echo of the `end` query param.
    public var end: Int
}

/// Response for `GET /v2.2/account/credits`.
public struct AccountCreditsData: Codable, Hashable, Sendable {
    public var credits: [CreditEntry]
}

/// Response for `GET /v2.2/account/payments`.
public struct AccountPaymentsData: Codable, Hashable, Sendable {
    public var payments: [PaymentEntry]
}

/// A single monthly-recurring charge row.
public struct MrcCharge: Codable, Hashable, Sendable {
    public var amount: Double
    public var description: String?
}

/// Response for `GET /v2.2/account/recurring-charges`.
public struct AccountMrcData: Codable, Hashable, Sendable {
    public var charges: [MrcCharge]
    public var total: Double
}

/// Response for `GET /v2.2/account/registration`.
public struct AccountRegistrationData: Codable, Hashable, Sendable {
    public var agent: String?
    public var uri: String?
    public var expires: Int?
}

/// Body for `POST /v2.2/account` (admin-only sub-account creation).
public struct AccountAddRequest: Codable, Hashable, Sendable {
    public var username: Int
    public var name: String
    public var email: String
    public var masterAccount: Int?

    public init(username: Int, name: String, email: String, masterAccount: Int? = nil) {
        self.username = username
        self.name = name
        self.email = email
        self.masterAccount = masterAccount
    }
}

/// Response for `POST /v2.2/account`.
public struct AccountAddData: Codable, Hashable, Sendable {
    public var username: String?
    public var name: String?
    public var email: String?
    public var masterAccount: String?
    /// Auto-generated initial password.
    public var password: String?
}

/// Body for `PUT /v2.2/account`. Optional fields are `nil` to leave unchanged.
public struct AccountPutRequest: Codable, Hashable, Sendable {
    public var notify: Bool?
    public var notifyThreshold: Int?
    public var timezone: String?
    public var callerId: String?
    /// Admin only.
    public var e911: Bool?
    /// Admin only.
    public var intl: Bool?
    /// Admin only.
    public var sms: Bool?
    /// Admin only.
    public var mms: Bool?
    /// Admin only.
    public var ccs: Int?

    public init(
        notify: Bool? = nil,
        notifyThreshold: Int? = nil,
        timezone: String? = nil,
        callerId: String? = nil,
        e911: Bool? = nil,
        intl: Bool? = nil,
        sms: Bool? = nil,
        mms: Bool? = nil,
        ccs: Int? = nil
    ) {
        self.notify = notify
        self.notifyThreshold = notifyThreshold
        self.timezone = timezone
        self.callerId = callerId
        self.e911 = e911
        self.intl = intl
        self.sms = sms
        self.mms = mms
        self.ccs = ccs
    }
}

/// Response for `PUT /v2.2/account`.
public struct AccountPutData: Codable, Hashable, Sendable {
    public var updated: [String]
}

/// Body for `POST /v2.2/accounts` (public sign-up).
public struct AccountSignupRequest: Codable, Hashable, Sendable {
    public var name: String
    public var email: String
    public var promo: String?

    public init(name: String, email: String, promo: String? = nil) {
        self.name = name
        self.email = email
        self.promo = promo
    }
}

/// Response for `POST /v2.2/accounts`.
public struct AccountSignupData: Codable, Hashable, Sendable {
    public var username: String?
    public var name: String?
    public var email: String?
    public var password: String?
}

/// Body for `POST /v2.2/account/recovery` (no auth required).
public struct AccountRecoverRequest: Codable, Hashable, Sendable {
    public var email: String

    public init(email: String) {
        self.email = email
    }
}

/// Response for `POST /v2.2/account/recovery`.
public struct AccountRecoverData: Codable, Hashable, Sendable {
    public var message: String?
}

/// Response for `POST /v2.2/account/api-key`.
public struct AccountApiKeyData: Codable, Hashable, Sendable {
    public var apiKey: String

    enum CodingKeys: String, CodingKey {
        // Wire field is "apikey" (all lowercase).
        case apiKey = "apikey"
    }
}
