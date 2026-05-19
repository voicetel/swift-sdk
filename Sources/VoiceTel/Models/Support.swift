//
//  Support.swift
//  VoiceTel
//
//  Models for the Support resource group (ticketing).
//

import Foundation

/// Ticket status. One of `"active"`, `"pending"`, `"closed"`, `"spam"`.
public typealias TicketStatus = String

// MARK: - Requests

/// Body for `POST /v2.2/support/tickets`.
public struct TicketCreateRequest: Codable, Hashable, Sendable {
    public var subject: String
    public var message: String
    /// Admin only: create on behalf of this customer.
    public var email: String?

    public init(subject: String, message: String, email: String? = nil) {
        self.subject = subject
        self.message = message
        self.email = email
    }
}

/// Body for `PUT /v2.2/support/tickets/{id}`.
public struct TicketUpdateRequest: Codable, Hashable, Sendable {
    public var status: TicketStatus

    public init(status: TicketStatus) {
        self.status = status
    }
}

/// Body for `POST /v2.2/support/tickets/{id}/replies`.
public struct TicketReplyRequest: Codable, Hashable, Sendable {
    public var message: String

    public init(message: String) {
        self.message = message
    }
}

// MARK: - Shared sub-types

/// Describes how a ticket or thread originated.
public struct TicketSource: Codable, Hashable, Sendable {
    public var via: String?
    public var type: String?
}

/// Action descriptor on a thread.
public struct TicketAction: Codable, Hashable, Sendable {
    public var text: String?
    public var type: String?
}

/// `createdBy` / `assignee` / `assignedTo` / `closedByUser` shape.
public struct TicketActor: Codable, Hashable, Sendable {
    public var id: Int?
    /// `"customer"` or `"user"`.
    public var type: String?
    public var email: String?
    public var firstName: String?
    public var lastName: String?
    public var photoUrl: String?
}

/// One custom-field row on a conversation.
public struct CustomFieldValue: Codable, Hashable, Sendable {
    public var id: Int?
    public var value: String?
    public var text: String?
}

/// `{id, value, type}` entry under `embedded.emails` / `phones` / `socialProfiles`.
public struct CustomerContactEntry: Codable, Hashable, Sendable {
    public var id: Int?
    public var value: String?
    public var type: String?
}

/// `{id, value}` entry under `embedded.websites`.
public struct CustomerWebsiteEntry: Codable, Hashable, Sendable {
    public var id: Int?
    public var value: String?
}

/// `embedded.address` shape on a ``SupportCustomer``.
public struct CustomerAddress: Codable, Hashable, Sendable {
    public var street: String?
    public var city: String?
    /// Two-letter US state code.
    public var state: String?
    /// ISO 3166-1 alpha-2.
    public var country: String?
    public var zip: String?
}

/// `embedded` shape on a ``SupportCustomer``.
public struct CustomerEmbedded: Codable, Hashable, Sendable {
    public var address: CustomerAddress?
    public var emails: [CustomerContactEntry]?
    public var phones: [CustomerContactEntry]?
    public var socialProfiles: [CustomerContactEntry]?
    public var websites: [CustomerWebsiteEntry]?
}

/// One file attached to a support thread.
public struct SupportAttachment: Codable, Hashable, Sendable {
    public var id: Int?
    public var mimeType: String?
    public var fileName: String?
    public var fileUrl: String?
    /// Size in bytes.
    public var size: Int?
}

/// `embedded` shape on a ``SupportThread``.
public struct ThreadEmbedded: Codable, Hashable, Sendable {
    public var attachments: [SupportAttachment]?
}

/// `embedded` shape on a ``SupportConversation``.
public struct ConversationEmbedded: Codable, Hashable, Sendable {
    public var threads: [SupportThread]?
}

/// End-user profile attached to a support ticket.
public struct SupportCustomer: Codable, Hashable, Sendable {
    public var id: Int?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    /// Free-form, max 60.
    public var company: String?
    public var jobTitle: String?
    public var photoType: String?
    public var photoUrl: String?
    public var notes: String?
    /// Always `"customer"`.
    public var type: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var embedded: CustomerEmbedded?
}

