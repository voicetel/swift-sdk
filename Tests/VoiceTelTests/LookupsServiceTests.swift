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
            path: "/v2.2/cnam/2015550123",
            json: envelope(#"{"cnam":"ALICE","number":"2015550123"}"#)
        )
        let r = try await client.lookups.cnam(number: "2015550123")
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

    func testCarrier() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/carrier/2015550123",
            json: envelope(#"{"number":"2015550123","carrier":{"name":"EXAMPLE CARRIER","type":"voip","mobile_country_code":null,"mobile_network_code":null,"error_code":null}}"#)
        )
        let r = try await client.lookups.carrier(number: "2015550123")
        XCTAssertEqual(r.number, "2015550123")
        XCTAssertEqual(r.carrier.name, "EXAMPLE CARRIER")
        XCTAssertEqual(r.carrier.type, "voip")
        XCTAssertNil(r.carrier.mobile_country_code)
        XCTAssertNil(r.carrier.mobile_network_code)
        XCTAssertNil(r.carrier.error_code)
    }

    // Mobile numbers fill the snake_case mobile codes; error_code is an int.
    func testCarrierMobileFields() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/carrier/2125550123",
            json: envelope(#"{"number":"2125550123","carrier":{"name":"EXAMPLE MOBILE","type":"mobile","mobile_country_code":"310","mobile_network_code":"456","error_code":0}}"#)
        )
        let r = try await client.lookups.carrier(number: "2125550123")
        XCTAssertEqual(r.carrier.type, "mobile")
        XCTAssertEqual(r.carrier.mobile_country_code, "310")
        XCTAssertEqual(r.carrier.mobile_network_code, "456")
        XCTAssertEqual(r.carrier.error_code, 0)
    }

    func testCarrierFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/carrier/x", statusCode: 403, json: "{}")
        do {
            _ = try await client.lookups.carrier(number: "x")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .permissionDenied)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testLRN() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/lrn/2015550123/2125550000",
            json: envelope("""
            {"ani":"2125550000","destination":"2015550123","lrn":{"lrn":"2015550001","state":"NJ","city":"Newark","rc":"NWRK","local":"Y"}}
            """)
        )
        let r = try await client.lookups.lrn(number: "2015550123", ani: "2125550000")
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
