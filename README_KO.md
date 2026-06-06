# UyaliBeautySDK: 모바일 뷰티 SDK

[English](README.md) | [简体中文](README_CN.md) | [日本語](README_JP.md) | [Français](README_FR.md) | [Deutsch](README_DE.md) | **한국어**

UyaliBeautySDK는 실시간 카메라 프레임과 이미지 처리를 위한 모바일 뷰티 SDK입니다. 뷰티 필터, 얼굴 보정, 바디 보정, 메이크업 효과를 제공합니다. 현재 제공되는 패키지는 iOS와 Android를 지원합니다.

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

- iOS는 카메라 프레임의 `CVPixelBuffer`를 직접 처리합니다.
- Android는 OpenGL ES texture processor로 카메라/비디오 텍스처를 처리하며, CPU 프레임 처리 경로도 fallback으로 유지합니다.
- SDK는 프레임 또는 텍스처만 처리합니다. 미리보기와 최종 표시는 호스트 앱이 담당합니다.
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

## iOS

### 연동 방식

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

수동 연동: `UyaliBeautySDK.xcframework`를 iOS 프로젝트에 드래그한 뒤 `Embed & Sign`으로 설정합니다.

### 데모 코드

`UyaliBeautyEngine` 인스턴스를 하나 생성하고 카메라 또는 이미지 처리 흐름에서 재사용합니다.

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

실시간 카메라 프레임은 캡처 콜백에서 `CVPixelBuffer`를 직접 처리합니다.

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    beauty.process(pixelBuffer: pixelBuffer)
}
```

이미지 워크플로우 또는 별도 출력 buffer가 필요한 파이프라인에서는 다음처럼 사용합니다.

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

### 런타임 임베딩

런타임에 다음과 같은 오류가 나타나면:

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

`UyaliBeautySDK.xcframework`가 `Frameworks, Libraries, and Embedded Content`에 추가되어 있고 `Embed & Sign`으로 설정되어 있는지 확인하세요.

![ios_bug](screenshot/ios_bug.png)

### 환경 요구 사항

- iOS 12.0+
- Xcode 15+
- Swift 5+

### 성능 미리보기

뷰티 렌더링을 켠 iPhone 7 테스트:

| Metric | Preview |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Android

### 연동 방식

Gradle Maven 저장소:

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

로컬 checkout에서는 Maven 저장소를 로컬 폴더로 지정할 수도 있습니다.

```gradle
maven { url = uri("path/to/UyaliBeautySDK/android_maven") }
```

로컬 AAR 파일:

```text
android_demo/libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

카메라 앱은 다음 권한도 선언해야 합니다.

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 데모 코드

Android 카메라 연동은 GPU 텍스처 처리를 권장합니다. 호스트 앱이 카메라 또는 비디오 텍스처를 전달하면 SDK가 처리된 텍스처를 반환합니다. 전체 Camera2, `SurfaceTexture`, renderer 연결은 demo에 포함되어 있습니다.

최소 텍스처 입력:

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

UyaliBeautyTextureFrame frame = beauty.process(oesTextureId);
int outputTextureId = frame.textureId();
```

renderer가 transform, 입력 크기, 출력 크기, 타임스탬프, 카메라 방향을 이미 관리한다면 명시적으로 전달할 수 있습니다.

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

`outputTextureId`는 호스트 앱의 renderer로 그리거나 encoder surface로 보냅니다.

### 파라미터 조정

대부분의 강도 값은 `0...100`을 사용합니다. 턱, 눈 간격, 입 모양 같은 일부 보정 offset은 `-50...50`을 사용합니다.

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

### CPU 프레임 폴백

텍스처 처리를 사용할 수 없는 기기나 파이프라인에서는 CPU 프레임 processor를 사용할 수 있습니다.

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
processor.engine().setWhiteDelta(40f);
processor.engine().setSkinDelta(35f);

UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

### 환경 요구 사항

- Android minSdk 26+
- Android Gradle Plugin 8+
- OpenGL ES를 지원하는 렌더링 파이프라인

## 데모 프로젝트

```text
iOS_demo/UyaliBeautySDKDemo
android_demo
```

demo에는 뷰티, 얼굴 보정, 바디 보정, 메이크업 컨트롤이 포함되어 있습니다.
