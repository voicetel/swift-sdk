//
//  ModelTests.swift
//  VoiceTelTests
//
//  Quick coverage on Codable round-trips for models that don't get
//  exercised by every happy-path service test.
//

import XCTest
@testable import VoiceTel

final class ModelTests: XCTestCase {

    func testJSONValueRoundTrip() throws {
        let raw = Data(#"{"k1":null,"k2":true,"k3":42,"k4":1.5,"k5":"hi","k6":[1,2,3],"k7":{"nested":"v"}}"#.utf8)
        let value = try JSONDecoder().decode(JSONValue.self, from: raw)
        switch value {
        case .object(let dict):
            XCTAssertEqual(dict.count, 7)
            if case .null = dict["k1"]! {} else { XCTFail("k1") }
            if case .bool(let b) = dict["k2"]! { XCTAssertTrue(b) } else { XCTFail("k2") }
            if case .int(let i) = dict["k3"]! { XCTAssertEqual(i, 42) } else { XCTFail("k3") }
            if case .double(let d) = dict["k4"]! { XCTAssertEqual(d, 1.5) } else { XCTFail("k4") }
            if case .string(let s) = dict["k5"]! { XCTAssertEqual(s, "hi") } else { XCTFail("k5") }
            if case .array(let a) = dict["k6"]! { XCTAssertEqual(a.count, 3) } else { XCTFail("k6") }
            if case .object(let o) = dict["k7"]! { XCTAssertEqual(o.count, 1) } else { XCTFail("k7") }
        default:
            XCTFail("expected object")
        }
        // Re-encode and re-decode to confirm symmetry.
        let re = try JSONEncoder().encode(value)
        _ = try JSONDecoder().decode(JSONValue.self, from: re)
    }

    func testMessageKeyComponentDecode() throws {
        let arr = try JSONDecoder().decode([MessageKeyComponent].self, from: Data("[\"alice\",42]".utf8))
        XCTAssertEqual(arr.count, 2)
        if case .string(let s) = arr[0] { XCTAssertEqual(s, "alice") } else { XCTFail() }
        if case .int(let i) = arr[1] { XCTAssertEqual(i, 42) } else { XCTFail() }

        // Round-trip
        let encoded = try JSONEncoder().encode(arr)
        let arr2 = try JSONDecoder().decode([MessageKeyComponent].self, from: encoded)
        XCTAssertEqual(arr.count, arr2.count)
    }

    func testOrderNumberDecodeString() throws {
        let n = try JSONDecoder().decode(OrderNumber.self, from: Data("\"2015550123\"".utf8))
        XCTAssertEqual(n.value, "2015550123")
        XCTAssertNil(n.spec)
    }

    func testOrderNumberDecodeObject() throws {
        let n = try JSONDecoder().decode(OrderNumber.self, from: Data(#"{"number":"2015550123","route":4}"#.utf8))
        XCTAssertEqual(n.spec?.number, "2015550123")
        XCTAssertEqual(n.spec?.route, 4)
        XCTAssertNil(n.value)
    }

    func testAccountModelsCodable() throws {
        let raw = Data("""
        {"username":"alice","name":"Alice","email":"a@b.c","enabled":true,"cash":100.0,"callerId":"2015550123","timezone":"America/Chicago","authType":0,"ccs":23,"notify":true,"notifyThreshold":5,"rates":{"cnam":0.01,"sms":0.005},"services":{"e911":true,"sms":true}}
        """.utf8)
        let decoded = try JSONDecoder().decode(AccountData.self, from: raw)
        XCTAssertEqual(decoded.username, "alice")
        XCTAssertEqual(decoded.rates?.cnam, 0.01)
        XCTAssertEqual(decoded.services?.e911, true)
        // Symmetric encode.
        let re = try JSONEncoder().encode(decoded)
        let again = try JSONDecoder().decode(AccountData.self, from: re)
        XCTAssertEqual(again.username, "alice")
    }

    func testAccountRatesAndServicesPublicInits() {
        // Exercises the public memberwise initializers (which by default we
        // don't get auto-synthesised public ones for storage-only structs).
        let r = AccountRates(cnam: 0.01, intlMax: 0.5, nibble: 0.005, lrn: 0.001,
                             fax: 0.0, tfAdj: 0.02, did: 0.85, mms: 0.04, sms: 0.005)
        XCTAssertEqual(r.cnam, 0.01)
        let s = AccountServices(e911: true, cnam: false, bypassMedia: false,
                                intl: true, mms: true, dialer: false, sms: true)
        XCTAssertTrue(s.e911 ?? false)
    }

    func testMessagingEnablementJobRoundTrip() throws {
        let raw = Data("""
        {"campaignId":"CAMP002","state":"failed","message":"carrier rejected","createdAt":"2026-10-01T12:00:00Z","updatedAt":"2026-10-01T13:00:00Z"}
        """.utf8)
        let job = try JSONDecoder().decode(MessagingEnablementJob.self, from: raw)
        XCTAssertEqual(job.campaignId, "CAMP002")
        XCTAssertEqual(job.state, "failed")
        XCTAssertEqual(job.message, "carrier rejected")
        // Symmetric encode.
        let re = try JSONEncoder().encode(job)
        let again = try JSONDecoder().decode(MessagingEnablementJob.self, from: re)
        XCTAssertEqual(again.state, "failed")
    }

    func testCampaignDcaCodable() throws {
        let raw = Data("""
        {"electionComplete":false,"electedCarriers":null,"carriers":[{"carrier":"Verizon Wireless","status":"REJECTED","detail":"Campaign rejected","updatedAt":"2026-10-02T09:30:00Z"}]}
        """.utf8)
        let dca = try JSONDecoder().decode(CampaignDca.self, from: raw)
        XCTAssertFalse(dca.electionComplete)
        XCTAssertNil(dca.electedCarriers)
        XCTAssertEqual(dca.carriers.count, 1)
        XCTAssertEqual(dca.carriers[0].carrier, "Verizon Wireless")
        XCTAssertEqual(dca.carriers[0].status, "REJECTED")
    }

    func testInventoryQueryDefaults() {
        let q = InventoryQuery(tnMask: "201555*")
        XCTAssertEqual(q.tnMask, "201555*")
        XCTAssertNil(q.quantity)
        XCTAssertNil(q.province)
        XCTAssertNil(q.rateCenter)
        XCTAssertNil(q.lata)
    }

    func testCoverageQueryDefaults() {
        let q = CoverageQuery(countBy: .state)
        XCTAssertEqual(q.countBy, .state)
        XCTAssertEqual(q.countBy.rawValue, "state")
        XCTAssertNil(q.locState)
        XCTAssertNil(q.city)
        XCTAssertNil(q.rcAbbre)
        XCTAssertNil(q.npa)
        XCTAssertNil(q.lata)
        // Wire values match the spec enum exactly.
        XCTAssertEqual(CoverageCountBy.city.rawValue, "city")
        XCTAssertEqual(CoverageCountBy.rateCenter.rawValue, "rateCenter")
        XCTAssertEqual(CoverageCountBy.npanxx.rawValue, "npanxx")
        XCTAssertEqual(CoverageCountBy.block.rawValue, "block")
    }

    func testPortFeatureSetters() {
        let f = PortFeature(
            number: "2015550123",
            routing: PortFeatureRouting(gatewayId: 4),
            lidb: PortFeatureLidb(name: "ALICE"),
            sms: PortFeatureSms(campaignId: "CAMP123")
        )
        XCTAssertEqual(f.routing?.gatewayId, 4)
        XCTAssertEqual(f.lidb?.name, "ALICE")
        XCTAssertEqual(f.sms?.campaignId, "CAMP123")
    }
}

