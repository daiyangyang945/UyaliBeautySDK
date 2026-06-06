# UyaliBeautySDK：移动端美颜 SDK

[English](README.md) | **简体中文** | [日本語](README_JP.md) | [Français](README_FR.md) | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK 是一个用于实时相机帧和图片处理的移动端美颜 SDK，提供基础美颜、美型、美体和美妆效果。目前可用包支持 iOS 和 Android。

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

- iOS 直接处理相机帧中的 `CVPixelBuffer`。
- Android 通过 OpenGL ES texture processor 处理相机/视频纹理，同时保留 CPU 帧处理作为兜底路线。
- SDK 只处理帧或纹理，不负责展示帧；预览和最终显示由宿主 App 完成。
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

## iOS

### 接入方式

Swift Package Manager：

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

```swift
import UyaliBeautySDK
```

CocoaPods：

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

手动集成：将 `UyaliBeautySDK.xcframework` 拖入 iOS 项目，并设置为 `Embed & Sign`。

### 演示代码

创建一个 `UyaliBeautyEngine` 实例，并在相机或图片处理链路中复用：

```swift
import UyaliBeautySDK

let beauty = UyaliBeautyEngine()

beauty.white_delta = 40
beauty.skin_delta = 40
beauty.faceThin_delta = 30
beauty.eyeBig_delta = 20
beauty.bodySlim_delta = 25
beauty.makeup_rouge_delta = 60
beauty.makeup_rouge_type = .rouge_shaonvfen
```

实时相机帧在采集回调里直接处理 `CVPixelBuffer`：

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    beauty.process(pixelBuffer: pixelBuffer)
}
```

图片处理或需要独立输出 buffer 的链路：

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

### 运行时嵌入

如果运行时出现类似错误：

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

请确认 `UyaliBeautySDK.xcframework` 已加入 `Frameworks, Libraries, and Embedded Content`，并设置为 `Embed & Sign`。

![ios_bug](screenshot/ios_bug.png)

### 环境要求

- iOS 12.0+
- Xcode 15+
- Swift 5+

### 性能预览

iPhone 7 开启美颜渲染测试：

| 指标 | 预览 |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Android

### 接入方式

Gradle Maven 仓库方式：

```gradle
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://raw.githubusercontent.com/daiyangyang945/UyaliBeautySDK/main/android_maven")
        }
    }
}
```

```gradle
dependencies {
    implementation "com.uyali.beauty:uyali-beauty-sdk:1.0.0"
}
```

本地 clone 仓库时，也可以指向本地目录：

```gradle
maven { url = uri("path/to/UyaliBeautySDK/android_maven") }
```

本地 AAR 文件方式：

```text
android_demo/libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

相机 App 还需要声明：

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 演示代码

Android 相机推荐走 GPU 纹理处理。宿主 App 负责提供相机或视频纹理，SDK 返回处理后的纹理；完整 Camera2、`SurfaceTexture` 和 renderer 接线可以直接看 demo。

最小纹理入口：

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

UyaliBeautyTextureFrame frame = beauty.process(oesTextureId);
int outputTextureId = frame.textureId();
```

如果你的渲染链路已经有 transform、输入尺寸、输出尺寸、时间戳和前后摄信息，可以显式传入：

```java
UyaliBeautyTextureFrame frame = beauty.process(
        UyaliBeautyTextureInput.externalOes(
                oesTextureId,
                transform,
                outputWidth,
                outputHeight,
                sourceWidth,
                sourceHeight,
                frontCamera,
                timestampNs,
                true));
int outputTextureId = frame.textureId();
```

宿主 App 使用自己的 renderer 绘制 `outputTextureId`，或者送入编码 Surface。

### 参数调整

大部分强度参数使用 `0...100`。部分美型偏移参数，例如下巴、眼距、嘴型，使用 `-50...50`。

```java
UyaliBeautyEngine engine = beauty.engine();

engine.setWhiteDelta(40f);
engine.setSkinDelta(35f);
engine.setEyeBrightDelta(20f);
engine.setTeethBrightDelta(20f);

engine.setFaceThinDelta(30f);
engine.setEyeBigDelta(20f);
engine.setNoseThinDelta(15f);

engine.setBodySlimDelta(25f);
engine.setLegLongDelta(15f);

engine.setMakeupRougeDelta(60f);
engine.setMakeupRougeType(UyaliMakeupCatalog.ROUGE_TYPES[0]);
```

### CPU 帧处理兜底

如果某些设备或管线不适合走纹理处理，可以用 CPU 帧处理：

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
processor.engine().setWhiteDelta(40f);
processor.engine().setSkinDelta(35f);

UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

### 环境要求

- Android minSdk 26+
- Android Gradle Plugin 8+
- 支持 OpenGL ES 的渲染链路

## Demo 工程

```text
iOS_demo/UyaliBeautySDKDemo
android_demo
```

Demo 包含美颜、美型、美体和美妆控制。
