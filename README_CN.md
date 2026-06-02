# UyaliBeautySDK：移动端美颜 SDK

[English](README.md) | **简体中文** | [日本語](README_JP.md) | [Français](README_FR.md) | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK 是一个用于实时相机帧和图片处理的移动端美颜 SDK，提供基础美颜、美型、美体和美妆效果。目前可用包支持 iOS。

如果这个项目对你有帮助，欢迎给一个 star 支持一下。

## 功能

### 基础美颜

UyaliBeautySDK 提供常见的人像美颜能力，可用于实时相机和图片处理场景：

- 美白和磨皮，用于自然肤色和肤质优化。
- 亮眼和白牙，用于局部细节增强。
- 去黑眼圈，用于面部局部区域精修。
- 每个效果都有独立强度参数，方便制作预设或用户可调节滑杆。

### 美型

美型能力覆盖整体脸型和局部五官：

- 整体脸型：小头、瘦脸、窄脸、V 脸、小脸。
- 面部轮廓：下巴、额头、颧骨调节。
- 眼睛和眉毛：大眼、眼距、眼角、下眼睑、眉间距、眉毛粗细。
- 鼻子和嘴巴：瘦鼻、鼻翼、长鼻、山根、嘴型调节。

### 美体

美体能力适合半身和全身人像场景：

- 瘦身、瘦腰、瘦腿、瘦手臂、瘦小腿、收腹。
- 窄肩、直角肩、天鹅颈。
- 长腿、增高、腿型调节。
- 支持实时相机预览和静态图片处理。

### 美妆

美妆能力采用“样式 + 强度”的控制方式：

- 眉毛、眼妆、美瞳、腮红、口红预设。
- 每个美妆类别都支持独立强度调节。
- 适合在 App 中快速搭建紧凑的美妆面板和预设切换。

### 渲染链路

- 直接处理相机帧中的 `CVPixelBuffer`。
- 支持原地渲染和返回输出 buffer 两种方式。
- 适用于相机预览、短视频拍摄和图片美化流程。

### 多人脸

UyaliBeautySDK 支持基于人脸的多人脸美颜和美型处理，同一帧中出现多张人脸时也可以进行处理。

## 效果展示

演示素材来自网络，若有版权问题，请联系维护者删除。

### 美型

| 瘦脸 | 下巴 | 眼距 |
| :--: | :--: | :--: |
| ![face_thin](gif/face_thin.gif) | ![chin](gif/chin.gif) | ![eye_distance](gif/eye_distance.gif) |

| 瘦鼻 | 眉间距 |
| :--: | :--: |
| ![nose_thin](gif/nose_thin.gif) | ![eyebrow_distance](gif/eyebrow_distance.gif) |

### 美妆

| 眉毛 | 口红 |
| :--: | :--: |
| ![makeup_eyebrow](gif/makeup_eyebrow.gif) | ![makeup_rouge](gif/makeup_rouge.gif) |

## iOS 安装

### Swift Package Manager

在 Xcode 中选择 `File > Add Package Dependencies...`，输入：

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

然后导入 SDK：

```swift
import UyaliBeautySDK
```

### CocoaPods

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

### 手动集成

将 `UyaliBeautySDK.xcframework` 拖入你的 iOS 项目，并设置为 `Embed & Sign`。

## 快速开始

创建一个 `UyaliBeautyEngine` 实例，并在相机或图片处理链路中复用：

```swift
import UyaliBeautySDK

let beauty = UyaliBeautyEngine()

// 基础美颜
beauty.white_delta = 40
beauty.skin_delta = 40
beauty.darkCircle_delta = 35

// 美型
beauty.faceThin_delta = 30
beauty.eyeBig_delta = 20
beauty.noseThin_delta = 15

// 美体
beauty.bodySlim_delta = 25
beauty.legLong_delta = 15

// 美妆
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
beauty.makeup_rouge_delta = 60
beauty.makeup_rouge_type = .rouge_shaonvfen
```

实时相机帧可以将相机输出配置为 32-bit pixel buffer，并在采集回调中处理每一帧：

```swift
import AVFoundation
import UyaliBeautySDK

final class BeautyFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let beauty = UyaliBeautyEngine()

    override init() {
        super.init()
        beauty.white_delta = 40
        beauty.skin_delta = 40
        beauty.faceThin_delta = 30
        beauty.bodySlim_delta = 25
    }

    func configure(_ videoOutput: AVCaptureVideoDataOutput) {
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 原地处理。处理后可以直接将同一个 pixelBuffer 渲染到预览视图。
        beauty.process(pixelBuffer: pixelBuffer)

        // previewView.display(pixelBuffer)
    }
}
```

如果是图片处理，或你的链路需要单独的输出 buffer：

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

最小接入只需要调用：

```swift
beauty.process(pixelBuffer: pixelBuffer)
```

美妆效果通常需要同时设置强度和样式：

```swift
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
```

Demo 中大部分强度参数范围为 `0...100`。部分美型偏移参数，例如下巴、眼距、嘴型，使用 `-50...50` 范围。

## Demo

Demo 工程位于：

```text
iOS_demo/UyaliBeautySDKDemo
```

Demo 包含美颜、美型、美体和美妆控制。

## 运行时嵌入

如果运行时出现类似错误：

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

请确认 `UyaliBeautySDK.xcframework` 已加入 `Frameworks, Libraries, and Embedded Content`，并设置为 `Embed & Sign`。

![ios_bug](screenshot/ios_bug.png)

## 性能预览

iPhone 7 开启美颜渲染测试：

| 指标 | 预览 |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## 当前 iOS 环境要求

- iOS 12.0+
- Xcode 15+
- Swift 5+
