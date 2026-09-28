import Foundation
import Testing
@testable import SampleApp

struct KeychainStoreTests {
    @Test func roundTripsAndDeletes() throws {
        let store = KeychainStore(service: "dev.example.sampleapp.tests.\(UUID().uuidString)")

        try store.set("secret", for: "refreshToken")
        try store.set("rotated", for: "refreshToken")
        #expect(try store.string(for: "refreshToken") == "rotated")

        try store.set(nil, for: "refreshToken")
        #expect(try store.string(for: "refreshToken") == nil)
    }
}
