//
//  SupportServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class SupportServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testList() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/support/tickets",
            json: envelope(#"{"tickets":[{"id":1,"number":1015,"status":"active","subject":"hi"}]}"#)
        )
        let r = try await client.support.list()
        XCTAssertEqual(r.tickets[0].ticketNumber, 1015)
        XCTAssertEqual(r.tickets[0].status, "active")
    }

    func testListFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/support/tickets", statusCode: 500, json: "{}")
        do { _ = try await client.support.list(); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testCreate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/support/tickets",
            json: envelope(#"{"ticket":{"id":1,"number":1015,"status":"active","subject":"hi"}}"#)
        )
        let r = try await client.support.create(TicketCreateRequest(subject: "hi", message: "body"))
        XCTAssertEqual(r.ticket.ticketNumber, 1015)
    }

    func testCreateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/support/tickets", statusCode: 400, json: "{}")
        do {
            _ = try await client.support.create(TicketCreateRequest(subject: "", message: ""))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testGet() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/support/tickets/42",
            json: envelope(#"{"ticket":{"id":42,"number":2114,"status":"pending"}}"#)
        )
        let r = try await client.support.get(id: 42)
        XCTAssertEqual(r.ticket.id, 42)
        XCTAssertEqual(r.ticket.ticketNumber, 2114)
    }

    func testGetFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/support/tickets/42", statusCode: 404, json: "{}")
        do { _ = try await client.support.get(id: 42); XCTFail("expected") } catch let e as APIError { XCTAssertEqual(e.kind, .notFound) } catch { XCTFail("unexpected: \(error)") }
    }

    func testUpdate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/support/tickets/42",
            json: envelope(#"{"id":42,"status":"success"}"#)
        )
        let r = try await client.support.update(id: 42, body: TicketUpdateRequest(status: "closed"))
        XCTAssertEqual(r.id, 42)
        XCTAssertEqual(r.status, "success")
    }

    func testUpdateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/support/tickets/42", statusCode: 400, json: "{}")
        do { _ = try await client.support.update(id: 42, body: TicketUpdateRequest(status: "x")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testDelete204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/support/tickets/42", statusCode: 204, body: Data())
        try await client.support.delete(id: 42)
    }

    func testDeleteFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/support/tickets/42", statusCode: 403, json: "{}")
        do { try await client.support.delete(id: 42); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testMessages() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/support/tickets/42/messages",
            json: envelope(#"{"messages":[{"id":1,"status":"active","body":"hi"}]}"#)
        )
        let r = try await client.support.messages(id: 42)
        XCTAssertEqual(r.messages[0].body, "hi")
    }

    func testMessagesFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/support/tickets/42/messages", statusCode: 404, json: "{}")
        do { _ = try await client.support.messages(id: 42); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testReply() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/support/tickets/42/replies",
            json: envelope(#"{"message":"Reply added"}"#)
        )
        let r = try await client.support.reply(id: 42, body: TicketReplyRequest(message: "thx"))
        XCTAssertEqual(r.message, "Reply added")
    }

    func testReplyFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/support/tickets/42/replies", statusCode: 400, json: "{}")
        do { _ = try await client.support.reply(id: 42, body: TicketReplyRequest(message: "")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testTicketNumberMapsToWireField() throws {
        // Ensures CodingKeys translates ticketNumber <-> "number" on the wire.
        let json = Data(#"{"id":1,"number":1015,"status":"active"}"#.utf8)
        let conv = try JSONDecoder().decode(SupportConversation.self, from: json)
        XCTAssertEqual(conv.ticketNumber, 1015)

        let encoded = try JSONEncoder().encode(conv)
        let dict = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        XCTAssertEqual(dict["number"] as? Int, 1015)
        XCTAssertNil(dict["ticketNumber"])
    }
}
