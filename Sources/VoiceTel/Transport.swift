//
//  Transport.swift
//  VoiceTel
//
//  Copyright (c) 2026 VoiceTel Communications.
//  Licensed under the MIT License.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP-method enum used by ``Transport``. Maps 1:1 to the strings on the wire.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Internal HTTP client used by every resource service.
///
/// Built on `URLSession` (cross-platform on Linux via `FoundationNetworking`).
/// Marked `final class` so a single instance can be shared across services
/// without copying mutable state (apiKey).
final class Transport: @unchecked Sendable {
    private let baseURL: String
    private let session: URLSession
    private let userAgent: String
    let maxRetries: Int

    /// API key is mutable — `VoiceTelClient.login` installs the freshly-issued key
    /// here. Reads/writes go through a serial queue to make the mutation
    /// safe across concurrent calls.
    private let lock = NSLock()
    private var _apiKey: String?

    var apiKey: String? {
        lock.lock(); defer { lock.unlock() }
        return _apiKey
    }

    func setApiKey(_ key: String?) {
        lock.lock(); defer { lock.unlock() }
        _apiKey = key
    }

    init(
        baseURL: String,
        apiKey: String?,
        session: URLSession,
        userAgent: String,
        maxRetries: Int
    ) {
        // Trim a trailing slash so callers can pass either form.
        var trimmed = baseURL
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        self.baseURL = trimmed
        self._apiKey = apiKey
        self.session = session
        self.userAgent = userAgent
        self.maxRetries = max(0, maxRetries)
    }

    var configuredBaseURL: String { baseURL }

    /// HTTP statuses we'll back off and retry. 429 + the usual transient 5xx set.
    private static let retryableStatuses: Set<Int> = [429, 500, 502, 503, 504]

    /// Performs an HTTP request and decodes the response into `Response`.
    ///
    /// - Parameters:
    ///   - method: HTTP verb.
    ///   - path: Path component starting with `/` (e.g. `/v2.2/numbers`).
    ///   - query: Optional flat `[name: value]` query pairs.
    ///   - body: Optional `Encodable` body; JSON-encoded.
    ///   - requireAuth: `true` for everything except `api-key` exchange and password recovery.
    func request<Response: Decodable>(
        _ method: HTTPMethod,
        path: String,
        query: [String: String?]? = nil,
        body: Encodable? = nil,
        requireAuth: Bool = true,
        responseType: Response.Type
    ) async throws -> Response {
        let raw = try await sendRequest(
            method: method,
            path: path,
            query: query,
            body: body,
            requireAuth: requireAuth
        )
        return try decode(Response.self, fromEnvelope: raw)
    }

    /// Performs an HTTP request that returns no usable body (DELETE → 204, etc.).
    func requestVoid(
        _ method: HTTPMethod,
        path: String,
        query: [String: String?]? = nil,
        body: Encodable? = nil,
        requireAuth: Bool = true
    ) async throws {
        _ = try await sendRequest(
            method: method,
            path: path,
            query: query,
            body: body,
            requireAuth: requireAuth
        )
    }

    /// Lower-level send: handles auth header, retries, and surfaces an APIError on
    /// non-2xx. Returns the raw response bytes for further decoding.
    private func sendRequest(
        method: HTTPMethod,
        path: String,
        query: [String: String?]?,
        body: Encodable?,
        requireAuth: Bool
    ) async throws -> Data {
        if requireAuth && (apiKey ?? "").isEmpty {
            throw APIError(
                kind: .authentication,
                message: "no api key set; call client.login(...) or pass apiKey: when constructing VoiceTelClient"
            )
        }

        let url = try buildURL(path: path, query: query)
        let bodyData = try encodeBody(body)

        let idempotencyKey: String? = [.post, .put, .patch].contains(method)
            ? UUID().uuidString : nil

        var attempt = 0

        while true {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
            if let bodyData = bodyData {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = bodyData
            }
            if requireAuth, let key = apiKey {
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            }
            if let key = idempotencyKey {
                request.setValue(key, forHTTPHeaderField: "Idempotency-Key")
            }

            let result: (Data, URLResponse)
            do {
                result = try await data(for: request)
            } catch {
                // Transport failure (DNS, TCP, TLS, cancellation, etc.).
                if attempt >= maxRetries {
                    throw APIError(
                        kind: .unknown,
                        statusCode: 0,
                        message: "transport error after \(attempt + 1) attempt(s): \(error.localizedDescription)",
                        underlying: error
                    )
                }
                try await backoff(attempt: attempt, retryAfter: nil)
                attempt += 1
                continue
            }

            let (data, response) = result
            guard let http = response as? HTTPURLResponse else {
                throw APIError(message: "non-HTTP response from \(url)")
            }

            if Self.retryableStatuses.contains(http.statusCode) && attempt < maxRetries {
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
                try await backoff(attempt: attempt, retryAfter: retryAfter)
                attempt += 1
                continue
            }

            if (200..<300).contains(http.statusCode) {
                return data
            }

            throw parseErrorResponse(status: http.statusCode, data: data)
        }
    }

