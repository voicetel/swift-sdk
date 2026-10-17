//
//  INumberingServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class INumberingServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testSearchInventory() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/inventory",
            json: envelope(#"{"numbers":[{"number":"2015550123","rateCenter":"NEWARK","city":"Newark","province":"NJ","lata":"224"}]}"#)
        )
        let r = try await client.iNumbering.searchInventory(query: InventoryQuery(tnMask: "201555*", quantity: 10, province: "NJ", rateCenter: "NEWARK", lata: "224"))
        XCTAssertEqual(r.numbers[0].number, "2015550123")

        let url = MockURLProtocol.allRequests().first?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("tnMask=201555*") || url.contains("tnMask=201555%2A"))
        XCTAssertTrue(url.contains("quantity=10"))
        XCTAssertTrue(url.contains("province=NJ"))
        XCTAssertTrue(url.contains("rateCenter=NEWARK"))
        XCTAssertTrue(url.contains("lata=224"))
    }

    func testSearchInventoryFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/inventory", statusCode: 400, json: "{}")
        do {
            _ = try await client.iNumbering.searchInventory(query: InventoryQuery(tnMask: "201"))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testCoverage() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/inventory/coverage",
            json: envelope(#"{"coverage":[{"count":50,"npa":"201","nxx":"555"}]}"#)
        )
        let r = try await client.iNumbering.coverage(query: CoverageQuery(countBy: .npanxx, locState: "NJ"))
        XCTAssertEqual(r.coverage[0].count, 50)

        let url = MockURLProtocol.allRequests().first?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("countBy=npanxx"))
        XCTAssertTrue(url.contains("locState=NJ"))
    }

    func testCoverageFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/inventory/coverage", statusCode: 500, json: "{}")
        do {
            _ = try await client.iNumbering.coverage(query: CoverageQuery(countBy: .state))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testOrder() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/orders",
            json: envelope(#"{"orderId":"ord-1","amountCharged":1.5,"numbersOrdered":["2015550123"]}"#)
        )
        let r = try await client.iNumbering.order(OrderCreateRequest(numbers: [
            OrderNumber(value: "2015550123"),
            OrderNumber(spec: OrderNumberSpec(number: "2125550000", route: 4))
        ]))
        XCTAssertEqual(r.orderId, "ord-1")

        // Verify body encoded as mixed strings and objects.
        let raw = MockURLProtocol.capturedBody(method: "POST", path: "/v2.2/orders")!
        let json = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
        let arr = json["numbers"] as! [Any]
        XCTAssertEqual(arr[0] as? String, "2015550123")
        XCTAssertEqual((arr[1] as? [String: Any])?["number"] as? String, "2125550000")
    }

    func testOrderFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/orders", statusCode: 409, json: "{}")
        do {
            _ = try await client.iNumbering.order(OrderCreateRequest(numbers: []))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .conflict)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testPortsList() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/ports",
            json: envelope(#"{"ports":[{"status":"PENDING","id":"123","pid":"ABCDE"}]}"#)
        )
        let r = try await client.iNumbering.ports()
        XCTAssertEqual(r.ports[0].pid, "ABCDE")
    }

    func testPortsListFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/ports", statusCode: 500, json: "{}")
        do {
            _ = try await client.iNumbering.ports()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testPortDetail() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/ports/y0d36",
            json: envelope(#"{"port":{"status":"PENDING","id":"8654d228","pid":"y0d36","numbers":["2015550123"]}}"#)
        )
        let r = try await client.iNumbering.port(id: "y0d36")
        XCTAssertEqual(r.port.numbers, ["2015550123"])
    }

    func testPortDetailFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/ports/y0d36", statusCode: 404, json: "{}")
        do {
            _ = try await client.iNumbering.port(id: "y0d36")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testSubmitPort() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/ports",
            json: envelope(#"{"pid":"ABCDE","ticket":1234,"message":"submitted","loaUrl":"https://x","portUrl":"https://x/p"}"#)
        )
        let req = PortSubmitRequest(
            did: ["2015550123"], name: "Alice", nameType: "residential",
            lcBtn: "2015550000", lcAccountNumber: "ACC", streetNumber: "1",
            street: "Main", streetType: "ST", city: "Newark", state: "NJ",
            zip: "07101", country: "US", authPerson: "Alice"
        )
        let r = try await client.iNumbering.submitPort(req)
        XCTAssertEqual(r.pid, "ABCDE")
        XCTAssertEqual(r.ticket, 1234)
    }

    func testSubmitPortFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/ports", statusCode: 400, json: "{}")
        let req = PortSubmitRequest(
            did: [], name: "", nameType: "", lcBtn: "", lcAccountNumber: "",
            streetNumber: "", street: "", streetType: "", city: "",
            state: "", zip: "", country: "", authPerson: ""
        )
        do {
            _ = try await client.iNumbering.submitPort(req)
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testPortAvailabilityIncludesV2210Fields() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/ports/availability/2015550123",
            json: envelope("""
            {"number":"2015550123","portable":true,"losingCarrier":"Acme","localRoutingNumber":"2015550001","rateCenterTier":"tier1","reason":null}
            """)
        )
        let r = try await client.iNumbering.portAvailability(number: "2015550123")
        XCTAssertTrue(r.portable)
        XCTAssertEqual(r.localRoutingNumber, "2015550001")
        XCTAssertEqual(r.rateCenterTier, "tier1")
        XCTAssertNil(r.reason)
    }

    func testPortAvailabilityFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/ports/availability/x", statusCode: 404, json: "{}")
        do {
            _ = try await client.iNumbering.portAvailability(number: "x")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testOrderNumberRoundTrip() throws {
        let plain = OrderNumber(value: "2015550123")
        let raw = try JSONEncoder().encode(plain)
        let str = String(data: raw, encoding: .utf8)
        XCTAssertEqual(str, "\"2015550123\"")

        let spec = OrderNumber(spec: OrderNumberSpec(number: "2015550123", route: 4))
        let raw2 = try JSONEncoder().encode(spec)
        let obj = try JSONSerialization.jsonObject(with: raw2) as? [String: Any]
        XCTAssertEqual(obj?["number"] as? String, "2015550123")
        XCTAssertEqual(obj?["route"] as? Int, 4)
    }
}
