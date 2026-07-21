import ProjectDescription

let project = Project(
    name: "Avis",
    targets: [
        .target(
            name: "Avis",
            destinations: .iOS,
            product: .app,
            bundleId: "com.example.Avis",

            infoPlist: .default,

            sources: [
                "Avis/**/*.swift"
            ],

            resources: [
                "Avis/**/*.xcassets"
            ]
        )
    ]
)
