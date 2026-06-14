# UyaliBeautySDK: Mobile Beauty SDK

**English** | [简体中文](README_CN.md) | [日本語](README_JP.md) | [Français](README_FR.md) | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK is a mobile beauty SDK for real-time camera frames and image processing. It provides beauty filters, face reshape, body reshape and makeup effects. The current package supports iOS, Android and HarmonyOS.

If this project helps you, a star would be appreciated.

## Features

### Skin Beauty

UyaliBeautySDK provides common portrait retouching controls for real-time camera and image workflows:

- Whitening and skin smoothing for natural skin enhancement.
- Bright eyes and teeth whitening for local detail enhancement.
- Dark circle reduction for face-area refinement.
- Independent intensity values for each effect, making it easy to build presets or user-controlled sliders.

### Face Reshape

Face reshape effects cover both overall face contour and local facial features:

- Overall shape: head reduction, slim face, narrow face, V face and small face.
- Facial contour: chin, forehead and cheekbone adjustment.
- Eyes and brows: eye enlargement, eye distance, eye corner, lower eyelid, eyebrow distance and eyebrow thickness.
- Nose and mouth: nose slimming, nose wing, nose length, nose root and mouth shape adjustment.

### Body Reshape

Body reshape effects are designed for portrait and full-body scenarios:

- Body, waist, leg, arm, calf and abdomen slimming.
- Narrow shoulders, shoulder shape and neck length adjustment.
- Long legs, body height and leg shape adjustment.
- Real-time camera preview and static image processing support.

### Makeup

Makeup effects use a style plus intensity workflow:

- Eyebrow, eyeshadow, pupil, blush and lipstick presets.
- Independent intensity control for each makeup category.
- Preset-based style switching for building compact makeup panels in apps.

### Rendering Workflow

- iOS processes `CVPixelBuffer` directly for camera frames.
- Android processes camera/video textures through an OpenGL ES texture processor, with CPU frame processing kept as a fallback path.
- The SDK only processes frames or textures. Preview display stays in the host app.
- Suitable for camera preview, short-video capture and photo beautification flows.

### Multi-face

UyaliBeautySDK supports multi-face processing for face-based beauty and reshape effects, so the same camera frame can handle more than one visible face.

## Showcase

Demo materials are sourced from the internet. If there are copyright concerns, please contact the maintainer for removal.

### Face Reshape

| Face | Chin | Eye Distance |
| :--: | :--: | :--: |
| ![face_thin](gif/face_thin.gif) | ![chin](gif/chin.gif) | ![eye_distance](gif/eye_distance.gif) |

| Nose | Eyebrow Distance |
| :--: | :--: |
| ![nose_thin](gif/nose_thin.gif) | ![eyebrow_distance](gif/eyebrow_distance.gif) |

### Makeup

| Eyebrow | Lipstick |
| :--: | :--: |
| ![makeup_eyebrow](gif/makeup_eyebrow.gif) | ![makeup_rouge](gif/makeup_rouge.gif) |

## iOS

### Integration

Swift Package Manager:

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

```swift
import UyaliBeautySDK
```

CocoaPods:

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

Manual integration: drag `UyaliBeautySDK.xcframework` into your iOS project and set it to `Embed & Sign`.

### Demo Code

Create one `UyaliBeautyEngine` instance and reuse it for camera or image processing:

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

For real-time camera frames, process the `CVPixelBuffer` in the capture callback:

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    beauty.process(pixelBuffer: pixelBuffer)
}
```

For image workflows or pipelines that need a separate output buffer:

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

### Runtime Embedding

If you see a runtime error like:

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

make sure `UyaliBeautySDK.xcframework` is added to `Frameworks, Libraries, and Embedded Content` and set to `Embed & Sign`.

![ios_bug](screenshot/ios_bug.png)

### Environment Requirements

- iOS 12.0+
- Xcode 15+
- Swift 5+

### Performance Preview

iPhone 7 test with beauty rendering enabled:

| Metric | Preview |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Android

### Integration

Gradle Maven repository:

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

For a local checkout, point the Maven repository to the local folder instead:

```gradle
maven { url = uri("path/to/UyaliBeautySDK/android_maven") }
```

Local AAR file:

```text
android_demo/libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

Camera apps also need:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### Demo Code

The recommended Android camera path is GPU texture processing. Your app provides the camera or video texture, and the SDK returns a processed texture. The demo contains the full Camera2, `SurfaceTexture` and renderer wiring.

Minimal texture entry:

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

beauty.process(oesTextureId);
int outputTextureId = beauty.outputTextureId();
```

If your renderer already tracks the transform, source size, output size, timestamp and camera direction, pass them explicitly:

```java
beauty.process(
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
int outputTextureId = beauty.outputTextureId();
```

Draw `outputTextureId` with your own renderer or send it to your encoder surface. For preview-only hosts, the SDK can also draw directly into the currently bound framebuffer:

```java
beauty.processToCurrentFramebuffer(oesTextureId);
```

`processToCurrentFramebuffer(...)` uses the same texture frame processor, but it does not produce `outputTextureId`; use `process(...)` when you need to preview later, encode, stream, or compose the processed texture.

### Parameter Control

Most intensities use `0...100`. Some reshape offsets, such as chin, eye distance and mouth shape, use `-50...50`.

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

### CPU Frame Fallback

Use the CPU frame processor for devices or pipelines where texture processing is not available:

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
processor.engine().setWhiteDelta(40f);
processor.engine().setSkinDelta(35f);

UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

### Environment Requirements

- Android minSdk 26+
- Android Gradle Plugin 8+
- OpenGL ES-capable rendering pipeline

## HarmonyOS

### Integration

Local HAR package:

```json5
{
  "dependencies": {
    "uyali_beauty_sdk": "file:../../harmony_sdk/uyali_beauty_sdk.har"
  }
}
```

Registry package:

```json5
{
  "dependencies": {
    "uyali_beauty_sdk": "1.0.0"
  }
}
```

Enable normalized OHM URLs in the project-level `build-profile.json5` product build options, then run `ohpm install`.

### Demo Code

```ts
import { UyaliBeautyEngine } from 'uyali_beauty_sdk';

const beauty = new UyaliBeautyEngine(context);
beauty.setParameter('white', 40);
beauty.setParameter('skin', 35);
beauty.setParameter('faceThin', 30);

await beauty.processPixelMapInPlace(pixelMap);
```

See `harmony_sdk/README.md` and `harmony_demo/README.md` for local HAR and registry import examples.

### Environment Requirements

- HarmonyOS 5.0+
- DevEco Studio or HarmonyOS command-line tools compatible with compileSdkVersion `6.0.2(22)`

## Demo Projects

```text
iOS_demo/UyaliBeautySDKDemo
android_demo
harmony_demo
```

The demos include beauty, face reshape, body reshape and makeup controls.
