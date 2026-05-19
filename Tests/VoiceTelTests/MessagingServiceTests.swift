//
//  MessagingServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class MessagingServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testHistory() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/messages",
            json: envelope("""
            {"number":"2015551234","type":"sms","fromTs":1,"toTs":2,"messages":[{"id":"m1","key":["alice",1700000000],"value":{"sourceNumber":"2015551234","destinationNumber":"2125550000","direction":"out","message":"hi"}}]}
            """)
        )
        let r = try await client.messaging.history(options: HistoryOptions(number: "2015551234", type: "sms"))
        XCTAssertEqual(r.messages.count, 1)
        XCTAssertEqual(r.messages[0].value.direction, "out")

        if case .int(let i) = r.messages[0].key[1] {
            XCTAssertEqual(i, 1700000000)
        } else {
            XCTFail("expected int in key[1]")
        }
        if case .string(let s) = r.messages[0].key[0] {
            XCTAssertEqual(s, "alice")
        } else {
            XCTFail("expected string in key[0]")
        }
    }

    func testHistoryFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/messages", statusCode: 500, json: "{}")
        do {
            _ = try await client.messaging.history()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testSend() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/messages",
            json: envelope(#"{"id":"prov-1","type":"sms","fromNumber":"2015551234","toNumber":"2125550000","parts":1}"#)
        )
        let r = try await client.messaging.send(MessageSendRequest(
            fromNumber: "2015551234", toNumber: "2125550000", text: "hi"
        ))
        XCTAssertEqual(r.id, "prov-1")
        XCTAssertEqual(r.parts, 1)

        // Verify wire-field names fromNumber/toNumber are preserved.
        let dict = bodyDict(MockURLProtocol.capturedBody(method: "POST", path: "/v2.2/messages"))
        XCTAssertEqual(dict["fromNumber"] as? String, "2015551234")
        XCTAssertEqual(dict["toNumber"] as? String, "2125550000")
        XCTAssertEqual(dict["text"] as? String, "hi")
    }

    func testSendFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/messages", statusCode: 400, json: #"{"message":"bad number"}"#)
        do {
            _ = try await client.messaging.send(MessageSendRequest(fromNumber: "x", toNumber: "y", text: "z"))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .badRequest)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testCreateBrand() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/messaging/brands",
            json: envelope(#"{"result":{"statusCode":"200","status":"Success"}}"#)
        )
        let r = try await client.messaging.createBrand(MessagingBrandCreateRequest(
            messagingBrandId: "B12345", messagingBrandName: "Test"
        ))
        XCTAssertEqual(r.result.status, "Success")
    }

    func testCreateBrandFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/messaging/brands", statusCode: 400, json: "{}")
        do {
            _ = try await client.messaging.createBrand(MessagingBrandCreateRequest(
                messagingBrandId: "x", messagingBrandName: "y"
            ))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testCampaignStatus() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/messaging/campaigns",
            json: envelope(#"{"campaigns":[{"id":"C12345A","status":"ACTIVE","numbers":["2015551234"]}]}"#)
        )
        let r = try await client.messaging.campaignStatus()
        XCTAssertEqual(r.campaigns[0].status, "ACTIVE")
    }

    func testCampaignStatusFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/messaging/campaigns", statusCode: 500, json: "{}")
        do {
            _ = try await client.messaging.campaignStatus()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testCreateCampaign() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/messaging/campaigns",
            json: envelope(#"{"result":{"statusCode":"200","status":"Success"}}"#)
        )
        let r = try await client.messaging.createCampaign(MessagingCampaignCreateRequest(
            messagingBrandId: "B1", externalCampaignId: "ext-1", campaignDescription: "test"
        ))
        XCTAssertEqual(r.result.status, "Success")
    }

    func testCreateCampaignFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/messaging/campaigns", statusCode: 400, json: "{}")
        do {
            _ = try await client.messaging.createCampaign(MessagingCampaignCreateRequest(
                messagingBrandId: "x", externalCampaignId: "y", campaignDescription: "z"
            ))
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testNumbersStateAll() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/numbers/messaging",
            json: envelope(#"{"numbers":[{"number":"2015551234","enabled":true,"carrier":17,"routeIn":1,"resource":"w","network":"A"}]}"#)
        )
        let r = try await client.messaging.numbersState()
        XCTAssertEqual(r.numbers[0].number, "2015551234")

        // No query string when numbers is empty.
        let url = MockURLProtocol.allRequests().first?.url?.absoluteString ?? ""
        XCTAssertFalse(url.contains("?numbers="))
    }

    func testNumbersStateFiltered() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/numbers/messaging",
            json: envelope(#"{"numbers":[]}"#)
        )
        _ = try await client.messaging.numbersState(numbers: ["2015551234", "2125550000"])
        let url = MockURLProtocol.allRequests().first?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("numbers=2015551234,2125550000") || url.contains("numbers=2015551234%2C2125550000"))
    }

    func testNumbersStateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/numbers/messaging", statusCode: 500, json: "{}")
        do {
            _ = try await client.messaging.numbersState()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }
}
