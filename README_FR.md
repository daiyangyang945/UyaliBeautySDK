# UyaliBeautySDK : SDK beauté mobile

[English](README.md) | [简体中文](README_CN.md) | [日本語](README_JP.md) | **Français** | [Deutsch](README_DE.md) | [한국어](README_KO.md)

UyaliBeautySDK est un SDK beauté mobile pour le traitement d'images et de flux caméra en temps réel. Il propose des filtres beauté, des effets de remodelage du visage, de remodelage du corps et de maquillage. Le package actuellement disponible prend en charge iOS et Android.

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

- iOS traite directement le `CVPixelBuffer` des frames caméra.
- Android traite les textures caméra/vidéo via un texture processor OpenGL ES, avec un chemin CPU conservé comme fallback.
- Le SDK traite uniquement les frames ou textures. L'aperçu et l'affichage final restent dans l'application hôte.
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

## iOS

### Intégration

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

Intégration manuelle : glissez `UyaliBeautySDK.xcframework` dans votre projet iOS et définissez-le sur `Embed & Sign`.

### Code de démonstration

Créez une seule instance de `UyaliBeautyEngine` et réutilisez-la pour la caméra ou le traitement d'image :

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

Pour les frames caméra en temps réel, traitez le `CVPixelBuffer` dans le callback de capture :

```swift
func captureOutput(_ output: AVCaptureOutput,
                   didOutput sampleBuffer: CMSampleBuffer,
                   from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    beauty.process(pixelBuffer: pixelBuffer)
}
```

Pour les workflows image ou les pipelines qui nécessitent un buffer de sortie séparé :

```swift
let processedPixelBuffer = beauty.processWithOutput(pixelBuffer: inputPixelBuffer)
```

### Intégration au runtime

Si vous voyez une erreur d'exécution comme :

```text
Library not loaded: @rpath/UyaliBeautySDK.framework/UyaliBeautySDK
```

vérifiez que `UyaliBeautySDK.xcframework` est ajouté à `Frameworks, Libraries, and Embedded Content` et défini sur `Embed & Sign`.

![ios_bug](screenshot/ios_bug.png)

### Prérequis

- iOS 12.0+
- Xcode 15+
- Swift 5+

### Aperçu des performances

Test sur iPhone 7 avec le rendu beauté activé :

| Metric | Preview |
| :--: | :--: |
| CPU | ![cpu](screenshot/cpu.png) |
| Memory | ![memory](screenshot/memory.png) |
| Energy | ![energy](screenshot/energy.png) |
| GPU | ![gpu](screenshot/gpu.png) |

## Android

### Intégration

Dépôt Gradle Maven :

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

Pour un checkout local, pointez plutôt le dépôt Maven vers le dossier local :

```gradle
maven { url = uri("path/to/UyaliBeautySDK/android_maven") }
```

Fichier AAR local :

```text
android_demo/libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

Les apps caméra doivent également déclarer :

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### Code de démonstration

Le chemin recommandé pour la caméra Android est le traitement de texture GPU. L'app hôte fournit la texture caméra ou vidéo, et le SDK renvoie une texture traitée. La démo contient le câblage complet Camera2, `SurfaceTexture` et renderer.

Entrée texture minimale :

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

UyaliBeautyTextureFrame frame = beauty.process(oesTextureId);
int outputTextureId = frame.textureId();
```

Si votre renderer suit déjà le transform, la taille source, la taille de sortie, le timestamp et la direction caméra, vous pouvez les passer explicitement :

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

Dessinez `outputTextureId` avec votre propre renderer ou envoyez-le vers votre surface d'encodage.

### Réglage des paramètres

La plupart des intensités utilisent `0...100`. Certains offsets de remodelage, comme le menton, la distance des yeux et la forme de la bouche, utilisent `-50...50`.

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

### Fallback CPU

Utilisez le processeur de frames CPU pour les appareils ou pipelines où le traitement de texture n'est pas disponible :

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
processor.engine().setWhiteDelta(40f);
processor.engine().setSkinDelta(35f);

UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

### Prérequis

- Android minSdk 26+
- Android Gradle Plugin 8+
- Pipeline de rendu compatible OpenGL ES

## Projets de démo

```text
iOS_demo/UyaliBeautySDKDemo
android_demo
```

Les démos incluent les contrôles beauté, remodelage du visage, remodelage du corps et maquillage.
