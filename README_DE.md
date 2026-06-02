# UyaliBeautySDK: Mobile Beauty SDK

[English](README.md) | [简体中文](README_CN.md) | [日本語](README_JP.md) | [Français](README_FR.md) | **Deutsch** | [한국어](README_KO.md)

UyaliBeautySDK ist ein Mobile Beauty SDK für Echtzeit-Kameraframes und Bildverarbeitung. Es bietet Beauty-Filter, Face Reshape, Body Reshape und Make-up-Effekte. Das aktuell verfügbare Paket unterstützt iOS.

Wenn dir dieses Projekt hilft, freuen wir uns über einen star.

## Funktionen

### Haut-Beauty

UyaliBeautySDK bietet typische Portrait-Retouching-Funktionen für Echtzeitkamera und Bildverarbeitung:

- Hautaufhellung und Hautglättung für eine natürliche Hautverbesserung.
- Hellere Augen und weißere Zähne zur lokalen Detailverbesserung.
- Reduktion von Augenringen für feinere Gesichtskorrekturen.
- Unabhängige Intensitätswerte für jeden Effekt, ideal für Presets oder benutzersteuerbare Slider.

### Face Reshape

Face-Reshape-Effekte decken sowohl die gesamte Gesichtsform als auch lokale Gesichtspartien ab:

- Gesamtform: Kopfverkleinerung, schlankes Gesicht, schmales Gesicht, V-Gesicht und kleines Gesicht.
- Kontur: Kinn, Stirn und Wangenknochen.
- Augen und Brauen: größere Augen, Augenabstand, Augenwinkel, unteres Augenlid, Brauenabstand und Brauenstärke.
- Nase und Mund: schmalere Nase, Nasenflügel, Nasenlänge, Nasenwurzel und Mundform.

### Body Reshape

Body-Reshape-Effekte sind für Portraits und Ganzkörperaufnahmen gedacht:

- Körper-, Taillen-, Bein-, Arm-, Waden- und Bauchverschlankung.
- Schmalere Schultern, Schulterform und Halslänge.
- Längere Beine, Körperhöhe und Beinform.
- Unterstützung für Echtzeit-Kameravorschau und statische Bildverarbeitung.

### Make-up

Make-up-Effekte nutzen einen Workflow aus Stil und Intensität:

- Presets für Augenbrauen, Lidschatten, Kontaktlinsen, Rouge und Lippenstift.
- Unabhängige Intensitätssteuerung für jede Kategorie.
- Geeignet für kompakte Make-up-Panels und Preset-Wechsel in Apps.

### Rendering-Workflow

- Direkte Verarbeitung von `CVPixelBuffer` aus Kameraframes.
- Unterstützung für In-Place-Rendering und Ausgabe-Buffer.
- Geeignet für Kameravorschau, Kurzvideoaufnahme und Fotoretusche.

### Mehrere Gesichter

UyaliBeautySDK unterstützt mehrere Gesichter für gesichtsbasierte Beauty- und Reshape-Effekte, sodass mehrere sichtbare Gesichter in einem Frame verarbeitet werden können.

## Vorschau

Die Demo-Materialien stammen aus dem Internet. Bei Urheberrechtsfragen wenden Sie sich bitte an den Maintainer.

### Face Reshape

| Schlankes Gesicht | Kinn | Augenabstand |
| :--: | :--: | :--: |
| ![face_thin](gif/face_thin.gif) | ![chin](gif/chin.gif) | ![eye_distance](gif/eye_distance.gif) |

| Nase | Brauenabstand |
| :--: | :--: |
| ![nose_thin](gif/nose_thin.gif) | ![eyebrow_distance](gif/eyebrow_distance.gif) |

### Make-up

| Augenbrauen | Lippenstift |
| :--: | :--: |
| ![makeup_eyebrow](gif/makeup_eyebrow.gif) | ![makeup_rouge](gif/makeup_rouge.gif) |

## iOS Installation

### Swift Package Manager

Wähle in Xcode `File > Add Package Dependencies...` und gib Folgendes ein:

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

SDK importieren:

```swift
import UyaliBeautySDK
```

### CocoaPods

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

### Manuelle Integration

Ziehe `UyaliBeautySDK.xcframework` in dein iOS-Projekt und setze es auf `Embed & Sign`.

## Schnellstart

Erstelle eine `UyaliBeautyEngine`-Instanz und verwende sie in deiner Kamera- oder Bildpipeline wieder:

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

Für Echtzeit-Kameraframes konfigurierst du den Kamera-Output als 32-bit pixel buffer und verarbeitest jeden Frame im Capture-Callback:

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

Für Bild-Workflows oder Pipelines, die einen separaten Ausgabe-Buffer benötigen:

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

Für die kleinste Integration ist der zentrale Aufruf:

```swift
beauty.process(pixelBuffer: pixelBuffer)
```

Make-up-Effekte benötigen normalerweise Intensität und Stil:

```swift
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
```

Die meisten Intensitätswerte in der Demo liegen im Bereich `0...100`. Einige Reshape-Offsets, zum Beispiel Kinn, Augenabstand und Mundform, verwenden den Bereich `-50...50`.

## Demo

Das Demo-Projekt befindet sich hier:

```text
iOS_demo/UyaliBeautySDKDemo
```

Die Demo enthält Steuerelemente für Beauty, Face Reshape, Body Reshape und Make-up.

## Runtime Embedding

Falls eine Laufzeitfehlermeldung wie diese erscheint:

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

stelle sicher, dass `UyaliBeautySDK.xcframework` unter `Frameworks, Libraries, and Embedded Content` hinzugefügt und auf `Embed & Sign` gesetzt ist.

![ios_bug](screenshot/ios_bug.png)

## Performance Preview

iPhone 7 Test mit aktiviertem Beauty Rendering:

| Metrik | Vorschau |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Speicher | ![memory](screenshot/memory.png) |
| Energie | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Aktuelle iOS Anforderungen

- iOS 12.0+
- Xcode 15+
- Swift 5+
