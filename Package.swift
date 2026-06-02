// swift-tools-version: 5.9
import PackageDescription

// Binary-only distribution. The public package does not include SDK source code.
// 二进制分发包。公开仓库不包含 SDK 源码。
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
