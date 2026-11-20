//
//  Fax.swift
//  VoiceTel
//
//  Models for the Fax resource group (spec v2.2.21).
//

import Foundation

// MARK: - Requests

/// Input for `POST /v2.2/faxes` (send a fax).
///
/// The body travels as `multipart/form-data`: `fromNumber` and `toNumber`
/// text fields plus one `documents` file part per document (1–10 files,
/// PDF/DOC/DOCX checked by content, 8 MiB each and 8 MiB in total).
///
/// `idempotencyKey` is a client-generated UUID sent as the required
/// `Idempotency-Key` header: resubmitting the same documents with the same
/// key returns the original job instead of sending twice. When `nil` the
/// transport mints one for the single attempt chain (retries reuse it).
public struct FaxSendRequest: Hashable, Sendable {
    /// 10-digit fax number on the authenticated account.
    public var fromNumber: String
    /// 10-digit US/CA destination number.
    public var toNumber: String
    /// 1–10 documents to transmit.
    public var documents: [FaxDocumentUpload]
    /// Optional client-generated UUID for the `Idempotency-Key` header.
    public var idempotencyKey: String?

    public init(
        fromNumber: String,
        toNumber: String,
        documents: [FaxDocumentUpload],
        idempotencyKey: String? = nil
    ) {
        self.fromNumber = fromNumber
        self.toNumber = toNumber
        self.documents = documents
        self.idempotencyKey = idempotencyKey
    }
}

/// One uploaded fax document.
public struct FaxDocumentUpload: Hashable, Sendable {
    /// File name as transmitted (e.g. `"contract.pdf"`).
    public var name: String
    /// MIME type: `application/pdf`, `application/msword`, or
    /// `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
    public var contentType: String
    /// Raw file bytes (the API checks content, not the extension).
    public var data: Data

    public init(name: String, contentType: String, data: Data) {
        self.name = name
        self.contentType = contentType
        self.data = data
    }
}

/// Query for `GET /v2.2/faxes` (fax history).
public struct FaxHistoryQuery: Hashable, Sendable {
    /// Required. A fax number on the authenticated account.
    public var number: String
    /// Newer edge of the range, unix seconds. Defaults to now.
    public var from: Int?
    /// Older edge of the range, unix seconds. Defaults to 24 hours ago.
    public var to: Int?
    /// Page size, 1 to 100. Defaults to 50.
    public var limit: Int?
    /// Opaque paging cursor from a previous response's `nextCursor`.
    public var cursor: String?
    /// `all`, `active` (not yet finished), `queued`, `sending`,
    /// `retry_pending`, `sent`, or `failed`.
    public var status: String?

    public init(
        number: String,
        from: Int? = nil,
        to: Int? = nil,
        limit: Int? = nil,
        cursor: String? = nil,
        status: String? = nil
    ) {
        self.number = number
        self.from = from
        self.to = to
        self.limit = limit
        self.cursor = cursor
        self.status = status
    }
}

// MARK: - Responses

/// A fax-capable number on the account, as returned by
/// `GET /v2.2/numbers/fax`.
public struct FaxNumber: Codable, Hashable, Sendable {
    /// 10-digit TN.
    public var number: String
    /// Id of the per-number fax destination; `0` delivers to the account email.
    public var destinationId: Int
    /// Email address faxes to this number deliver to.
    public var email: String
}

/// Response for `GET /v2.2/numbers/fax`.
public struct FaxNumbersData: Codable, Hashable, Sendable {
    public var numbers: [FaxNumber]
}

/// A document attached to a fax job (send echo and job reads alike).
public struct FaxDocumentInfo: Codable, Hashable, Sendable {
    public var name: String
    public var size: Int
    public var contentType: String
}

/// Response for `POST /v2.2/faxes` (HTTP 201).
public struct FaxSendData: Codable, Hashable, Sendable {
    public var id: String
    public var fromNumber: String
    public var toNumber: String
    /// `"queued"` on a fresh submission.
    public var status: String
    public var documents: [FaxDocumentInfo]?
}

/// A fax job, as returned by history and `GET /v2.2/faxes/{id}`.
///
/// Timestamps are ISO-8601 UTC strings. Poll until `status` is `"sent"` or
/// `"failed"`.
public struct FaxJob: Codable, Hashable, Sendable {
    public var id: String
    public var fromNumber: String
    public var toNumber: String
    /// The `Idempotency-Key` the job was submitted with, `nil` otherwise.
    public var clientToken: String?
    /// `"queued"`, `"sending"`, `"retry_pending"`, `"sent"`, or `"failed"`.
    public var status: String
    public var submittedAt: String
    public var startedAt: String?
    public var completedAt: String?
    public var attempts: Int?
    public var failureReason: String?
    public var documents: [FaxDocumentInfo]?
    /// Whether `document(id:)` can serve the rendered PDF.
    public var documentAvailable: Bool?
    public var documentName: String?
    public var documentSize: Int?
}

/// Response for `GET /v2.2/faxes` — one page of history, newest first.
public struct FaxHistoryData: Codable, Hashable, Sendable {
    public var number: String
    public var fromTs: Int
    public var toTs: Int
    public var faxes: [FaxJob]
    /// Cursor for the next page; `nil` when exhausted.
    public var nextCursor: String?
}
