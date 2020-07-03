// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "emceeadmin",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "emceeadmin",
            targets: [
                "EmceeAdminBinary",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/avito-tech/Emcee.git", .branch("master")),
        .package(url: "https://github.com/SnapKit/SnapKit", .exact("5.0.1")),
    ],
    targets: [
        .target(
            name: "EasyAppKit"
        ),
        .target(
            name: "EmceeAdminLib",
            dependencies: [
                "EasyAppKit",
                "EmceeCommunications",
                "EmceeInterfaces",
                "SnapKit",
            ]
        ),
        .target(
            name: "EmceeAdminBinary",
            dependencies: [
                "EmceeAdminLib",
            ]
        ),
    ]
)
