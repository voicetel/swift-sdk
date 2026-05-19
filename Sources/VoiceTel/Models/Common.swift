//
//  Common.swift
//  VoiceTel
//
//  Copyright (c) 2026 VoiceTel Communications.
//  Licensed under the MIT License.
//

import Foundation

/// A single row in the IP allowlist (`/v2.2/acl`).
///
/// `cidr` must be `/8`, `/16`, `/24`, or `/32` and must describe a routable public IPv4.
public struct CidrEntry: Codable, Hashable, Sendable {
    public var cidr: String

    public init(cidr: String) {
        self.cidr = cidr
    }
}
