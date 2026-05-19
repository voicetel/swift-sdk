//
//  ClientTests.swift
//  VoiceTelTests
//

import XCTest
@testable import VoiceTel

final class ClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    func testDefaultsAreSane() {
        let c = VoiceTelClient()
        XCTAssertEqual(c.baseURL, VoiceTel.defaultBaseURL)
        XCTAssertNil(c.apiKey)
    }

    func testBaseURLTrailingSlashTrimmed() {
        let c = VoiceTelClient(baseURL: "https://api.example.com/")
        XCTAssertEqual(c.baseURL, "https://api.example.com")
    }

    func testSetAPIKey() {
        let c = makeTestClient(apiKey: nil)
        XCTAssertNil(c.apiKey)
        c.setAPIKey("hex000")
        XCTAssertEqual(c.apiKey, "hex000")
        c.setAPIKey(nil)
        XCTAssertNil(c.apiKey)
    }

    func testLoginInstallsKeyAndStripsEnvelope() async throws {
        let client = makeTestClient(apiKey: nil)
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/account/api-key",
            json: envelope(#"{"apikey":"abcdef1234567890"}"#)
        )
        let key = try await client.login(username: "1000000001", password: "hunter2")
        XCTAssertEqual(key, "abcdef1234567890")
        XCTAssertEqual(client.apiKey, "abcdef1234567890")

        let body = bodyDict(MockURLProtocol.capturedBody(method: "POST", path: "/v2.2/account/api-key"))
        XCTAssertEqual(body["username"] as? String, "1000000001")
        XCTAssertEqual(body["password"] as? String, "hunter2")
    }

    func testLoginFailureSurfacesAPIError() async {
        let client = makeTestClient(apiKey: nil)
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/account/api-key",
            statusCode: 401,
            json: #"{"code":"invalid_credentials","message":"bad password"}"#
        )
        do {
            _ = try await client.login(username: "1000000001", password: "wrong")
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .authentication)
            XCTAssertEqual(error.statusCode, 401)
            XCTAssertEqual(error.code, "invalid_credentials")
            XCTAssertEqual(error.message, "bad password")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testLoginEmptyKeyRejected() async {
        let client = makeTestClient(apiKey: nil)
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/account/api-key",
            json: envelope(#"{"apikey":""}"#)
        )
        do {
            _ = try await client.login(username: "u", password: "p")
            XCTFail("expected error for empty apikey")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .authentication)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testMissingAPIKeyShortCircuitsAuthCalls() async {
        let client = makeTestClient(apiKey: nil)
        do {
            _ = try await client.account.get()
            XCTFail("expected authentication error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .authentication)
            XCTAssertEqual(error.statusCode, 0)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testEnvelopeStrippingFallbackToRawBody() async throws {
        // Response without status/data envelope is decoded directly.
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/cnam/2015551234",
            json: #"{"cnam":"PIZZA HUT","number":"2015551234"}"#
        )
        let result = try await client.lookups.cnam(number: "2015551234")
        XCTAssertEqual(result.cnam, "PIZZA HUT")
        XCTAssertEqual(result.number, "2015551234")
    }

    func testRetryOn429ThenSuccess() async throws {
        let client = makeTestClient(maxRetries: 2)
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account",
            statusCode: 429,
            json: #"{"message":"too many"}"#,
            headers: ["Retry-After": "0"]
        )
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account",
            json: envelope(#"{"username":"alice","cash":12.5}"#)
        )
        let me = try await client.account.get()
        XCTAssertEqual(me.username, "alice")
        XCTAssertEqual(me.cash, 12.5)
        XCTAssertEqual(MockURLProtocol.allRequests().count, 2)
    }

    func testRetryOn5xxThenSuccess() async throws {
        let client = makeTestClient(maxRetries: 1)
        MockURLProtocol.enqueue(method: "GET", path: "/v2.2/account", statusCode: 503, body: Data())
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/account",
            json: envelope(#"{"username":"bob"}"#)
        )
        let me = try await client.account.get()
        XCTAssertEqual(me.username, "bob")
    }

    func testRetryExhaustedBubblesError() async {
        let client = makeTestClient(maxRetries: 1)
        for _ in 0..<3 {
            MockURLProtocol.enqueueJSON(
                method: "GET",
                path: "/v2.2/account",
                statusCode: 500,
                json: #"{"message":"boom"}"#
            )
        }
        do {
            _ = try await client.account.get()
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .server)
            XCTAssertEqual(error.statusCode, 500)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testAPIErrorKindMapping() {
        XCTAssertEqual(APIError.kindFromStatus(400), .badRequest)
        XCTAssertEqual(APIError.kindFromStatus(401), .authentication)
        XCTAssertEqual(APIError.kindFromStatus(403), .permissionDenied)
        XCTAssertEqual(APIError.kindFromStatus(404), .notFound)
        XCTAssertEqual(APIError.kindFromStatus(409), .conflict)
        XCTAssertEqual(APIError.kindFromStatus(429), .rateLimit)
        XCTAssertEqual(APIError.kindFromStatus(500), .server)
        XCTAssertEqual(APIError.kindFromStatus(599), .server)
        XCTAssertEqual(APIError.kindFromStatus(418), .unknown)
    }

    func testAPIErrorHelpers() {
        let rl = APIError(kind: .rateLimit, statusCode: 429, message: "x")
        XCTAssertTrue(APIError.isRateLimit(rl))
        XCTAssertFalse(APIError.isNotFound(rl))
        XCTAssertFalse(APIError.isNotFound(NSError(domain: "x", code: 1)))
        XCTAssertTrue(APIError.isNotFound(APIError(kind: .notFound, message: "x")))
        XCTAssertTrue(APIError.isAuthentication(APIError(kind: .authentication, message: "x")))
        XCTAssertTrue(APIError.isConflict(APIError(kind: .conflict, message: "x")))
    }

    func testAPIErrorDescriptionFormats() {
        XCTAssertEqual(
            APIError(kind: .server, statusCode: 500, code: "boom", message: "down").errorDescription,
            "voicetel: HTTP 500 boom: down"
        )
        XCTAssertEqual(
            APIError(kind: .server, statusCode: 500, message: "down").errorDescription,
            "voicetel: HTTP 500: down"
        )
        XCTAssertEqual(
            APIError(kind: .unknown, statusCode: 0, message: "no key").errorDescription,
            "voicetel: no key"
        )
    }

    func testVersionConstants() {
        XCTAssertEqual(VoiceTel.sdkVersion, "2.2.10")
        XCTAssertEqual(VoiceTel.apiVersion, "v2.2.10")
        XCTAssertEqual(VoiceTel.defaultBaseURL, "https://api.voicetel.com")
        XCTAssertTrue(VoiceTel.defaultUserAgent.contains("voicetel-swift/"))
    }

    func testErrorBodyParsedJSON() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/numbers/9999999999",
            statusCode: 404,
            json: #"{"error":"not_found","message":"no such number"}"#
        )
        do {
            _ = try await client.numbers.get(number: "9999999999")
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .notFound)
            XCTAssertEqual(error.statusCode, 404)
            XCTAssertEqual(error.code, "not_found")
            XCTAssertEqual(error.message, "no such number")
            XCTAssertNotNil(error.body)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testErrorBodyNonJSON() async {
        let client = makeTestClient()
        MockURLProtocol.enqueue(
            method: "GET",
            path: "/v2.2/numbers/abc",
            statusCode: 500,
            body: Data("upstream went sideways".utf8)
        )
        do {
            _ = try await client.numbers.get(number: "abc")
            XCTFail("expected error")
        } catch let error as APIError {
            XCTAssertEqual(error.kind, .server)
            XCTAssertEqual(error.statusCode, 500)
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }
}
