# UyaliBeautySDK：モバイル ビューティー SDK

[English](README.md) | [简体中文](README_CN.md) | **日本語** | [Français](README_FR.md) | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK は、リアルタイムのカメラフレームと画像処理に対応したモバイル ビューティー SDK です。美肌、フェイスリシェイプ、ボディリシェイプ、メイク効果を利用できます。現在利用できるパッケージは iOS と Android に対応しています。

このプロジェクトが役に立った場合は、star で応援していただけるとうれしいです。

## 機能

### 美肌

UyaliBeautySDK は、リアルタイムカメラと画像処理向けの一般的なポートレート補正機能を提供します。

- 美白とスキンスムージングで自然な肌質を調整。
- 目元補正と歯のホワイトニングで局所的なディテールを強調。
- クマ軽減で顔まわりを細かく補正。
- 各効果は独立した強度パラメータを持ち、プリセットやユーザー用スライダーを作りやすくなっています。

### フェイスリシェイプ

フェイスリシェイプは、顔全体の輪郭と局所的なパーツ調整をカバーします。

- 全体形状：小頭、顔やせ、細顔、V ライン、小顔。
- 輪郭：あご、額、頬骨の調整。
- 目と眉：目の拡大、目の距離、目尻、下まぶた、眉間距離、眉の太さ。
- 鼻と口：鼻やせ、小鼻、鼻の長さ、鼻根、口元の調整。

### ボディリシェイプ

ボディリシェイプは、ポートレートや全身写真のシーンに適しています。

- 体、ウエスト、脚、腕、ふくらはぎ、腹部のスリム補正。
- 肩幅、肩ライン、首の長さの調整。
- 脚長、身長、脚形の調整。
- リアルタイムカメラプレビューと静止画像処理に対応。

### メイク

メイク効果は「スタイル + 強度」のワークフローで制御します。

- 眉、アイシャドウ、カラコン、チーク、リップのプリセット。
- 各メイクカテゴリに独立した強度設定。
- アプリ内でコンパクトなメイクパネルやプリセット切り替えを作りやすい設計。

### レンダリングワークフロー

- iOS はカメラフレームの `CVPixelBuffer` を直接処理します。
- Android は OpenGL ES texture processor でカメラ/動画テクスチャを処理し、CPU フレーム処理をフォールバックとして残しています。
- SDK はフレームまたはテクスチャだけを処理します。プレビュー表示はホストアプリ側で行います。
- カメラプレビュー、ショート動画撮影、写真加工フローに適しています。

### 複数顔

UyaliBeautySDK は、顔ベースの美肌およびリシェイプ効果で複数人の顔をサポートし、同じフレーム内に複数の顔がある場合にも処理できます。

## ショーケース

デモ素材はインターネット上の素材を使用しています。著作権上の問題がある場合は、メンテナーまでご連絡ください。

### フェイスリシェイプ

| 顔やせ | あご | 目の距離 |
| :--: | :--: | :--: |
| ![face_thin](gif/face_thin.gif) | ![chin](gif/chin.gif) | ![eye_distance](gif/eye_distance.gif) |

| 鼻 | 眉間距離 |
| :--: | :--: |
| ![nose_thin](gif/nose_thin.gif) | ![eyebrow_distance](gif/eyebrow_distance.gif) |

### メイク

| 眉 | リップ |
| :--: | :--: |
| ![makeup_eyebrow](gif/makeup_eyebrow.gif) | ![makeup_rouge](gif/makeup_rouge.gif) |

## iOS

### 接続方法

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

手動連携：`UyaliBeautySDK.xcframework` を iOS プロジェクトにドラッグし、`Embed & Sign` に設定します。

### デモコード

`UyaliBeautyEngine` インスタンスを 1 つ作成し、カメラ処理または画像処理で再利用します。

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

リアルタイムカメラフレームでは、キャプチャコールバック内で `CVPixelBuffer` を直接処理します。

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    beauty.process(pixelBuffer: pixelBuffer)
}
```

画像処理、または独立した出力 buffer が必要なパイプラインでは次のように使います。

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

### 実行時埋め込み

実行時に次のようなエラーが出る場合：

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

`UyaliBeautySDK.xcframework` が `Frameworks, Libraries, and Embedded Content` に追加され、`Embed & Sign` に設定されていることを確認してください。

![ios_bug](screenshot/ios_bug.png)

### 環境要件

- iOS 12.0+
- Xcode 15+
- Swift 5+

### パフォーマンスプレビュー

美肌レンダリングを有効にした iPhone 7 でのテスト：

| Metric | Preview |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Android

### 接続方法

Gradle Maven リポジトリ：

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

ローカル checkout では、Maven リポジトリをローカルフォルダに向けることもできます。

```gradle
maven { url = uri("path/to/UyaliBeautySDK/android_maven") }
```

ローカル AAR ファイル：

```text
android_demo/libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

カメラアプリでは次の権限も必要です。

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### デモコード

Android のカメラ連携では GPU テクスチャ処理を推奨します。ホストアプリがカメラまたは動画テクスチャを渡し、SDK は処理後のテクスチャを返します。Camera2、`SurfaceTexture`、renderer の接続は demo に含まれています。

最小のテクスチャ入力：

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

UyaliBeautyTextureFrame frame = beauty.process(oesTextureId);
int outputTextureId = frame.textureId();
```

renderer 側で transform、入力サイズ、出力サイズ、タイムスタンプ、カメラ向きを管理している場合は、明示的に渡せます。

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

`outputTextureId` はホストアプリ自身の renderer で描画するか、encoder surface に送ります。

### パラメータ調整

多くの強度パラメータは `0...100` を使用します。あご、目の距離、口元など一部のリシェイプ offset は `-50...50` を使用します。

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

### CPU フレームフォールバック

テクスチャ処理を使えないデバイスやパイプラインでは、CPU フレーム processor を使用できます。

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
processor.engine().setWhiteDelta(40f);
processor.engine().setSkinDelta(35f);

UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

### 環境要件

- Android minSdk 26+
- Android Gradle Plugin 8+
- OpenGL ES に対応したレンダリングパイプライン

## デモプロジェクト

```text
iOS_demo/UyaliBeautySDKDemo
android_demo
```

demo には美肌、フェイスリシェイプ、ボディリシェイプ、メイクのコントロールが含まれています。
