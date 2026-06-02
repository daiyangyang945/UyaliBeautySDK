# UyaliBeautySDK : SDK beauté mobile

[English](README.md) | [简体中文](README_CN.md) | [日本語](README_JP.md) | **Français** | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK est un SDK beauté mobile pour le traitement d'images et de flux caméra en temps réel. Il propose des filtres beauté, des effets de remodelage du visage, de remodelage du corps et de maquillage. Le package actuellement disponible prend en charge iOS.

Si ce projet vous aide, un star serait apprécié.

## Fonctionnalités

### Beauté de la Peau

UyaliBeautySDK fournit des contrôles de retouche portrait pour les flux caméra en temps réel et le traitement d'images :

- Éclaircissement et lissage de la peau pour un rendu naturel.
- Yeux plus lumineux et dents plus blanches pour améliorer les détails locaux.
- Réduction des cernes pour affiner certaines zones du visage.
- Intensité indépendante pour chaque effet, pratique pour créer des presets ou des curseurs utilisateur.

### Remodelage du Visage

Les effets de remodelage couvrent le contour global du visage et les éléments locaux :

- Forme globale : réduction de la tête, visage affiné, visage plus étroit, visage en V et petit visage.
- Contour : menton, front et pommettes.
- Yeux et sourcils : agrandissement des yeux, distance des yeux, coin des yeux, paupière inférieure, distance et épaisseur des sourcils.
- Nez et bouche : nez affiné, ailes du nez, longueur du nez, racine du nez et forme de la bouche.

### Remodelage du Corps

Les effets de remodelage du corps sont conçus pour les portraits et les scènes en pied :

- Amincissement du corps, de la taille, des jambes, des bras, des mollets et de l'abdomen.
- Épaules plus étroites, forme des épaules et longueur du cou.
- Jambes plus longues, hauteur du corps et forme des jambes.
- Prise en charge de l'aperçu caméra en temps réel et du traitement d'images statiques.

### Maquillage

Les effets de maquillage utilisent un modèle basé sur le style et l'intensité :

- Presets pour sourcils, fard à paupières, lentilles, blush et rouge à lèvres.
- Contrôle indépendant de l'intensité pour chaque catégorie.
- Pratique pour construire des panneaux de maquillage compacts et des presets dans une application.

### Workflow de Rendu

- Traitement direct du `CVPixelBuffer` des frames caméra.
- Rendu en place ou rendu avec buffer de sortie.
- Adapté aux aperçus caméra, à la capture vidéo courte et à la retouche photo.

### Multi-visage

UyaliBeautySDK prend en charge plusieurs visages pour les effets de beauté et de remodelage basés sur le visage, afin de traiter plusieurs visages visibles dans une même frame.

## Aperçu

Les supports de démonstration proviennent d'internet. En cas de problème de droits, veuillez contacter le mainteneur pour suppression.

### Remodelage du Visage

| Visage affiné | Menton | Distance des yeux |
| :--: | :--: | :--: |
| ![face_thin](gif/face_thin.gif) | ![chin](gif/chin.gif) | ![eye_distance](gif/eye_distance.gif) |

| Nez | Distance des sourcils |
| :--: | :--: |
| ![nose_thin](gif/nose_thin.gif) | ![eyebrow_distance](gif/eyebrow_distance.gif) |

### Maquillage

| Sourcils | Rouge à lèvres |
| :--: | :--: |
| ![makeup_eyebrow](gif/makeup_eyebrow.gif) | ![makeup_rouge](gif/makeup_rouge.gif) |

## Installation iOS

### Swift Package Manager

Dans Xcode, choisissez `File > Add Package Dependencies...`, puis saisissez :

```text
https://github.com/daiyangyang945/UyaliBeautySDK.git
```

Importez le SDK :

```swift
import UyaliBeautySDK
```

### CocoaPods

```ruby
pod 'UyaliBeautySDK', :git => 'https://github.com/daiyangyang945/UyaliBeautySDK.git'
```

### Intégration Manuelle

Ajoutez `UyaliBeautySDK.xcframework` à votre projet iOS et définissez-le sur `Embed & Sign`.

## Démarrage Rapide

Créez une instance de `UyaliBeautyEngine` et réutilisez-la dans votre pipeline caméra ou image :

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

Pour les frames caméra en temps réel, configurez la sortie caméra en pixel buffer 32-bit et traitez chaque frame dans le callback de capture :

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

Pour les workflows image ou les pipelines qui nécessitent un buffer de sortie séparé :

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

Pour l'intégration minimale, l'appel principal est :

```swift
beauty.process(pixelBuffer: pixelBuffer)
```

Les effets de maquillage utilisent généralement une intensité et un style :

```swift
beauty.makeup_eyebrow_delta = 80
beauty.makeup_eyebrow_type = .eyebrow_cupin
```

La plupart des intensités utilisées dans la démo sont dans la plage `0...100`. Certains offsets de reshape, comme le menton, la distance des yeux et la forme de la bouche, utilisent une plage `-50...50`.

## Démo

Le projet de démonstration se trouve ici :

```text
iOS_demo/UyaliBeautySDKDemo
```

La démo inclut les contrôles de beauté, de remodelage du visage, de remodelage du corps et de maquillage.

## Intégration au Runtime

Si vous voyez une erreur comme :

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

vérifiez que `UyaliBeautySDK.xcframework` est ajouté à `Frameworks, Libraries, and Embedded Content` et défini sur `Embed & Sign`.

![ios_bug](screenshot/ios_bug.png)

## Aperçu des Performances

Test iPhone 7 avec rendu beauté activé :

| Métrique | Aperçu |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Mémoire | ![memory](screenshot/memory.png) |
| Énergie | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Prérequis iOS Actuels

- iOS 12.0+
- Xcode 15+
- Swift 5+
