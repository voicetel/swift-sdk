//
//  SupportService.swift
//  VoiceTel
//
//  Resource service for the Support tag (ticketing).
//

import Foundation

/// Support ticket management.
///
/// Customers see only their own tickets. Administrators see all tickets.
public final class SupportService: @unchecked Sendable {
    let transport: Transport
    init(transport: Transport) { self.transport = transport }

    /// `GET /v2.2/support/tickets` — every ticket visible to the caller.
    public func list() async throws -> TicketsListData {
        try await transport.request(.get, path: "/v2.2/support/tickets", responseType: TicketsListData.self)
    }

    /// `POST /v2.2/support/tickets` — open a new support ticket.
    public func create(_ body: TicketCreateRequest) async throws -> TicketData {
        try await transport.request(.post, path: "/v2.2/support/tickets", body: body, responseType: TicketData.self)
    }

    /// `GET /v2.2/support/tickets/{id}` — fetch one ticket by id.
    public func get(id: Int) async throws -> TicketData {
        try await transport.request(.get, path: "/v2.2/support/tickets/\(id)", responseType: TicketData.self)
    }

    /// `PUT /v2.2/support/tickets/{id}` — change a ticket's status.
    public func update(id: Int, body: TicketUpdateRequest) async throws -> TicketUpdateData {
        try await transport.request(.put, path: "/v2.2/support/tickets/\(id)", body: body, responseType: TicketUpdateData.self)
    }

    /// `DELETE /v2.2/support/tickets/{id}` — remove a ticket. Admin only. Returns 204 No Content.
    public func delete(id: Int) async throws {
        try await transport.requestVoid(.delete, path: "/v2.2/support/tickets/\(id)")
    }

    /// `GET /v2.2/support/tickets/{id}/messages` — every thread (message) on a ticket.
    public func messages(id: Int) async throws -> TicketThreadsData {
        try await transport.request(.get, path: "/v2.2/support/tickets/\(id)/messages", responseType: TicketThreadsData.self)
    }

    /// `POST /v2.2/support/tickets/{id}/replies` — add a reply to a ticket.
    public func reply(id: Int, body: TicketReplyRequest) async throws -> TicketReplyData {
        try await transport.request(.post, path: "/v2.2/support/tickets/\(id)/replies", body: body, responseType: TicketReplyData.self)
    }
}
