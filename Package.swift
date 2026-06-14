// swift-tools-version: 5.9
import PackageDescription

// Binary package distribution.
// 二进制分发包。
let package = Package(
    name: "UyaliBeautySDK",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "UyaliBeautySDK",
            targets: ["UyaliBeautySDK"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "UyaliBeautySDK",
            path: "UyaliBeautySDK.xcframework"
        )
    ]
)
