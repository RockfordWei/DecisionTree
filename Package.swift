// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DecisionTree",
    products: [
        .library(
            name: "DecisionTree",
            targets: ["DecisionTree"]),
    ],
    dependencies: [
      .package(url: "https://github.com/PerfectlySoft/Perfect-MySQL.git", "3.0.0" ..< "4.0.0")
    ],
    targets: [
        .target(
            name: "DecisionTree",
            dependencies: [
              "PerfectMySQL"
            ]),
        .testTarget(
            name: "DecisionTreeTests",
            dependencies: ["DecisionTree"]),
    ]
)
