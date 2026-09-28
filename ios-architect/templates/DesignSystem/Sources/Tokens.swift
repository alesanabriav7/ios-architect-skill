import SwiftUI

public enum Space {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
}

public enum Radius {
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 20
}

public extension Color {
    /// Asset colors in a framework must name its bundle; `Color("Name")` looks in the app bundle and silently renders clear.
    static let accentBrand = Color("AccentBrand", bundle: .designSystem)
}

extension Bundle {
    /// For a Swift package target use `Bundle.module` instead.
    static let designSystem = Bundle(for: BundleToken.self)
}

private final class BundleToken {}
