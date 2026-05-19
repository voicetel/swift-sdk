//
//  IntegrationTests.swift
//  VoiceTelTests
//
//  Read-only integration tests, gated on VOICETEL_USERNAME / VOICETEL_PASSWORD.
//  Skipped silently when the env vars are not present so unit tests can run
//  in CI without credentials.
//

import XCTest
@testable import VoiceTel

final class IntegrationTests: XCTestCase {

    /// Skips this test (with a descriptive throw) when credentials aren't configured.
    private func requireCredentials() throws -> (username: String, password: String, baseURL: String) {
        let env = ProcessInfo.processInfo.environment
        guard let username = env["VOICETEL_USERNAME"], !username.isEmpty,
              let password = env["VOICETEL_PASSWORD"], !password.isEmpty else {
            throw XCTSkip("VOICETEL_USERNAME / VOICETEL_PASSWORD not set")
        }
        let baseURL = env["VOICETEL_BASE_URL"] ?? VoiceTel.defaultBaseURL
        return (username, password, baseURL)
    }

    func testLoginAndProfile() async throws {
        let creds = try requireCredentials()
        let client = VoiceTelClient(baseURL: creds.baseURL)
        _ = try await client.login(username: creds.username, password: creds.password)
        XCTAssertFalse(client.apiKey?.isEmpty ?? true)
        let me = try await client.account.get()
        XCTAssertNotNil(me.username)
    }

    func testListNumbers() async throws {
        let creds = try requireCredentials()
        let client = VoiceTelClient(baseURL: creds.baseURL)
        _ = try await client.login(username: creds.username, password: creds.password)
        _ = try await client.numbers.list()
    }

    func testListGateways() async throws {
        let creds = try requireCredentials()
        let client = VoiceTelClient(baseURL: creds.baseURL)
        _ = try await client.login(username: creds.username, password: creds.password)
        let g = try await client.gateways.list()
        // Every account has the system routes pre-populated.
        XCTAssertFalse(g.gateways.isEmpty)
    }
}
