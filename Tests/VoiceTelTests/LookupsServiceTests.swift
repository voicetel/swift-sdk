//
//  LookupsServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class LookupsServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testCNAM() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/cnam/2015551234",
            json: envelope(#"{"cnam":"ALICE","number":"2015551234"}"#)
        )
        let r = try await client.lookups.cnam(number: "2015551234")
        XCTAssertEqual(r.cnam, "ALICE")
    }

    func testCNAMFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/cnam/x", statusCode: 404, json: "{}")
        do {
            _ = try await client.lookups.cnam(number: "x")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testLRN() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/lrn/2015551234/2125550000",
            json: envelope("""
            {"ani":"2125550000","destination":"2015551234","lrn":{"lrn":"2015550001","state":"NJ","city":"Newark","rc":"NWRK","local":"Y"}}
            """)
        )
        let r = try await client.lookups.lrn(number: "2015551234", ani: "2125550000")
        XCTAssertEqual(r.lrn.state, "NJ")
        XCTAssertEqual(r.lrn.local, "Y")
    }

    func testLRNFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/lrn/x/y", statusCode: 403, json: "{}")
        do {
            _ = try await client.lookups.lrn(number: "x", ani: "y")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .permissionDenied)
        } catch { XCTFail("unexpected: \(error)") }
    }
}
