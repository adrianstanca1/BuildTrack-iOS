// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuildTrack",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "BuildTrack", targets: ["BuildTrack"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "BuildTrack",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: ".",
            exclude: [
                "Tests",
                "scripts",
                "fastlane",
                ".github",
                "BuildTrack.xcodeproj",
                "BuildTrack.xcworkspace",
                "Package.swift",
            ]
        ),
    ]
)
