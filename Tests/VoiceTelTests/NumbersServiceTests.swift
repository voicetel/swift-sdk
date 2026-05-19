//
//  NumbersServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class NumbersServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    // Helper to register a numbers happy-path response.
    private func registerDetail(method: String, path: String, number: String = "2015551234") {
        MockURLProtocol.enqueueJSON(
            method: method,
            path: path,
            json: envelope("""
            {"number":"\(number)","translated":"\(number)","route":4,"gateway":null,"cnam":false,"forward":false,"forwardTo":null,"carrier":0,"smsEnabled":false,"faxEnabled":false}
            """)
        )
    }

    func testList() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/numbers",
            json: envelope(#"{"numbers":[{"number":"2015551234","translated":"2015551234","route":4,"gateway":null,"cnam":false,"forward":false,"forwardTo":null,"carrier":0,"smsEnabled":false,"faxEnabled":false}]}"#)
        )
        let r = try await client.numbers.list()
        XCTAssertEqual(r.numbers[0].number, "2015551234")
    }

    func testListFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers", statusCode: 500, json: "{}")
        do { _ = try await client.numbers.list(); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testAdd() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/numbers", json: envelope(#"{"number":"2015551234","route":4}"#))
        let r = try await client.numbers.add(NumberAddRequest(number: "2015551234"))
        XCTAssertEqual(r.number, "2015551234")
    }

    func testAddFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/numbers", statusCode: 409, json: "{}")
        do { _ = try await client.numbers.add(NumberAddRequest(number: "x")); XCTFail("expected") } catch let e as APIError { XCTAssertEqual(e.kind, .conflict) } catch { XCTFail("unexpected: \(error)") }
    }

    func testGet() async throws {
        let client = makeTestClient()
        registerDetail(method: "GET", path: "/v2.2/numbers/2015551234")
        let r = try await client.numbers.get(number: "2015551234")
        XCTAssertEqual(r.number, "2015551234")
        XCTAssertEqual(r.route, 4)
    }

    func testGetFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/x", statusCode: 404, json: "{}")
        do { _ = try await client.numbers.get(number: "x"); XCTFail("expected") } catch let e as APIError { XCTAssertEqual(e.kind, .notFound) } catch { XCTFail("unexpected: \(error)") }
    }

    func testRemove204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/numbers/2015551234", statusCode: 204, body: Data())
        try await client.numbers.remove(number: "2015551234")
    }

    func testRemoveFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/x", statusCode: 404, json: "{}")
        do { try await client.numbers.remove(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testMove() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PATCH", path: "/v2.2/numbers/2015551234",
            json: envelope(#"{"number":"2015551234","accountId":99,"route":4}"#))
        let r = try await client.numbers.move(number: "2015551234", body: NumberMoveRequest(accountId: 99, route: 4))
        XCTAssertEqual(r.accountId, 99)
    }

    func testMoveFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PATCH", path: "/v2.2/numbers/x", statusCode: 403, json: "{}")
        do { _ = try await client.numbers.move(number: "x", body: NumberMoveRequest(accountId: 1, route: 1)); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRelease204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "POST", path: "/v2.2/numbers/2015551234/release", statusCode: 204, body: Data())
        try await client.numbers.release(number: "2015551234")
    }

    func testReleaseFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/numbers/x/release", statusCode: 404, json: "{}")
        do { try await client.numbers.release(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetRoute() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/route",
            json: envelope(#"{"number":"2015551234","route":4}"#))
        let r = try await client.numbers.setRoute(number: "2015551234", body: NumberRouteRequest(route: 4))
        XCTAssertEqual(r.route, 4)
    }

    func testSetRouteFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/route", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setRoute(number: "x", body: NumberRouteRequest(route: 0)); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetTranslation() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/translation",
            json: envelope(#"{"number":"2015551234","translation":"123"}"#))
        let r = try await client.numbers.setTranslation(number: "2015551234", body: NumberTranslationRequest(translation: "123"))
        XCTAssertEqual(r.translation, "123")
    }

    func testSetTranslationFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/translation", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setTranslation(number: "x", body: NumberTranslationRequest(translation: "x")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetCnam() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/cnam",
            json: envelope(#"{"number":"2015551234","cnam":true}"#))
        let r = try await client.numbers.setCnam(number: "2015551234", body: NumberCnamRequest(enabled: true))
        XCTAssertTrue(r.cnam)
    }

    func testSetCnamFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/cnam", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setCnam(number: "x", body: NumberCnamRequest(enabled: false)); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetLidb() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/lidb",
            json: envelope(#"{"number":"2015551234","cnam":"ALICE","customerOrderReference":"ref-1","carrierStatus":"Success"}"#))
        let r = try await client.numbers.setLidb(number: "2015551234", body: NumberLidbRequest(cnam: "ALICE"))
        XCTAssertEqual(r.cnam, "ALICE")
        XCTAssertEqual(r.carrierStatus, "Success")
    }

    func testSetLidbFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/lidb", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setLidb(number: "x", body: NumberLidbRequest(cnam: "")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testGetFax() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/2015551234/fax",
            json: envelope(#"{"number":"2015551234","email":"f@x"}"#))
        let r = try await client.numbers.getFax(number: "2015551234")
        XCTAssertEqual(r.email, "f@x")
    }

    func testGetFaxFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/x/fax", statusCode: 404, json: "{}")
        do { _ = try await client.numbers.getFax(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetFax() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/fax",
            json: envelope(#"{"number":"2015551234","email":"f@x"}"#))
        let r = try await client.numbers.setFax(number: "2015551234", body: NumberFaxRequest(email: "f@x"))
        XCTAssertEqual(r.email, "f@x")
    }

    func testSetFaxFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/fax", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setFax(number: "x", body: NumberFaxRequest(email: "")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRemoveFax204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/numbers/2015551234/fax", statusCode: 204, body: Data())
        try await client.numbers.removeFax(number: "2015551234")
    }

    func testRemoveFaxFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/x/fax", statusCode: 404, json: "{}")
        do { try await client.numbers.removeFax(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetForward() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/forward",
            json: envelope(#"{"number":"2015551234","forwardTo":"2125550000"}"#))
        let r = try await client.numbers.setForward(number: "2015551234", body: NumberForwardRequest(destination: "2125550000"))
        XCTAssertEqual(r.forwardTo, "2125550000")
    }

    func testSetForwardFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/forward", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setForward(number: "x", body: NumberForwardRequest(destination: "0")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRemoveForward204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/numbers/2015551234/forward", statusCode: 204, body: Data())
        try await client.numbers.removeForward(number: "2015551234")
    }

    func testRemoveForwardFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/x/forward", statusCode: 404, json: "{}")
        do { try await client.numbers.removeForward(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testGetSms() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/2015551234/sms",
            json: envelope(#"{"number":"2015551234","type":"webhook","resource":"https://x"}"#))
        let r = try await client.numbers.getSms(number: "2015551234")
        XCTAssertEqual(r.type, "webhook")
    }

    func testGetSmsFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/x/sms", statusCode: 404, json: "{}")
        do { _ = try await client.numbers.getSms(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetSms() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/sms",
            json: envelope(#"{"number":"2015551234","type":"webhook","resource":"https://x"}"#))
        let r = try await client.numbers.setSms(number: "2015551234", body: NumberSmsRequest(type: "webhook", resource: "https://x"))
        XCTAssertEqual(r.resource, "https://x")
    }

    func testSetSmsFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/sms", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setSms(number: "x", body: NumberSmsRequest(type: "", resource: "")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRemoveSms204() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueue(method: "DELETE", path: "/v2.2/numbers/2015551234/sms", statusCode: 204, body: Data())
        try await client.numbers.removeSms(number: "2015551234")
    }

    func testRemoveSmsFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/x/sms", statusCode: 404, json: "{}")
        do { try await client.numbers.removeSms(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testGetMessaging() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/2015551234/messaging",
            json: envelope(#"{"number":"2015551234","enabled":true,"carrier":17,"routeIn":1,"resource":"w","network":"A","campaign":null}"#))
        let r = try await client.numbers.getMessaging(number: "2015551234")
        XCTAssertEqual(r.network, "A")
    }

    func testGetMessagingFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/x/messaging", statusCode: 404, json: "{}")
        do { _ = try await client.numbers.getMessaging(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testPatchMessaging() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PATCH", path: "/v2.2/numbers/2015551234/messaging",
            json: envelope(#"{"number":"2015551234","updated":["routeIn"]}"#))
        let r = try await client.numbers.patchMessaging(number: "2015551234", body: NumberMessagingPatchRequest(routeIn: 2))
        XCTAssertEqual(r.updated, ["routeIn"])
    }

    func testPatchMessagingFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PATCH", path: "/v2.2/numbers/x/messaging", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.patchMessaging(number: "x", body: NumberMessagingPatchRequest()); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testAssignCampaign() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/2015551234/messaging-campaign",
            json: envelope(#"{"number":"2015551234","campaignId":"CAMP123","carrier":17,"network":"A","upstreamCnpId":"SFL9UTQ","previousNetwork":null,"previousNetworkCleared":false}"#))
        let r = try await client.numbers.assignCampaign(number: "2015551234", body: NumberCampaignAssignRequest(campaignId: "CAMP123"))
        XCTAssertEqual(r.network, "A")
    }

    func testAssignCampaignFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PUT", path: "/v2.2/numbers/x/messaging-campaign", statusCode: 409, json: "{}")
        do { _ = try await client.numbers.assignCampaign(number: "x", body: NumberCampaignAssignRequest(campaignId: "y")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testUnassignCampaign() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/2015551234/messaging-campaign",
            json: envelope(#"{"number":"2015551234","campaignId":"CAMP123","network":"A","upstreamCnpId":"SFL9UTQ","unassigned":true}"#))
        let r = try await client.numbers.unassignCampaign(number: "2015551234")
        XCTAssertTrue(r.unassigned)
    }

    func testUnassignCampaignFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/x/messaging-campaign", statusCode: 404, json: "{}")
        do { _ = try await client.numbers.unassignCampaign(number: "x"); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testBulkUnassignCampaign() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/messaging-campaign",
            json: envelope(#"{"campaignId":"CAMP123","network":"A","upstreamCnpId":"SFL9UTQ","unassignedNumbers":["2015551234"]}"#))
        let r = try await client.numbers.bulkUnassignCampaign(numbers: ["2015551234"])
        XCTAssertEqual(r.unassignedNumbers, ["2015551234"])
    }

    func testBulkUnassignCampaignFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "DELETE", path: "/v2.2/numbers/messaging-campaign", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.bulkUnassignCampaign(numbers: []); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSetPortOutPin() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PATCH", path: "/v2.2/numbers/2015551234/port-out-pin",
            json: envelope(#"{"number":"2015551234","portOutPin":"1234"}"#))
        let r = try await client.numbers.setPortOutPin(number: "2015551234", body: PortOutPinUpdateRequest(pin: "1234"))
        XCTAssertEqual(r.portOutPin, "1234")
    }

    func testSetPortOutPinFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "PATCH", path: "/v2.2/numbers/x/port-out-pin", statusCode: 400, json: "{}")
        do { _ = try await client.numbers.setPortOutPin(number: "x", body: PortOutPinUpdateRequest(pin: "")); XCTFail("expected") } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }
}
