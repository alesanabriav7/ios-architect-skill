import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")

// Verification only: `TUIST_MAIN_ACTOR_DEFAULT=1 tuist generate` compiles our targets as MainActor-by-default modules.
let swiftSettings: SettingsDictionary = Environment.mainActorDefault.getBoolean(default: false)
    ? ["SWIFT_VERSION": "6.0", "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor", "SWIFT_APPROACHABLE_CONCURRENCY": "YES"]
    : ["SWIFT_VERSION": "6.0"]

let project = Project(
    name: "SampleApp",
    settings: .settings(base: swiftSettings),
    targets: [
        .target(
            name: "SampleApp",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.example.sampleapp",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "CFBundleURLTypes": .array([
                    .dictionary(["CFBundleURLSchemes": .array([.string("sampleapp")])]),
                ]),
            ]),
            sources: ["App/Sources/**"],
            dependencies: [
                .target(name: "DesignSystem"),
                .external(name: "GRDB"),
            ]
        ),
        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.example.sampleapp.designsystem",
            deploymentTargets: deploymentTargets,
            sources: ["DesignSystem/Sources/**"],
            resources: ["DesignSystem/Resources/**"]
        ),
        .target(
            name: "SampleAppTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.example.sampleapp.tests",
            deploymentTargets: deploymentTargets,
            sources: ["App/Tests/**"],
            dependencies: [
                .target(name: "SampleApp"),
                .target(name: "DesignSystem"),
                .external(name: "GRDB"),
            ]
        ),
    ]
)
