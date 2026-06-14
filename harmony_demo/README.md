# UyaliBeauty HarmonyOS Demo

This demo shows camera preview processing and image processing with `uyali_beauty_sdk`.

## Default Import

The demo uses the local HAR package by default:

```json5
{
  "dependencies": {
    "uyali_beauty_sdk": "file:../../harmony_sdk/uyali_beauty_sdk.har"
  }
}
```

## Registry Import

After the package is published to your OHPM-compatible registry, change the dependency to:

```json5
{
  "dependencies": {
    "uyali_beauty_sdk": "1.0.0"
  }
}
```

Run `ohpm install` after changing the dependency.

## Run

Open this folder in DevEco Studio, configure signing for your device, then run the `entry` module.

Command-line build:

```bash
ohpm install
hvigorw assembleHap
```

## Demo Screens

- Camera beauty: `entry/src/main/ets/pages/CameraBeautyPage.ets`
- Image beauty: `entry/src/main/ets/pages/ImageBeautyPage.ets`
- Parameter catalog: `entry/src/main/ets/demo/BeautyCatalog.ets`
