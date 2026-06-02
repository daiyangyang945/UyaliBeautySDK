# UyaliBeautySDK: 모바일 뷰티 SDK

[English](README.md) | [简体中文](README_CN.md) | [日本語](README_JP.md) | [Français](README_FR.md) | [Deutsch](README_DE.md) | **한국어**

UyaliBeautySDK는 실시간 카메라 프레임과 이미지 처리를 위한 모바일 뷰티 SDK입니다. 뷰티 필터, 얼굴 보정, 바디 보정, 메이크업 효과를 제공합니다. 현재 제공되는 패키지는 iOS를 지원합니다.

이 프로젝트가 도움이 되었다면 star로 응원해 주세요.

## 기능

### 피부 뷰티

UyaliBeautySDK는 실시간 카메라와 이미지 처리에 사용할 수 있는 기본적인 인물 보정 기능을 제공합니다.

- 미백과 피부 보정으로 자연스러운 피부 표현을 지원합니다.
- 눈 밝기와 치아 미백으로 국소 디테일을 개선합니다.
- 다크서클 완화로 얼굴 영역을 세밀하게 보정합니다.
- 각 효과는 독립적인 강도 값을 제공하여 프리셋이나 사용자 슬라이더를 만들기 쉽습니다.

### 얼굴 보정

얼굴 보정 효과는 전체 얼굴 윤곽과 국소 얼굴 부위를 모두 다룹니다.

- 전체 형태: 머리 축소, 얼굴 슬림, 좁은 얼굴, V라인, 작은 얼굴.
- 윤곽: 턱, 이마, 광대 조절.
- 눈과 눈썹: 큰 눈, 눈 간격, 눈꼬리, 아래 눈꺼풀, 눈썹 간격, 눈썹 두께.
- 코와 입: 코 슬림, 콧볼, 코 길이, 콧대, 입 모양 조절.

### 바디 보정

바디 보정 효과는 인물과 전신 이미지 시나리오에 맞춰 설계되었습니다.

- 몸, 허리, 다리, 팔, 종아리, 복부 슬림.
- 좁은 어깨, 어깨 모양, 목 길이 조절.
- 긴 다리, 키, 다리 모양 조절.
- 실시간 카메라 미리보기와 정적 이미지 처리 지원.

### 메이크업

메이크업 효과는 스타일과 강도를 함께 설정하는 방식입니다.

- 눈썹, 아이섀도, 렌즈, 블러셔, 립 프리셋.
- 각 메이크업 카테고리별 독립 강도 조절.
- 앱에서 compact한 메이크업 패널과 프리셋 전환을 만들기 좋습니다.

### 렌더링 워크플로우

- 카메라 프레임의 `CVPixelBuffer`를 직접 처리합니다.
- 인플레이스 렌더링과 출력 buffer 렌더링을 모두 지원합니다.
- 카메라 미리보기, 숏폼 영상 촬영, 사진 보정 흐름에 적합합니다.

### 다중 얼굴

UyaliBeautySDK는 얼굴 기반 뷰티와 얼굴 보정 효과에서 다중 얼굴 처리를 지원하여, 한 프레임에 여러 얼굴이 보여도 처리할 수 있습니다.

## 쇼케이스

데모 자료는 인터넷에서 가져온 자료입니다. 저작권 문제가 있다면 유지관리자에게 연락해 주세요.

### 얼굴 보정

| 얼굴 슬림 | 턱 | 눈 간격 |
| :--: | :--: | :--: |
| ![face_thin](gif/face_thin.gif) | ![chin](gif/chin.gif) | ![eye_distance](gif/eye_distance.gif) |

| 코 | 눈썹 간격 |
| :--: | :--: |
| ![nose_thin](gif/nose_thin.gif) | ![eyebrow_distance](gif/eyebrow_distance.gif) |

### 메이크업

| 눈썹 | 립 |
| :--: | :--: |
| ![makeup_eyebrow](gif/makeup_eyebrow.gif) | ![makeup_rouge](gif/makeup_rouge.gif) |

## iOS 설치

### Swift Package Manager

Xcode에서 `File > Add Package Dependencies...`를 선택하고 다음 URL을 입력합니다.

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

SDK를 import합니다.

```swift
import UyaliBeautySDK
```

### CocoaPods

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

### 수동 연동

`UyaliBeautySDK.xcframework`를 iOS 프로젝트에 추가하고 `Embed & Sign`으로 설정합니다.

## 빠른 시작

`UyaliBeautyEngine` 인스턴스를 하나 만들고 카메라 또는 이미지 처리 파이프라인에서 재사용합니다.

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

실시간 카메라 프레임은 카메라 출력을 32-bit pixel buffer로 설정하고 캡처 콜백에서 각 프레임을 처리합니다.

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

이미지 처리 또는 별도 출력 buffer가 필요한 파이프라인에서는:

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

최소 연동에서 핵심 호출은 다음과 같습니다.

```swift
beauty.process(pixelBuffer: pixelBuffer)
```

메이크업 효과는 보통 강도와 스타일을 함께 설정합니다.

```swift
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
```

데모의 대부분 강도 값은 `0...100` 범위입니다. 턱, 눈 거리, 입 모양 같은 일부 reshape offset은 `-50...50` 범위를 사용합니다.

## Demo

데모 프로젝트 위치:

```text
iOS_demo/UyaliBeautySDKDemo
```

데모에는 뷰티, 얼굴 보정, 바디 보정, 메이크업 컨트롤이 포함되어 있습니다.

## 런타임 임베딩

다음과 같은 런타임 오류가 표시되는 경우:

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

`UyaliBeautySDK.xcframework`가 `Frameworks, Libraries, and Embedded Content`에 추가되어 있고 `Embed & Sign`으로 설정되어 있는지 확인하세요.

![ios_bug](screenshot/ios_bug.png)

## 성능 미리보기

iPhone 7에서 뷰티 렌더링을 활성화한 테스트:

| 지표 | 미리보기 |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| 메모리 | ![memory](screenshot/memory.png) |
| 에너지 | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## 현재 iOS 요구 사항

- iOS 12.0+
- Xcode 15+
- Swift 5+
