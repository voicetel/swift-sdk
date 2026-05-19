//
//  ACLServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class ACLServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testList() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/acl",
            json: envelope(#"{"acl":[{"cidr":"1.2.3.4/32"}]}"#)
        )
        let resp = try await client.acl.list()
        XCTAssertEqual(resp.acl[0].cidr, "1.2.3.4/32")
    }

    func testListFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/acl", statusCode: 401, json: #"{"message":"nope"}"#)
        do {
            _ = try await client.acl.list()
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .authentication)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testAdd() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/acl",
            json: envelope(#"{"added":[{"cidr":"1.2.3.4/32"}]}"#)
        )
        let resp = try await client.acl.add(AclModifyRequest(acl: [CidrEntry(cidr: "1.2.3.4/32")]))
        XCTAssertEqual(resp.added[0].cidr, "1.2.3.4/32")
    }

    func testAddConflictBody() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/acl",
            statusCode: 409,
            json: #"{"message":"partial","added":[{"cidr":"1.2.3.4/32"}],"failed":[{"cidr":"10.0.0.0/24","reason":"Invalid mask: must be /8, /16, /24, or /32"}]}"#
        )
        do {
            _ = try await client.acl.add(AclModifyRequest(acl: []))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .conflict)
            XCTAssertNotNil(e.body)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testRemove() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "DELETE",
            path: "/v2.2/acl",
            json: envelope(#"{"removed":[{"cidr":"1.2.3.4/32"}]}"#)
        )
        let resp = try await client.acl.remove(AclModifyRequest(acl: [CidrEntry(cidr: "1.2.3.4/32")]))
        XCTAssertEqual(resp.removed[0].cidr, "1.2.3.4/32")
    }

    func testRemoveFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/acl", statusCode: 404, json: "{}")
        do {
            _ = try await client.acl.remove(AclModifyRequest(acl: []))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }
}
