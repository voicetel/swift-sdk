//
//  FaxService.swift
//  VoiceTel
//
//  Resource service for the Fax tag (spec v2.2.21).
//

import Foundation

/// Sending faxes and reading their delivery state.
public final class FaxService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/numbers/fax` — every fax-capable number on the account with
    /// the email address each delivers to (`destinationId` 0 = account email).
    public func numbers() async throws -> FaxNumbersData {
        try await transport.request(.get, path: "/v2.2/numbers/fax", responseType: FaxNumbersData.self)
    }

    /// `POST /v2.2/faxes` — submit a fax for delivery (HTTP 201).
    ///
    /// The request is hand-built `multipart/form-data`; the required
    /// `Idempotency-Key` header is the request's `idempotencyKey` when set,
    /// otherwise a generated UUID — resubmitting the same documents with the
    /// same key returns the original job instead of sending twice. Requires
    /// an enabled account with a positive balance; rate limit 10 sends per
    /// minute per account (429 with `Retry-After: 60`).
    public func send(_ input: FaxSendRequest) async throws -> FaxSendData {
        guard !input.documents.isEmpty else {
            throw APIError(kind: .badRequest, message: "fax send requires at least one document")
        }
        var form = MultipartFormData()
        form.addField(name: "fromNumber", value: input.fromNumber)
        form.addField(name: "toNumber", value: input.toNumber)
        for doc in input.documents {
            form.addFile(MultipartFile(
                name: "documents",
                filename: doc.name,
                contentType: doc.contentType,
                data: doc.data
            ))
        }
        return try await transport.requestMultipart(
            path: "/v2.2/faxes",
            form: form,
            idempotencyKey: input.idempotencyKey,
            responseType: FaxSendData.self
        )
    }

    /// `GET /v2.2/faxes` — faxes sent from one of your fax numbers, newest
    /// first, with cursor paging. `query.number` is required; `from` is the
    /// newer edge of the range (defaults to now), `to` the older edge
    /// (defaults to 24 hours ago).
    public func history(_ query: FaxHistoryQuery) async throws -> FaxHistoryData {
        let q: [String: String?] = [
            "number": query.number,
            "from": query.from.map(String.init),
            "to": query.to.map(String.init),
            "limit": query.limit.map(String.init),
            "cursor": query.cursor,
            "status": query.status
        ]
        return try await transport.request(.get, path: "/v2.2/faxes", query: q, responseType: FaxHistoryData.self)
    }

    /// `GET /v2.2/faxes/{id}` — one fax job. Poll until `status` is `"sent"`
    /// or `"failed"`.
    public func get(id: String) async throws -> FaxJob {
        try await transport.request(
            .get,
            path: "/v2.2/faxes/\(encodePathSegment(id))",
            responseType: FaxJob.self
        )
    }

    /// `GET /v2.2/faxes/{id}/document` — the PDF rendering of a fax job as
    /// raw bytes (binary response, not JSON). Available when the job reports
    /// `documentAvailable == true`; throws `.notFound` otherwise.
    public func document(id: String) async throws -> Data {
        try await transport.requestRaw(
            .get,
            path: "/v2.2/faxes/\(encodePathSegment(id))/document"
        )
    }
}
