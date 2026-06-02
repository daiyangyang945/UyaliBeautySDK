# UyaliBeautySDK: Mobile Beauty SDK

**English** | [简体中文](README_CN.md) | [日本語](README_JP.md) | [Français](README_FR.md) | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK is a mobile beauty SDK for real-time camera frames and image processing. It provides beauty filters, face reshape, body reshape and makeup effects. The current package supports iOS.

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

- Processes `CVPixelBuffer` directly for camera frames.
- Supports in-place rendering and output-buffer rendering.
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

## iOS Installation

### Swift Package Manager

In Xcode, choose `File > Add Package Dependencies...`, then enter:

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

Import the SDK:

```swift
import UyaliBeautySDK
```

### CocoaPods

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

### Manual Integration

Drag `UyaliBeautySDK.xcframework` into your iOS project and set it to `Embed & Sign`.

## Quick Start

Create one `UyaliBeautyEngine` instance and reuse it for your camera or image pipeline:

```swift
import UyaliBeautySDK

let beauty = UyaliBeautyEngine()

// Skin beauty
beauty.white_delta = 40
beauty.skin_delta = 40
beauty.darkCircle_delta = 35

// Face reshape
beauty.faceThin_delta = 30
beauty.eyeBig_delta = 20
beauty.noseThin_delta = 15

// Body reshape
beauty.bodySlim_delta = 25
beauty.legLong_delta = 15

// Makeup
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
beauty.makeup_rouge_delta = 60
beauty.makeup_rouge_type = .rouge_shaonvfen
```

For real-time camera frames, configure your camera output as a 32-bit pixel buffer and process each frame in the capture callback:

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

        // In-place processing. Render the same pixelBuffer in your preview view.
        beauty.process(pixelBuffer: pixelBuffer)

        // previewView.display(pixelBuffer)
    }
}
```

For image workflows or pipelines that need a separate output buffer:

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

For the smallest possible integration, the core call is:

```swift
beauty.process(pixelBuffer: pixelBuffer)
```

Makeup effects usually need both intensity and style:

```swift
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
```

Most intensity values use the `0...100` range in the demo. Some reshape offsets, such as chin, eye distance and mouth shape, use a `-50...50` range.

## Demo

The demo project is located at:

```text
iOS_demo/UyaliBeautySDKDemo
```

The demo includes beauty, face reshape, body reshape and makeup controls.

## Runtime Embedding

If you see a runtime error like:

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

make sure `UyaliBeautySDK.xcframework` is added to `Frameworks, Libraries, and Embedded Content` and set to `Embed & Sign`.

![ios_bug](screenshot/ios_bug.png)

## Performance Preview

iPhone 7 test with beauty rendering enabled:

| Metric | Preview |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Current iOS Requirements

- iOS 12.0+
- Xcode 15+
- Swift 5+
