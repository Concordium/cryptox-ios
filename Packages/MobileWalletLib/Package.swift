// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileWalletLib",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "MobileWalletLib", targets: ["LegacyMobileWallet"]),
    ],
    targets: [
        .binaryTarget(
            name: "LegacyMobileWallet",
            path: "Sources/MobileWalletLib/Binaries/libmobile_wallet.xcframework"
        )
    ]
)
