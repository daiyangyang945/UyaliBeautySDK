# UyaliBeauty HarmonyOS SDK

This folder contains the HarmonyOS SDK HAR package and integration examples.

## Local HAR Import

Place `uyali_beauty_sdk.har` in your project, then declare it from the module that uses the SDK:

```json5
{
  "dependencies": {
    "uyali_beauty_sdk": "file:../../harmony_sdk/uyali_beauty_sdk.har"
  }
}
```

The project-level `build-profile.json5` should enable normalized OHM URLs:

```json5
{
  "app": {
    "products": [
      {
        "buildOption": {
          "strictMode": {
            "useNormalizedOHMUrl": true
          }
        }
      }
    ]
  }
}
```

Run:

```bash
ohpm install
```

## Registry Import

After the package is published to your OHPM-compatible registry:

```json5
{
  "dependencies": {
    "uyali_beauty_sdk": "1.0.0"
  }
}
```

Then run:

```bash
ohpm install
```

## Basic Usage

```ts
import { UyaliBeautyEngine } from 'uyali_beauty_sdk';

const beauty = new UyaliBeautyEngine(context);
beauty.setParameter('white', 40);
beauty.setParameter('skin', 35);
beauty.setParameter('faceThin', 30);

await beauty.processPixelMapInPlace(pixelMap);
```
