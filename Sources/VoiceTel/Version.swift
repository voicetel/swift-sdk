//
//  Version.swift
//  VoiceTel
//
//  Copyright (c) 2026 VoiceTel Communications.
//  Licensed under the MIT License.
//

import Foundation

/// Static identifiers and defaults baked into the VoiceTel SDK.
public enum VoiceTel {
    /// Semantic version of this client library. Matches the API version it targets.
    public static let sdkVersion = "2.2.10"

    /// VoiceTel REST API version this SDK targets.
    public static let apiVersion = "v2.2.10"

    /// Production API endpoint. Override with ``VoiceTelClient/init(baseURL:apiKey:session:userAgent:maxRetries:)``.
    public static let defaultBaseURL = "https://api.voicetel.com"

    /// Default `User-Agent` header sent on every request.
    public static let defaultUserAgent = "voicetel-swift/\(sdkVersion) (+https://github.com/voicetel/swift-sdk)"
}
