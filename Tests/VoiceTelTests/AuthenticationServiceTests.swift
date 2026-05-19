//
//  AuthenticationServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class AuthenticationServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testGet() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/auth",
            json: envelope(#"{"authType":1,"authTypeDescription":"IP Auth","acl":[{"cidr":"1.2.3.4/32"}]}"#)
        )
        let resp = try await client.authentication.get()
        XCTAssertEqual(resp.authType, 1)
        XCTAssertEqual(resp.authTypeDescription, "IP Auth")
        XCTAssertEqual(resp.acl[0].cidr, "1.2.3.4/32")
    }

    func testGetFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/auth", statusCode: 500, json: "{}")
        do {
            _ = try await client.authentication.get()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testUpdate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/auth",
            json: envelope(#"{"updated":[{"field":"authType","value":2},{"field":"password"}]}"#)
        )
        let resp = try await client.authentication.update(AuthPutRequest(authType: 2, password: "abc123"))
        XCTAssertEqual(resp.updated.count, 2)
        XCTAssertEqual(resp.updated[0].field, "authType")
        XCTAssertEqual(resp.updated[0].value, 2)
    }

    func testUpdateConflict() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/auth",
            statusCode: 409,
            json: #"{"message":"partial","updated":[{"field":"authType","value":3}]}"#
        )
        do {
            _ = try await client.authentication.update(AuthPutRequest(authType: 3))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .conflict)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testAuthTypeConstants() {
        XCTAssertEqual(AuthType.digest, 0)
        XCTAssertEqual(AuthType.ipAuth, 1)
        XCTAssertEqual(AuthType.digestOrIP, 2)
        XCTAssertEqual(AuthType.digestAndIP, 3)
    }
}
