# UyaliBeautySDK：モバイル ビューティー SDK

[English](README.md) | [简体中文](README_CN.md) | **日本語** | [Français](README_FR.md) | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK は、リアルタイムのカメラフレームと画像処理に対応したモバイル ビューティー SDK です。美肌、フェイスリシェイプ、ボディリシェイプ、メイク効果を利用できます。現在利用できるパッケージは iOS に対応しています。

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

- カメラフレームの `CVPixelBuffer` を直接処理。
- インプレースレンダリングと出力 buffer の両方に対応。
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

## iOS インストール

### Swift Package Manager

Xcode で `File > Add Package Dependencies...` を選択し、次の URL を入力します。

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

SDK をインポートします。

```swift
import UyaliBeautySDK
```

### CocoaPods

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

### 手動インストール

`UyaliBeautySDK.xcframework` を iOS プロジェクトに追加し、`Embed & Sign` に設定します。

## クイックスタート

`UyaliBeautyEngine` を 1 つ作成し、カメラまたは画像処理パイプラインで再利用します。

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

リアルタイムカメラフレームでは、カメラ出力を 32-bit pixel buffer に設定し、キャプチャコールバック内で各フレームを処理します。

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

画像処理や別の出力 buffer が必要なパイプラインでは：

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

最小構成では、中心となる呼び出しは次の 1 行です。

```swift
beauty.process(pixelBuffer: pixelBuffer)
```

メイク効果では通常、強度とスタイルの両方を設定します。

```swift
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
```

デモでは多くの強度値が `0...100` の範囲です。一部の reshape オフセット、たとえば chin、eye distance、mouth shape は `-50...50` の範囲を使用します。

## Demo

デモプロジェクト：

```text
iOS_demo/UyaliBeautySDKDemo
```

デモには、美肌、フェイスリシェイプ、ボディリシェイプ、メイクの各コントロールが含まれています。

## ランタイム埋め込み

次のようなランタイムエラーが表示される場合：

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

`UyaliBeautySDK.xcframework` が `Frameworks, Libraries, and Embedded Content` に追加され、`Embed & Sign` に設定されていることを確認してください。

![ios_bug](screenshot/ios_bug.png)

## パフォーマンスプレビュー

iPhone 7 で美顔レンダリングを有効にしたテスト：

| 項目 | プレビュー |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| メモリ | ![memory](screenshot/memory.png) |
| エネルギー | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## 現在の iOS 動作環境

- iOS 12.0+
- Xcode 15+
- Swift 5+
