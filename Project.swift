import ProjectDescription

let project = Project(
    name: "Avis",
    targets: [
        .target(
            name: "Avis",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.Avis",

            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:])
            ]),

            sources: [
                "Avis/**/*.swift"
            ],

            resources: [
                "Avis/**/*.xcassets"
            ]
        )
    ]
)
