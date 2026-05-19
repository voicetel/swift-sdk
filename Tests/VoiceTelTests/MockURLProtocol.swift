//
//  MockURLProtocol.swift
//  VoiceTelTests
//
//  Standard URLProtocol-based mock — let tests configure stubs, assert on
//  what was sent, and replay queued responses for retry tests.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class MockURLProtocol: URLProtocol {

    /// Stub for a single request.
    struct Stub {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    // MARK: - State (lock-protected; accessed from URLSession's worker queue + tests)

    private static let lock = NSLock()
    private static var stubsQueue: [String: [Stub]] = [:]
    private static var requestLog: [URLRequest] = []
    private static var capturedBodies: [String: [Data]] = [:]

    static func reset() {
        lock.lock()
        stubsQueue.removeAll()
        requestLog.removeAll()
        capturedBodies.removeAll()
        lock.unlock()
    }

    static func enqueue(method: String, path: String, statusCode: Int = 200, headers: [String: String] = [:], body: Data = Data()) {
        let key = "\(method) \(path)"
        lock.lock()
        var existing = stubsQueue[key, default: []]
        existing.append(Stub(statusCode: statusCode, headers: headers, body: body))
        stubsQueue[key] = existing
        lock.unlock()
    }

    static func enqueueJSON(method: String, path: String, statusCode: Int = 200, json: String, headers: [String: String] = [:]) {
        var hdr = headers
        if hdr["Content-Type"] == nil {
            hdr["Content-Type"] = "application/json"
        }
        enqueue(method: method, path: path, statusCode: statusCode, headers: hdr, body: Data(json.utf8))
    }

    static func capturedBody(method: String, path: String) -> Data? {
        let key = "\(method) \(path)"
        lock.lock(); defer { lock.unlock() }
        return capturedBodies[key]?.first
    }

    static func capturedBodies(method: String, path: String) -> [Data] {
        let key = "\(method) \(path)"
        lock.lock(); defer { lock.unlock() }
        return capturedBodies[key] ?? []
    }

    static func allRequests() -> [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return requestLog
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let key = "\(method) \(path)"

        let body = MockURLProtocol.bodyBytes(of: request)

        var stub: Stub?
        MockURLProtocol.lock.lock()
        MockURLProtocol.requestLog.append(self.request)
        if let body = body {
            var list = MockURLProtocol.capturedBodies[key, default: []]
            list.append(body)
            MockURLProtocol.capturedBodies[key] = list
        }
        if var queue = MockURLProtocol.stubsQueue[key], !queue.isEmpty {
            stub = queue.removeFirst()
            MockURLProtocol.stubsQueue[key] = queue
        }
        MockURLProtocol.lock.unlock()

        guard let chosen = stub else {
            let err = NSError(domain: "MockURLProtocol", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "no stub registered for \(key)"
            ])
            client?.urlProtocol(self, didFailWithError: err)
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: chosen.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: chosen.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if !chosen.body.isEmpty {
            client?.urlProtocol(self, didLoad: chosen.body)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// Drains the request body, whether it was attached as `httpBody` or as
    /// `httpBodyStream` (Linux/Foundation often switches to the stream form).
    private static func bodyBytes(of request: URLRequest) -> Data? {
        if let data = request.httpBody, !data.isEmpty {
            return data
        }
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufSize)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: bufSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            return data.isEmpty ? nil : data
        }
        return nil
    }
}

// MARK: - URLSession helpers

extension URLSession {
    /// Creates a URLSession configured to route every request through ``MockURLProtocol``.
    static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }
}
