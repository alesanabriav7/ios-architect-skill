import SwiftUI

/// Shared component: tokens only, scales with Dynamic Type, no fixed heights.
public struct StatusBadge: View {
    private let title: LocalizedStringKey
    private let systemImage: String

    public init(_ title: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentBrand)
            .padding(.horizontal, Space.s)
            .padding(.vertical, Space.xs)
            .background(Color.accentBrand.opacity(0.12), in: .capsule)
    }
}

#Preview {
    StatusBadge("Pinned", systemImage: "pin.fill")
        .padding()
}
