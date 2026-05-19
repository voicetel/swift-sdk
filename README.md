# 📞 VoiceTel Swift SDK

The official Swift client for the [VoiceTel REST API](https://voicetel.com/docs/api/v2.2/) — provision numbers, place orders, validate e911, send messages, and manage your account, all with Swift Concurrency and strongly-typed `Codable` models.

![Version](https://img.shields.io/badge/version-2.2.10-blue)
![Swift](https://img.shields.io/badge/swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)
![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)
![Platforms](https://img.shields.io/badge/platforms-macOS%2012%20%7C%20iOS%2015%20%7C%20tvOS%2015%20%7C%20watchOS%208%20%7C%20Linux-lightgrey)

## 📚 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quickstart](#-quickstart)
- [Authentication](#-authentication)
- [Resource Reference](#-resource-reference)
- [Error Handling](#-error-handling)
- [Cancellation and Timeouts](#-cancellation-and-timeouts)
- [Rate Limits](#-rate-limits)
- [Development](#-development)
- [API Documentation](#-api-documentation)
- [Contributors](#-contributors)
- [Sponsors](#-sponsors)
- [License](#-license)

## ✨ Features

### 🛡️ Strongly Typed End-to-End
- **Native Swift `Codable` structs** for every one of the 73 API operations — JSON encoded with `Foundation.JSONEncoder`, no reflection magic.
- **Optionals for nullable request fields** — `Bool?` / `Int?` / `String?` distinguish "not set" from "zero" cleanly when PATCH-ing.
- **Optionals for nullable response fields** — `forwardTo: String?` lets you tell apart "no forward configured" from an empty destination.
- **Async / await throughout.** Every method is `async throws`; cancellation propagates from `Task` down to the HTTP layer.

### 🔁 Production-Grade Transport
- Built on `URLSession` — no third-party dependencies, works on Linux via `FoundationNetworking`.
- **Automatic retry** with exponential backoff on 429 / 5xx — honors `Retry-After` headers, capped at 8s.
- **Configurable timeout** per session (defaults to 30s).
- **Bearer auth** managed for you; the password→key exchange is one method call (`client.login`).
- **Structured `APIError`** with typed `kind` so you can `switch error.kind { case .rateLimit: ... }` without parsing HTTP status codes.

### 📞 Complete API Coverage
- **Numbers** — list, get, add, remove, route, translate, CNAM, LIDB, fax, forward, SMS, messaging campaigns, port-out PIN, account moves.
- **Account** — profile, sub-accounts, CDRs, credits, payments, MRC, registration, password recovery.
- **e911** — record provisioning, address validation, lookup, removal.
- **Gateways** — list, create, update, delete, view bound numbers.
- **Messaging** — SMS & MMS sending, message history, 10DLC brand and campaign registration, per-number messaging state.
- **Lookups** — CNAM and LRN dips.
- **iNumbering** — inventory search, coverage queries, number orders, port-in submissions, port-out availability.
- **Support** — ticket create / read / update / delete, threaded messages, replies.
- **ACL** — IP allowlist management with structured 409 conflict bodies.
- **Authentication** — switch between Digest, IP-only, or hybrid modes; rotate passwords.

### 🧪 Battle-Tested
- **95% line coverage** with `swift test --enable-code-coverage`.
- **`URLProtocol`-based unit tests** that exercise every method and every error path.
- **Race-free**: services are `final class` value-types around a lock-protected transport.
- **Zero codegen footprint** — every byte hand-written.

### 📦 Clean Distribution
- Single Swift Package (`VoiceTel`).
- Foundation-only — no external dependencies.
- Linux build is first-class.

## 🚀 Installation

### Swift Package Manager (recommended)

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/voicetel/swift-sdk", from: "2.2.10")
],
targets: [
    .target(name: "App", dependencies: [
        .product(name: "VoiceTel", package: "swift-sdk")
    ])
]
```

Or via Xcode: **File ▸ Add Packages…** and paste `https://github.com/voicetel/swift-sdk`.

### CocoaPods

```ruby
pod 'VoiceTel', '~> 2.2.10'
```

Requires Swift 5.9+ and one of: macOS 12+, iOS 15+, tvOS 15+, watchOS 8+, or any Linux distribution supported by the official Swift toolchain.

## 🏁 Quickstart

```swift
import VoiceTel

let client = VoiceTelClient()

// Exchange username + password for an API key (one-time per session)
let apiKey = try await client.login(username: "1000000001", password: "hunter2")

// Typed responses — your IDE knows what `me` is.
let me = try await client.account.get()
print("Balance: $\(me.cash ?? 0)  |  Caller ID: \(me.callerId ?? "")")

// List your numbers
let numbers = try await client.numbers.list()
for n in numbers.numbers {
    print("\(n.number)  route=\(n.route)  cnam=\(n.cnam)  sms=\(n.smsEnabled)")
}
```

Or, if you already have an API key:

```swift
let client = VoiceTelClient(apiKey: "32hex...")

let coverage = try await client.iNumbering.coverage(query: CoverageQuery(state: "NJ"))
for bucket in coverage.coverage {
    print("\(bucket.npa ?? "")-\(bucket.nxx ?? ""): \(bucket.count) TNs available")
}
```

## 🔑 Authentication

Every endpoint requires `Authorization: Bearer <apikey>` **except** `POST /v2.2/account/api-key`, which exchanges username + password for a fresh key. `VoiceTelClient.login(username:password:)` handles the exchange and installs the returned key on the transport.

Re-fetch the API key after any password change — the old one is invalidated.

> Don't have credentials yet? Get them at **[voicetel.com/docs/api/v2.2/credentials](https://voicetel.com/docs/api/v2.2/credentials/)**.

```swift
let client = VoiceTelClient()
let key = try await client.login(username: "1000000001", password: "hunter2")
// `key` is the new 32-hex bearer; the client already has it installed.
```

## 🗺️ Resource Reference

| Resource       | Field on Client       | Example                                                                |
|----------------|-----------------------|------------------------------------------------------------------------|
| Account        | `client.account`        | `try await client.account.cdr(start: t1, end: t2)`                       |
| ACL            | `client.acl`            | `try await client.acl.add(AclModifyRequest(acl: [...]))`                 |
| Authentication | `client.authentication` | `try await client.authentication.update(AuthPutRequest(authType: 1))`    |
| e911           | `client.e911`           | `try await client.e911.validate(E911AddressRequest(...))`                |
| Gateways       | `client.gateways`       | `try await client.gateways.list()`                                       |
| iNumbering     | `client.iNumbering`     | `try await client.iNumbering.searchInventory(query: InventoryQuery(npa: 201))` |
| Lookups        | `client.lookups`        | `try await client.lookups.lrn(number: "2015551234", ani: "2012548000")`  |
| Messaging      | `client.messaging`      | `try await client.messaging.send(MessageSendRequest(...))`               |
| Numbers        | `client.numbers`        | `try await client.numbers.assignCampaign(number: "2015551234", body: ...)` |
| Support        | `client.support`        | `try await client.support.create(TicketCreateRequest(...))`              |

Optional request fields are Swift optionals. Pass `nil` (or simply omit the argument) to leave them unchanged:

```swift
let body = AccountPutRequest(
    notify: true,
    notifyThreshold: 5,
    timezone: "America/Chicago"
)
let resp = try await client.account.update(body)
print(resp.updated) // ["notify", "notifyThreshold", "timezone"]
```

## 🚨 Error Handling

All API errors throw a `VoiceTel.APIError`. Inspect `kind` or use the helpers:

| Kind                 | HTTP status |
|----------------------|-------------|
| `.badRequest`         | 400         |
| `.authentication`     | 401         |
| `.permissionDenied`   | 403         |
| `.notFound`           | 404         |
| `.conflict`           | 409         |
| `.rateLimit`          | 429         |
| `.server`             | 5xx         |
| `.unknown`            | other / transport |

```swift
do {
    let n = try await client.numbers.get(number: "9999999999")
    print(n)
} catch let error as APIError where error.kind == .notFound {
    print("That number isn't on your account.")
} catch let error as APIError where error.kind == .rateLimit {
    print("Slow down — backoff and retry.")
} catch {
    print("Unexpected: \(error)")
}
```

Or use the static helpers:

```swift
if APIError.isNotFound(error) { ... }
if APIError.isRateLimit(error) { ... }
```

Conflict (409) responses preserve the structured body so you can inspect partial successes:

```swift
do {
    _ = try await client.acl.add(AclModifyRequest(acl: cidrs))
} catch let error as APIError where error.kind == .conflict {
    // error.body is the raw JSON (Any?); cast to inspect.
    print("partial: \(String(describing: error.body))")
}
```

## ⏱️ Cancellation and Timeouts

Every method is `async throws` and respects Swift Concurrency cancellation. Wrap a call in a `Task` and cancel it from anywhere:

```swift
let task = Task {
    try await client.account.get()
}
// later...
task.cancel()
```

For per-request deadlines, configure the `URLSession` you pass to the client:

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 10
config.timeoutIntervalForResource = 30
let client = VoiceTelClient(session: URLSession(configuration: config))
```

## ⏱️ Rate Limits

These endpoints are limited to **6 requests per hour per IP**:

- `GET /v2.2/account` (`client.account.get()`)
- `GET /v2.2/account/cdr` (`client.account.cdr(start:end:)`)
- `GET /v2.2/account/recurring-charges` (`client.account.recurringCharges()`)
- `GET /v2.2/account/payments` (`client.account.payments()`)
- `GET /v2.2/account/registration` (`client.account.registration()`)
- `POST /v2.2/account/api-key` (`client.login(username:password:)`)

The SDK automatically retries 429 responses with `Retry-After` honored, up to `maxRetries` attempts (default 2). To bump it:

```swift
let client = VoiceTelClient(apiKey: key, maxRetries: 4)
```

## 🛠️ Development

```bash
git clone https://github.com/voicetel/swift-sdk
cd swift-sdk

# Run unit tests
swift test

# With coverage
swift test --enable-code-coverage

# Inspect coverage report (Linux/macOS, llvm-cov from the Swift toolchain)
PROF=$(find .build -name 'default.profdata' | head -1)
BIN=$(find .build -name '*.xctest' -type f | head -1)
llvm-cov report "$BIN" --instr-profile="$PROF" --ignore-filename-regex='(Tests|\.build)'

# Build the release artifact
swift build -c release
```

Integration tests (gated on `VOICETEL_USERNAME` + `VOICETEL_PASSWORD`) exercise the live API in read-only mode:

```bash
cp .env.example .env  # then edit .env with real credentials
set -a; source .env; set +a
swift test --filter IntegrationTests
```

## 📖 API Documentation

- **Reference docs:** [voicetel.com/docs/api/v2.2/](https://voicetel.com/docs/api/v2.2/)
- **Interactive playground:** [voicetel.com/docs/api/v2.2/playground/](https://voicetel.com/docs/api/v2.2/playground/) — try the API in your browser without writing any code
- **API credentials:** [voicetel.com/docs/api/v2.2/credentials/](https://voicetel.com/docs/api/v2.2/credentials/)

## 🙌 Contributors

- [Michael Mavroudis](https://github.com/mavroudis) — Lead Developer

Contributions welcome. Open an issue describing the change, or send a pull request against `main`.

## 💖 Sponsors

| Sponsor                                              | Contribution                                 |
|------------------------------------------------------|----------------------------------------------|
| [VoiceTel Communications](https://voicetel.com)        | Primary development and production hosting   |

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
