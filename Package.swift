// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "zxcvbn",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "zxcvbn",
            targets: ["zxcvbn"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "zxcvbn",
            resources: [
                .copy("Resources/adjacency-graphs.json"),
                .copy("Resources/frequency-lists.json")
            ]
        ),
        .testTarget(
            name: "zxcvbnTests",
            dependencies: ["zxcvbn"],
            path: "Tests/zxcvbn-Tests",
            sources: [
                "TestCompatibility.swift",
                "TestHelpers.swift",
                "TestMatching.swift",
                "TestMatchingHelpers.swift",
                "TestScoring.swift",
                "TestTimeEstimates.swift",
                "TestValues1.swift"
            ]
        )
    ]
)
