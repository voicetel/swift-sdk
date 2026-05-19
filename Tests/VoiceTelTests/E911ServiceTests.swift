//
//  E911ServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class E911ServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testList() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/e911",
            json: envelope("""
            {"records":[{"dn":"12015551234","callername":"ALICE","address1":"1 X St","city":"Newark","state":"NJ","zip":"07101"}]}
            """)
        )
        let r = try await client.e911.list()
        XCTAssertEqual(r.records[0].dn, "12015551234")
    }

    func testListFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/e911", statusCode: 500, json: "{}")
        do {
            _ = try await client.e911.list()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testCreate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/e911",
            json: envelope(#"{"record":{"dn":"12015551234","callername":"A","address1":"1","city":"N","state":"NJ","zip":"07101"}}"#)
        )
        let r = try await client.e911.create(E911CreateRequest(
            dn: "2015551234", callername: "A", address1: "1", city: "N", state: "NJ", zip: "07101"
        ))
        XCTAssertEqual(r.record.dn, "12015551234")
    }

    func testCreateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/e911", statusCode: 400, json: #"{"message":"bad zip"}"#)
        do {
            _ = try await client.e911.create(E911CreateRequest(dn: "x", callername: "x", address1: "x", city: "x", state: "x", zip: "x"))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .badRequest)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testValidate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/e911/validations",
            json: envelope(#"{"address":{"addressid":99,"address1":"1","city":"N","state":"NJ","zip":"07101"}}"#)
        )
        let r = try await client.e911.validate(E911AddressRequest(address1: "1", city: "N", state: "NJ", zip: "07101"))
        XCTAssertEqual(r.address.addressid, 99)
    }

    func testValidateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/e911/validations", statusCode: 400, json: "{}")
        do {
            _ = try await client.e911.validate(E911AddressRequest(address1: "", city: "", state: "", zip: ""))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testGet() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/e911/2015551234",
            json: envelope(#"{"record":{"dn":"12015551234","callername":"A","address1":"1","city":"N","state":"NJ","zip":"07101"}}"#)
        )
        let r = try await client.e911.get(dn: "2015551234")
        XCTAssertEqual(r.record.callername, "A")
    }

    func testGetNotFound() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/e911/2015551234", statusCode: 404, json: "{}")
        do {
            _ = try await client.e911.get(dn: "2015551234")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testProvision() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/e911/2015551234",
            json: envelope(#"{"record":{"dn":"12015551234","callername":"A","address1":"1","city":"N","state":"NJ","zip":"07101"}}"#)
        )
        let r = try await client.e911.provision(dn: "2015551234", body: E911ProvisionByIDRequest(callername: "A", addressid: 99))
        XCTAssertEqual(r.record.callername, "A")
    }

    func testProvisionFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/e911/x", statusCode: 400, json: "{}")
        do {
            _ = try await client.e911.provision(dn: "x", body: E911ProvisionByIDRequest(callername: "y", addressid: 0))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRemoveSucceedsOn204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/e911/2015551234", statusCode: 204, body: Data())
        try await client.e911.remove(dn: "2015551234")
    }

    func testRemoveFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/e911/2015551234", statusCode: 404, json: "{}")
        do {
            try await client.e911.remove(dn: "2015551234")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }
}
