// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthBox",
	 platforms: [
					 .macOS(.v13),
					 .iOS(.v16),
					 .watchOS(.v8)
			],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HealthBox",
            targets: ["HealthBox"]),
    ],
	 dependencies: [
		 .package(url: "https://github.com/ios-tooling/Suite.git", from: "1.0.111"),
	 ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HealthBox", dependencies: [
					.product(name: "Suite", package: "Suite"),
				]),
        .testTarget(
            name: "HealthBoxTests",
            dependencies: ["HealthBox"]),
    ]
)
