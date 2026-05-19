//
//  APIError.swift
//  VoiceTel
//
//  Copyright (c) 2026 VoiceTel Communications.
//  Licensed under the MIT License.
//

import Foundation

/// Structured error thrown for every non-2xx VoiceTel response and for transport failures.
///
/// Inspect ``APIError/kind`` instead of comparing HTTP status codes directly:
///
/// ```swift
/// do {
///     _ = try await client.numbers.get(number: "9999999999")
/// } catch let error as APIError where error.kind == .notFound {
///     print("That number isn't on your account.")
/// }
/// ```
public struct APIError: LocalizedError, @unchecked Sendable {
    /// Classification of the failure based on HTTP status (or `.unknown` for transport errors).
    public enum Kind: String, Sendable, Equatable, CaseIterable {
        /// Catch-all for unmapped statuses or transport failures.
        case unknown
        /// HTTP 400 — server-side validation failure.
        case badRequest
        /// HTTP 401 — bearer token missing, expired, or invalid.
        case authentication
        /// HTTP 403 — authenticated but not allowed.
        case permissionDenied
        /// HTTP 404 — resource does not exist.
        case notFound
        /// HTTP 409 — request conflicts with current state.
        case conflict
        /// HTTP 429 — exceeded the 6/hour/IP cap on account/* endpoints.
        case rateLimit
        /// Any HTTP 5xx.
        case server
    }

    /// Kind of failure. Use this instead of switching on ``statusCode``.
    public let kind: Kind

    /// HTTP status code. Zero when the failure happened before the response arrived.
    public let statusCode: Int

    /// Server-provided error code, when one was supplied in the response body.
    public let code: String?

    /// Human-readable message extracted from the response (or a fallback).
    public let message: String

    /// Raw response body, parsed as JSON when possible (else the literal string).
    public let body: Any?

    /// Underlying transport error, if any (DNS, TCP, TLS, cancellation, etc.).
    public let underlying: Error?

    public init(
        kind: Kind = .unknown,
        statusCode: Int = 0,
        code: String? = nil,
        message: String,
        body: Any? = nil,
        underlying: Error? = nil
    ) {
        self.kind = kind
        self.statusCode = statusCode
        self.code = code
        self.message = message
        self.body = body
        self.underlying = underlying
    }

    public var errorDescription: String? {
        if let code = code, !code.isEmpty {
            return "voicetel: HTTP \(statusCode) \(code): \(message)"
        }
        if statusCode == 0 {
            return "voicetel: \(message)"
        }
        return "voicetel: HTTP \(statusCode): \(message)"
    }

    /// Returns `true` if `error` is an `APIError` with the given kind.
    public static func isKind(_ error: Error, _ kind: Kind) -> Bool {
        guard let apiError = error as? APIError else { return false }
        return apiError.kind == kind
    }

    /// Convenience: was this an HTTP 429?
    public static func isRateLimit(_ error: Error) -> Bool { isKind(error, .rateLimit) }

    /// Convenience: was this an HTTP 404?
    public static func isNotFound(_ error: Error) -> Bool { isKind(error, .notFound) }

    /// Convenience: was this an HTTP 401?
    public static func isAuthentication(_ error: Error) -> Bool { isKind(error, .authentication) }

    /// Convenience: was this an HTTP 409?
    public static func isConflict(_ error: Error) -> Bool { isKind(error, .conflict) }

    /// Build an APIError given an HTTP status, optional code/message, and a parsed body.
    static func from(statusCode: Int, code: String?, message: String, body: Any?) -> APIError {
        APIError(
            kind: kindFromStatus(statusCode),
            statusCode: statusCode,
            code: code,
            message: message,
            body: body
        )
    }

    static func kindFromStatus(_ status: Int) -> Kind {
        switch status {
        case 400: return .badRequest
        case 401: return .authentication
        case 403: return .permissionDenied
        case 404: return .notFound
        case 409: return .conflict
        case 429: return .rateLimit
        case 500..<600: return .server
        default: return .unknown
        }
    }
}
