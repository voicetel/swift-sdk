//
//  GatewaysServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class GatewaysServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testList() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/gateways",
            json: envelope(#"{"gateways":[{"id":4,"gateway":"DID","system":true}]}"#)
        )
        let r = try await client.gateways.list()
        XCTAssertEqual(r.gateways.first?.gateway, "DID")
        XCTAssertEqual(r.gateways.first?.system, true)
        XCTAssertNil(r.gateways.first?.limit)
    }

    func testListFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/gateways", statusCode: 500, json: "{}")
        do {
            _ = try await client.gateways.list()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testAdd() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/gateways",
            json: envelope(#"{"id":10,"gateway":"1.2.3.4","limit":23}"#)
        )
        let r = try await client.gateways.add(GatewayAddRequest(gateway: "1.2.3.4"))
        XCTAssertEqual(r.id, 10)
        XCTAssertEqual(r.limit, 23)
    }

    func testAddFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/gateways", statusCode: 400, json: #"{"message":"bad gateway"}"#)
        do {
            _ = try await client.gateways.add(GatewayAddRequest(gateway: "x"))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .badRequest)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testGet() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/gateways/10",
            json: envelope(#"{"id":10,"gateway":"1.2.3.4","limit":23}"#)
        )
        let r = try await client.gateways.get(id: 10)
        XCTAssertEqual(r.id, 10)
    }

    func testGetFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/gateways/99", statusCode: 404, json: "{}")
        do {
            _ = try await client.gateways.get(id: 99)
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testUpdate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/gateways/10",
            json: envelope(#"{"id":10,"gateway":"1.2.3.4","limit":50}"#)
        )
        let r = try await client.gateways.update(id: 10, body: GatewayUpdateRequest(limit: 50))
        XCTAssertEqual(r.limit, 50)
    }

    func testUpdateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/gateways/10", statusCode: 400, json: "{}")
        do {
            _ = try await client.gateways.update(id: 10, body: GatewayUpdateRequest())
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRemove204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/gateways/10", statusCode: 204, body: Data())
        try await client.gateways.remove(id: 10)
    }

    func testRemoveFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/gateways/10", statusCode: 404, json: "{}")
        do {
            try await client.gateways.remove(id: 10)
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testNumbers() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/gateways/10/numbers",
            json: envelope(#"{"numbers":[{"number":"2015551234","translated":"2015551234","forward":false,"forwardTo":null,"cnam":false,"carrier":0,"smsEnabled":false,"faxEnabled":false}]}"#)
        )
        let r = try await client.gateways.numbers(id: 10)
        XCTAssertEqual(r.numbers[0].number, "2015551234")
        XCTAssertNil(r.numbers[0].forwardTo)
    }

    func testNumbersFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/gateways/10/numbers", statusCode: 404, json: "{}")
        do {
            _ = try await client.gateways.numbers(id: 10)
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }
}
