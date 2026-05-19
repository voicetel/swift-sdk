//
//  AccountServiceTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class AccountServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testGet() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account",
            json: envelope("""
            {"username":"alice","name":"Alice","email":"a@b.c","cash":42.0,"rates":{"sms":0.005}}
            """)
        )
        let me = try await client.account.get()
        XCTAssertEqual(me.username, "alice")
        XCTAssertEqual(me.rates?.sms, 0.005)
    }

    func testGetFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account",
            statusCode: 500,
            json: #"{"message":"db down"}"#
        )
        do {
            _ = try await client.account.get()
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .server)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testUpdate() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/account",
            json: envelope(#"{"updated":["timezone","callerId"]}"#)
        )
        let body = AccountPutRequest(
            notify: true,
            notifyThreshold: 5,
            timezone: "America/Chicago",
            callerId: "2015551234"
        )
        let resp = try await client.account.update(body)
        XCTAssertEqual(resp.updated, ["timezone", "callerId"])

        let dict = bodyDict(MockURLProtocol.capturedBody(method: "PUT", path: "/v2.2/account"))
        XCTAssertEqual(dict["notify"] as? Bool, true)
        XCTAssertEqual(dict["notifyThreshold"] as? Int, 5)
    }

    func testUpdateFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "PUT",
            path: "/v2.2/account",
            statusCode: 400,
            json: #"{"code":"bad_field","message":"invalid timezone"}"#
        )
        do {
            _ = try await client.account.update(AccountPutRequest(timezone: "nope"))
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .badRequest)
            XCTAssertEqual(error.code, "bad_field")
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testAdd() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/account",
            json: envelope(#"{"username":"1000000002","password":"genpw","email":"x@y.z"}"#)
        )
        let resp = try await client.account.add(AccountAddRequest(username: 1000000002, name: "Sub", email: "x@y.z"))
        XCTAssertEqual(resp.username, "1000000002")
        XCTAssertEqual(resp.password, "genpw")
    }

    func testAddFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/account",
            statusCode: 403,
            json: #"{"message":"not admin"}"#
        )
        do {
            _ = try await client.account.add(AccountAddRequest(username: 1, name: "n", email: "e"))
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .permissionDenied)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testSignup() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/accounts",
            json: envelope(#"{"username":"1000000003","password":"genpw","name":"N","email":"e@e.e"}"#)
        )
        let resp = try await client.account.signup(AccountSignupRequest(name: "N", email: "e@e.e"))
        XCTAssertEqual(resp.username, "1000000003")
    }

    func testSignupFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/accounts",
            statusCode: 409,
            json: #"{"message":"email already in use"}"#
        )
        do {
            _ = try await client.account.signup(AccountSignupRequest(name: "n", email: "e"))
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .conflict)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testCDR() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account/cdr",
            json: envelope("""
            {"cdr":[{"id":"x","key":["alice","1700000000"],"value":{"dur":"10","dst":"2125551234","ba":"0.01"}}],"start":1700000000,"end":1700000100}
            """)
        )
        let resp = try await client.account.cdr(start: 1700000000, end: 1700000100)
        XCTAssertEqual(resp.cdr.count, 1)
        XCTAssertEqual(resp.cdr[0].value.dur, "10")
        XCTAssertEqual(resp.start, 1700000000)
    }

    func testCDRFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account/cdr",
            statusCode: 429,
            json: #"{"message":"slow down"}"#
        )
        do {
            _ = try await client.account.cdr()
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .rateLimit)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testCredits() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account/credits",
            json: envelope(#"{"credits":[{"date":"2025-01-01","paid":true,"amount":100.0}]}"#)
        )
        let resp = try await client.account.credits()
        XCTAssertEqual(resp.credits.count, 1)
    }

    func testCreditsFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/account/credits", statusCode: 500, json: "{}")
        do {
            _ = try await client.account.credits()
            XCTFail("expected")
        } catch is APIError {
            // ok
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testRecurringCharges() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account/recurring-charges",
            json: envelope(#"{"charges":[{"amount":3.99,"description":"DID"}],"total":3.99}"#)
        )
        let resp = try await client.account.recurringCharges()
        XCTAssertEqual(resp.total, 3.99)
    }

    func testRecurringChargesFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/account/recurring-charges", statusCode: 429, json: "{}")
        do {
            _ = try await client.account.recurringCharges()
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .rateLimit)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testPayments() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account/payments",
            json: envelope(#"{"payments":[{"date":"2025-01-01","status":"Completed","amount":50.0}]}"#)
        )
        let resp = try await client.account.payments()
        XCTAssertEqual(resp.payments[0].status, "Completed")
    }

    func testPaymentsFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/account/payments", statusCode: 500, json: "{}")
        do {
            _ = try await client.account.payments()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRegistration() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account/registration",
            json: envelope(#"{"agent":"PJSIP","uri":"sip:alice@1.2.3.4","expires":3600}"#)
        )
        let resp = try await client.account.registration()
        XCTAssertEqual(resp.agent, "PJSIP")
        XCTAssertEqual(resp.expires, 3600)
    }

    func testRegistrationFailure() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(method: "GET", path: "/v2.2/account/registration", statusCode: 500, json: "{}")
        do {
            _ = try await client.account.registration()
            XCTFail("expected")
        } catch is APIError {} catch { XCTFail("unexpected: \(error)") }
    }

    func testRecover() async throws {
        let client = makeTestClient(apiKey: nil)
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/account/recovery",
            json: envelope(#"{"message":"check email"}"#)
        )
        let resp = try await client.account.recover(AccountRecoverRequest(email: "lost@x.com"))
        XCTAssertEqual(resp.message, "check email")
    }

    func testRecoverFailure() async {
        let client = makeTestClient(apiKey: nil)
        MockURLProtocol.enqueueJSON(method: "POST", path: "/v2.2/account/recovery", statusCode: 404, json: #"{"message":"no such email"}"#)
        do {
            _ = try await client.account.recover(AccountRecoverRequest(email: "x"))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }
}
