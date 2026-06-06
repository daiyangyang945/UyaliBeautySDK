# UyaliBeauty Android Demo

This standalone demo consumes the Android SDK from the Maven package in this repository:

```text
../android_maven/com/uyali/beauty/uyali-beauty-sdk/1.0.0/
```

The SDK only processes frames and textures. Camera ownership, preview rendering, final display and video encoding stay in the host app.

## Integration

### Gradle Maven Repository

Add the repository in `settings.gradle`:

```gradle
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("../android_maven") }
    }
}
```

Add the SDK dependency in `app/build.gradle`:

```gradle
dependencies {
    implementation "com.uyali.beauty:uyali-beauty-sdk:1.0.0"
}
```

### Local AAR File

You can also copy the AAR into your app and depend on it directly:

```text
libs/uyali-beauty-sdk-release.aar
```

```gradle
dependencies {
    implementation files("libs/uyali-beauty-sdk-release.aar")
}
```

## Demo Code

Call this on the GL thread after your camera or video source updates its texture:

```java
UyaliBeautyTextureProcessor beauty = new UyaliBeautyTextureProcessor(context);

UyaliBeautyTextureFrame frame = beauty.process(oesTextureId);
int outputTextureId = frame.textureId();
```

For a full Camera2, `SurfaceTexture` and renderer setup, see:

```text
app/src/main/java/com/uyali/beauty/UyaliBeautyView.java
app/src/main/java/com/uyali/beauty/demo/Camera2Controller.java
```

## Parameters

```java
UyaliBeautyEngine engine = beauty.engine();
engine.setWhiteDelta(40f);
engine.setSkinDelta(35f);
engine.setFaceThinDelta(30f);
engine.setEyeBigDelta(20f);
engine.setBodySlimDelta(25f);
engine.setMakeupRougeDelta(60f);
engine.setMakeupRougeType(UyaliMakeupCatalog.ROUGE_TYPES[0]);
```

## CPU Fallback

```java
UyaliBeautyFrameProcessor processor = new UyaliBeautyFrameProcessor(context);
UyaliBeautyFrame frame = processor.process(image, rotationDegrees);
ByteBuffer rgba = frame.rgba();
```

## Environment Requirements

- Android minSdk 26+
- Android Gradle Plugin 8+
- OpenGL ES-capable rendering pipeline

## Build

```bash
./gradlew :app:assembleDebug
```
