import ProjectDescription

let project = Project(
    name: "Avis",
    packages: [
        .remote(url: "https://github.com/Mijick/CalendarView.git", requirement: .branch("main"))
    ],
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
            ],

            dependencies: [
                .package(product: "MijickCalendarView")
            ]
        )
    ]
)
