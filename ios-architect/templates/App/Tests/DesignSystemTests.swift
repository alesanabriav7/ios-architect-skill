import Testing
import UIKit
@testable import DesignSystem

struct DesignSystemTests {
    @Test func assetColorsResolveFromTheFrameworkBundle() {
        #expect(UIColor(named: "AccentBrand", in: .designSystem, compatibleWith: nil) != nil)
    }
}