    /// `URLSession.data(for:)` polyfill for Linux + older Apple toolchains that
    /// don't expose the async overload.
    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data, let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
        #else
        if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
            return try await session.data(for: request)
        }
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data, let response = response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
        #endif
    }

    // MARK: - URL & body helpers

    private func buildURL(path: String, query: [String: String?]?) throws -> URL {
        let normalisedPath = path.hasPrefix("/") ? path : "/" + path
        let target = baseURL + normalisedPath
        guard var comps = URLComponents(string: target) else {
            throw APIError(message: "invalid URL: \(target)")
        }
        if let query = query {
            let items: [URLQueryItem] = query
                .compactMap { (key, value) in
                    guard let value = value, !value.isEmpty else { return nil }
                    return URLQueryItem(name: key, value: value)
                }
                .sorted { $0.name < $1.name }
            if !items.isEmpty {
                comps.queryItems = items
            }
        }
        guard let url = comps.url else {
            throw APIError(message: "invalid URL components: \(target)")
        }
        return url
    }

    private func encodeBody(_ body: Encodable?) throws -> Data? {
        guard let body = body else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(AnyEncodable(body))
        } catch {
            throw APIError(
                kind: .unknown,
                message: "marshal request body: \(error.localizedDescription)",
                underlying: error
            )
        }
    }

    // MARK: - Decode

    /// Strips the `{"status": "success", "data": <T>}` envelope before decoding.
    private func decode<T: Decodable>(_ type: T.Type, fromEnvelope raw: Data) throws -> T {
        let decoder = JSONDecoder()
        if raw.isEmpty {
            // The decoder will fail on empty data for non-optional types, which
            // is intentional. Optional callers should use `requestVoid`.
            throw APIError(message: "empty response body")
        }
        let inner = Self.unwrap(raw)
        do {
            return try decoder.decode(T.self, from: inner)
        } catch {
            let bodyString = String(data: inner, encoding: .utf8) ?? "<binary>"
            throw APIError(
                kind: .unknown,
                statusCode: 200,
                message: "decode response body: \(error.localizedDescription)",
                body: bodyString,
                underlying: error
            )
        }
    }

    /// Peels `{"status": "...", "data": ...}` off raw JSON when present.
    static func unwrap(_ raw: Data) -> Data {
        // Cheap path: only attempt unwrapping if it looks like a JSON object.
        let trimmed = raw.drop(while: { $0 == 0x20 || $0 == 0x09 || $0 == 0x0A || $0 == 0x0D })
        guard trimmed.first == 0x7B /* '{' */ else { return raw }
        guard let object = try? JSONSerialization.jsonObject(with: raw, options: []) else {
            return raw
        }
        guard let dict = object as? [String: Any] else { return raw }
        // The envelope is `{"status": "<string>", "data": <object|array|primitive>}`.
        guard dict["status"] is String, let data = dict["data"] else {
            return raw
        }
        do {
            return try JSONSerialization.data(withJSONObject: data, options: [.fragmentsAllowed])
        } catch {
            return raw
        }
    }

    // MARK: - Errors / backoff

    private func parseErrorResponse(status: Int, data: Data) -> APIError {
        var code: String?
        var message: String?
        var body: Any?
        if !data.isEmpty,
           let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            body = object
            if let dict = object as? [String: Any] {
                if let c = dict["code"] as? String {
                    code = c
                } else if let e = dict["error"] as? String {
                    code = e
                }
                if let m = dict["message"] as? String {
                    message = m
                } else if let e = dict["error"] as? String {
                    message = e
                }
            }
        } else if let str = String(data: data, encoding: .utf8) {
            body = str
        }
        let finalMessage = message ?? "HTTP \(status)"
        return APIError.from(statusCode: status, code: code, message: finalMessage, body: body)
    }

    private func backoff(attempt: Int, retryAfter: Int?) async throws {
        let delay: TimeInterval
        if let secs = retryAfter, secs >= 0 {
            delay = TimeInterval(secs)
        } else {
            // Exponential capped at 8s: 0.5, 1, 2, 4, 8...
            let base: Double = 0.5
            let computed = base * pow(2.0, Double(attempt))
            delay = min(computed, 8.0)
        }
        if delay <= 0 { return }
        let nanos = UInt64(delay * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanos)
    }
}

// MARK: - AnyEncodable

/// Type-eraser for `Encodable` so the public surface can accept heterogeneous
/// body types without forcing a generic on every transport call.
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ wrapped: T) {
        self._encode = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
