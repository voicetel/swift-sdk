//
//  TestSupport.swift
//  VoiceTelTests
//
//  Shared helpers for every test: makeClient, JSON envelope wrapping, and
//  small assertion utilities.
//

import XCTest
@testable import VoiceTel

/// Wraps a raw `data` JSON literal in the standard `{"status":"success","data":...}` envelope.
func envelope(_ rawDataJSON: String) -> String {
    return "{\"status\":\"success\",\"data\":\(rawDataJSON)}"
}

/// Build a client wired to `MockURLProtocol` with no retries (so error tests
/// don't sit through backoff). Pre-installs an API key so endpoints requiring
/// auth don't short-circuit unless the test specifically wants that.
func makeTestClient(maxRetries: Int = 0, apiKey: String? = "test-bearer-32hex0000000000000000") -> VoiceTelClient {
    return VoiceTelClient(
        baseURL: "https://api.voicetel.test",
        apiKey: apiKey,
        session: .mockSession(),
        userAgent: "voicetel-swift-test/0.0",
        maxRetries: maxRetries
    )
}

/// Strict-equality JSON dictionary parse for asserting on captured request bodies.
func bodyDict(_ data: Data?, file: StaticString = #file, line: UInt = #line) -> [String: Any] {
    guard let data = data else {
        XCTFail("expected captured body, got nil", file: file, line: line)
        return [:]
    }
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        XCTFail("body was not a JSON object: \(String(data: data, encoding: .utf8) ?? "<binary>")", file: file, line: line)
        return [:]
    }
    return json
}
