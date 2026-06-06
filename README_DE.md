# UyaliBeautySDK: Mobile Beauty SDK

[English](README.md) | [简体中文](README_CN.md) | [日本語](README_JP.md) | [Français](README_FR.md) | **Deutsch** | [한국어](README_KO.md)

UyaliBeautySDK ist ein Mobile Beauty SDK für Echtzeit-Kameraframes und Bildverarbeitung. Es bietet Beauty-Filter, Face Reshape, Body Reshape und Make-up-Effekte. Das aktuell verfügbare Paket unterstützt iOS und Android.

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

- iOS verarbeitet `CVPixelBuffer` aus Kameraframes direkt.
- Android verarbeitet Kamera-/Videotexturen über einen OpenGL ES texture processor; CPU-Frameverarbeitung bleibt als Fallback erhalten.
- Das SDK verarbeitet nur Frames oder Texturen. Vorschau und finale Anzeige bleiben in der Host-App.
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

Manuelle Integration: Ziehe `UyaliBeautySDK.xcframework` in dein iOS-Projekt und setze es auf `Embed & Sign`.

### Demo-Code

Erstelle eine `UyaliBeautyEngine`-Instanz und verwende sie für Kamera- oder Bildverarbeitung wieder:

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

Für Echtzeit-Kameraframes verarbeitest du den `CVPixelBuffer` direkt im Capture-Callback:

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    beauty.process(pixelBuffer: pixelBuffer)
}
```

Für Bild-Workflows oder Pipelines, die einen separaten Output-Buffer benötigen:

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

### Runtime-Einbettung

Wenn zur Laufzeit ein Fehler wie dieser erscheint:

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

stelle sicher, dass `UyaliBeautySDK.xcframework` unter `Frameworks, Libraries, and Embedded Content` hinzugefügt und auf `Embed & Sign` gesetzt ist.

![ios_bug](screenshot/ios_bug.png)

### Anforderungen

- iOS 12.0+
- Xcode 15+
- Swift 5+

### Leistungsvorschau

iPhone-7-Test mit aktiviertem Beauty-Rendering:

| Metric | Preview |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Android

### Integration

Gradle-Maven-Repository:

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

Bei einem lokalen Checkout kannst du das Maven-Repository stattdessen auf den lokalen Ordner verweisen lassen:

```gradle
maven { url = uri("path/to/UyaliBeautySDK/android_maven") }
```

Lokale AAR-Datei:

```text
android_demo/libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

Kamera-Apps benötigen außerdem:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### Demo-Code

Der empfohlene Android-Kamerapfad ist GPU-Texturverarbeitung. Die Host-App übergibt die Kamera- oder Videotextur, und das SDK gibt eine verarbeitete Textur zurück. Das Demo enthält die vollständige Camera2-, `SurfaceTexture`- und Renderer-Verkabelung.

Minimaler Texture-Einstieg:

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

UyaliBeautyTextureFrame frame = beauty.process(oesTextureId);
int outputTextureId = frame.textureId();
```

Wenn dein Renderer Transform, Quellgröße, Ausgabegröße, Zeitstempel und Kamerarichtung bereits kennt, kannst du sie explizit übergeben:

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

Zeichne `outputTextureId` mit deinem eigenen Renderer oder sende es an deine Encoder-Surface.

### Parametersteuerung

Die meisten Intensitäten verwenden `0...100`. Einige Reshape-Offsets wie Kinn, Augenabstand und Mundform verwenden `-50...50`.

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

### CPU-Frame-Fallback

Verwende den CPU-Frame-Prozessor für Geräte oder Pipelines, in denen Texturverarbeitung nicht verfügbar ist:

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
processor.engine().setWhiteDelta(40f);
processor.engine().setSkinDelta(35f);

UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

### Anforderungen

- Android minSdk 26+
- Android Gradle Plugin 8+
- OpenGL-ES-fähige Rendering-Pipeline

## Demo-Projekte

```text
iOS_demo/UyaliBeautySDKDemo
android_demo
```

Die Demos enthalten Controls für Beauty, Face Reshape, Body Reshape und Make-up.