/// One message in a ticket conversation.
public struct SupportThread: Codable, Hashable, Sendable {
    public var id: Int?
    public var status: TicketStatus
    public var state: String?
    /// `"customer"`, `"message"`, or `"note"`.
    public var type: String?
    public var body: String?
    public var rating: Int?
    public var ratingComment: String?
    public var openedAt: String?
    public var createdAt: String?
    public var source: TicketSource?
    public var action: TicketAction?
    public var createdBy: TicketActor?
    public var assignedTo: TicketActor?
    public var customer: SupportCustomer?
    public var to: [String]?
    public var cc: [String]?
    public var bcc: [String]?
    public var embedded: ThreadEmbedded?
}

/// A support ticket.
///
/// **Important wire-quirk:** the API field `number` is a ticket *sequence number*
/// (e.g. `1015`, `2114`), NOT a phone number. We surface it as ``ticketNumber``
/// to avoid confusion with the 10-digit TNs used everywhere else in this SDK.
public struct SupportConversation: Codable, Hashable, Sendable {
    public var id: Int?
    /// Human-readable ticket sequence number. Maps to wire field `number`.
    public var ticketNumber: Int?
    public var status: TicketStatus
    public var state: String?
    public var subject: String?
    public var preview: String?
    public var type: String?
    public var mailboxId: Int?
    public var folderId: Int?
    public var threadsCount: Int?
    public var closedBy: Int?
    public var closedAt: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var userUpdatedAt: String?
    /// Free-form map; preserved as encoded JSON so the SDK never lies about shape.
    public var customerWaitingSince: JSONValue?
    public var source: TicketSource?
    public var createdBy: TicketActor?
    public var assignee: TicketActor?
    public var closedByUser: TicketActor?
    public var customer: SupportCustomer?
    public var cc: [String]?
    public var bcc: [String]?
    public var customFields: [CustomFieldValue]?
    public var embedded: ConversationEmbedded?

    enum CodingKeys: String, CodingKey {
        case id
        case ticketNumber = "number"
        case status, state, subject, preview, type
        case mailboxId, folderId, threadsCount, closedBy, closedAt
        case createdAt, updatedAt, userUpdatedAt, customerWaitingSince
        case source, createdBy, assignee, closedByUser, customer
        case cc, bcc, customFields, embedded
    }
}

// MARK: - Responses

/// Response for `GET`/`POST /v2.2/support/tickets/{...}`.
public struct TicketData: Codable, Hashable, Sendable {
    public var ticket: SupportConversation
}

/// Response for `GET /v2.2/support/tickets`.
public struct TicketsListData: Codable, Hashable, Sendable {
    public var tickets: [SupportConversation]
}

/// Response for `GET /v2.2/support/tickets/{id}/messages`.
public struct TicketThreadsData: Codable, Hashable, Sendable {
    public var messages: [SupportThread]
}

/// Response for `POST /v2.2/support/tickets/{id}/replies`.
public struct TicketReplyData: Codable, Hashable, Sendable {
    /// Always `"Reply added"`.
    public var message: String
}

/// Response for `PUT /v2.2/support/tickets/{id}`.
public struct TicketUpdateData: Codable, Hashable, Sendable {
    public var id: Int?
    /// Outcome, e.g. `"success"`.
    public var status: String
}

// MARK: - JSONValue

/// A loosely-typed JSON value. Used for response fields whose shape the API
/// docs don't pin down (e.g. ``SupportConversation/customerWaitingSince``).
public enum JSONValue: Codable, Hashable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([JSONValue].self) {
            self = .array(arr)
        } else if let obj = try? container.decode([String: JSONValue].self) {
            self = .object(obj)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let b): try container.encode(b)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .string(let s): try container.encode(s)
        case .array(let a): try container.encode(a)
        case .object(let o): try container.encode(o)
        }
    }
}
