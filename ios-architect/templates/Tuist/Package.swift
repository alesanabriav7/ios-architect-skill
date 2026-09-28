// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

// Xcode 26+ rejects GRDB's declared iOS 13 target; raise it to the app's minimum.
let packageSettings = PackageSettings(
    productTypes: ["GRDB": .framework],
    targetSettings: [
        "GRDB": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
        "GRDBSQLite": .settings(base: ["IPHONEOS_DEPLOYMENT_TARGET": "26.0"]),
    ]
)
#endif

let package = Package(
    name: "SampleAppDependencies",
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ]
)
