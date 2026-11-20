//
//  FaxServiceTests.swift
//  VoiceTelTests
//
//  Wire-shape tests for the Fax tag (spec v2.2.21).
//

import XCTest
@testable import VoiceTel

final class FaxServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    /// Minimal PDF-ish payload with a magic byte prefix and embedded NULs so a
    /// lossy (text-mode) transport would corrupt it.
    static let pdfBytes = Data([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37, 0x0A, 0x00, 0x01, 0x02])

    private func uuidPatternOK(_ s: String?) -> Bool {
        guard let s = s else { return false }
        return s.range(of: #"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$"#, options: .regularExpression) != nil
    }

    private func capturedHeader(_ name: String) -> String? {
        MockURLProtocol.allRequests().first?.value(forHTTPHeaderField: name)
    }

    func testNumbers() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/numbers/fax",
            json: envelope(#"{"numbers":[{"number":"2015550123","destinationId":7,"email":"fax@example.com"}]}"#)
        )
        let resp = try await client.fax.numbers()
        XCTAssertEqual(resp.numbers[0].number, "2015550123")
        XCTAssertEqual(resp.numbers[0].destinationId, 7)
        XCTAssertEqual(resp.numbers[0].email, "fax@example.com")
    }

    func testSendBuildsMultipartWithUUIDIdempotencyKey() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/faxes",
            statusCode: 201,
            json: envelope(#"{"id":"9f8c2b41a","fromNumber":"2015550123","toNumber":"2125550123","status":"queued","documents":[{"name":"contract.pdf","size":123456,"contentType":"application/pdf"}]}"#)
        )
        let resp = try await client.fax.send(FaxSendRequest(
            fromNumber: "2015550123",
            toNumber: "2125550123",
            documents: [FaxDocumentUpload(name: "contract.pdf", contentType: "application/pdf", data: Self.pdfBytes)]
        ))
        XCTAssertEqual(resp.id, "9f8c2b41a")
        XCTAssertEqual(resp.status, "queued")
        XCTAssertEqual(resp.documents?.first?.name, "contract.pdf")

        // Header shape: multipart content type + UUID Idempotency-Key.
        let contentType = capturedHeader("Content-Type")
        XCTAssertTrue(contentType?.hasPrefix("multipart/form-data; boundary=") == true, "got \(contentType ?? "nil")")
        XCTAssertTrue(uuidPatternOK(capturedHeader("Idempotency-Key")))

        // Body shape: both text fields, the file part with filename +
        // content type + raw bytes, and the closing boundary.
        let body = try XCTUnwrap(MockURLProtocol.capturedBody(method: "POST", path: "/v2.2/faxes"))
        let boundary = try XCTUnwrap(contentType?.components(separatedBy: "boundary=").last)
        let bodyString = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"fromNumber\"\r\n\r\n2015550123\r\n"))
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"toNumber\"\r\n\r\n2125550123\r\n"))
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"documents\"; filename=\"contract.pdf\"\r\n"))
        XCTAssertTrue(bodyString.contains("Content-Type: application/pdf\r\n\r\n"))
        XCTAssertNotNil(body.range(of: Self.pdfBytes))
        XCTAssertTrue(bodyString.hasSuffix("--\(boundary)--\r\n"))
    }

    func testSendHonorsCallerSuppliedIdempotencyKey() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/faxes",
            statusCode: 201,
            json: envelope(#"{"id":"x","fromNumber":"2015550123","toNumber":"2125550123","status":"queued"}"#)
        )
        _ = try await client.fax.send(FaxSendRequest(
            fromNumber: "2015550123",
            toNumber: "2125550123",
            documents: [FaxDocumentUpload(name: "a.doc", contentType: "application/msword", data: Data([0xD0, 0xCF, 0x11, 0xE0]))],
            idempotencyKey: "123e4567-e89b-12d3-a456-426614174000"
        ))
        XCTAssertEqual(capturedHeader("Idempotency-Key"), "123e4567-e89b-12d3-a456-426614174000")
    }

    func testSendRejectsEmptyDocumentsBeforeHittingTheWire() async {
        let client = makeTestClient()
        do {
            _ = try await client.fax.send(FaxSendRequest(fromNumber: "2015550123", toNumber: "2125550123", documents: []))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .badRequest)
        } catch { XCTFail("unexpected: \(error)") }
        XCTAssertTrue(MockURLProtocol.allRequests().isEmpty)
    }

    func testSendErrorEnvelopeCarriesServerTimeTolerantly() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/faxes",
            statusCode: 402,
            json: #"{"status":"error","error":{"code":402,"message":"Your account needs a positive balance to send faxes."},"serverTime":1795100000}"#
        )
        do {
            _ = try await client.fax.send(FaxSendRequest(
                fromNumber: "2015550123",
                toNumber: "2125550123",
                documents: [FaxDocumentUpload(name: "x.pdf", contentType: "application/pdf", data: Self.pdfBytes)]
            ))
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .paymentRequired)
            XCTAssertEqual(e.statusCode, 402)
            XCTAssertEqual(e.message, "Your account needs a positive balance to send faxes.")
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testSendMaps402And413ToTypedKinds() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/faxes",
            statusCode: 402,
            json: #"{"status":"error","error":{"code":402,"message":"Your account needs a positive balance to send faxes."}}"#
        )
        MockURLProtocol.enqueueJSON(
            method: "POST",
            path: "/v2.2/faxes",
            statusCode: 413,
            json: #"{"status":"error","error":{"code":413,"message":"The documents must total 8 MiB or smaller"}}"#
        )
        let request = FaxSendRequest(
            fromNumber: "2015550123",
            toNumber: "2125550123",
            documents: [FaxDocumentUpload(name: "x.pdf", contentType: "application/pdf", data: Self.pdfBytes)]
        )
        do {
            _ = try await client.fax.send(request)
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .paymentRequired)
            XCTAssertEqual(e.statusCode, 402)
        } catch { XCTFail("unexpected: \(error)") }
        do {
            _ = try await client.fax.send(request)
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .requestTooLarge)
            XCTAssertEqual(e.statusCode, 413)
        } catch { XCTFail("unexpected: \(error)") }
    }

    func testHistorySendsExactSpecQueryNames() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/faxes",
            json: envelope(#"{"number":"2015550123","fromTs":1795100000,"toTs":1795013600,"faxes":[{"id":"9f8c2b41a","fromNumber":"2015550123","toNumber":"2125550123","clientToken":"123e4567-e89b-12d3-a456-426614174000","status":"sent","submittedAt":"2026-11-20T15:04:05Z","startedAt":"2026-11-20T15:04:41Z","completedAt":"2026-11-20T15:05:19Z","attempts":1,"failureReason":null,"documents":[{"name":"contract.pdf","size":123456,"contentType":"application/pdf"}],"documentAvailable":true,"documentName":"contract.pdf","documentSize":123456}],"nextCursor":null}"#)
        )
        let resp = try await client.fax.history(FaxHistoryQuery(
            number: "2015550123",
            from: 1795100000,
            to: 1795013600,
            limit: 25,
            cursor: "cur=sor",
            status: "sent"
        ))
        XCTAssertEqual(resp.faxes[0].id, "9f8c2b41a")
        XCTAssertEqual(resp.faxes[0].status, "sent")
        XCTAssertEqual(resp.faxes[0].attempts, 1)
        XCTAssertNil(resp.faxes[0].failureReason)
        XCTAssertNil(resp.nextCursor)

        let comps = URLComponents(url: try XCTUnwrap(MockURLProtocol.allRequests().first?.url), resolvingAgainstBaseURL: false)
        let items = try XCTUnwrap(comps?.queryItems)
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") }),
            [
                "number": "2015550123",
                "from": "1795100000",
                "to": "1795013600",
                "limit": "25",
                "cursor": "cur=sor",
                "status": "sent",
            ]
        )
    }

    func testGet() async throws {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/faxes/9f8c2b41a",
            json: envelope(#"{"id":"9f8c2b41a","fromNumber":"2015550123","toNumber":"2125550123","clientToken":null,"status":"sending","submittedAt":"2026-11-20T15:04:05Z","startedAt":null,"completedAt":null,"attempts":0,"failureReason":null,"documents":[],"documentAvailable":false}"#)
        )
        let job = try await client.fax.get(id: "9f8c2b41a")
        XCTAssertEqual(job.id, "9f8c2b41a")
        XCTAssertEqual(job.status, "sending")
        XCTAssertNil(job.clientToken)
        XCTAssertEqual(job.documentAvailable, false)
    }

    func testDocumentReturnsRawBytes() async throws {
        let client = makeTestClient()
        // Binary body with NULs — must come back byte-for-byte, undecoded.
        MockURLProtocol.enqueue(
            method: "GET",
            path: "/v2.2/faxes/9f8c2b41a/document",
            statusCode: 200,
            headers: [
                "Content-Type": "application/pdf",
                "Content-Disposition": "attachment; filename=\"contract.pdf\"",
            ],
            body: Self.pdfBytes
        )
        let data = try await client.fax.document(id: "9f8c2b41a")
        XCTAssertEqual(data, Self.pdfBytes)
    }

    func testDocumentNotFound() async {
        let client = makeTestClient()
        MockURLProtocol.enqueueJSON(
            method: "GET",
            path: "/v2.2/faxes/nope/document",
            statusCode: 404,
            json: #"{"status":"error","error":{"code":404,"message":"Not found"},"serverTime":1795100000}"#
        )
        do {
            _ = try await client.fax.document(id: "nope")
            XCTFail("expected")
        } catch let e as APIError {
            XCTAssertEqual(e.kind, .notFound)
            XCTAssertEqual(e.message, "Not found")
        } catch { XCTFail("unexpected: \(error)") }
    }
}
