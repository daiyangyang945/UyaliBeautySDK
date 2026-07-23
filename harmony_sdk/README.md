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
beauty.loadLicenseFromRawfile(context, 'uyali/license.lic');
beauty.setParameter('white', 40);
beauty.setParameter('skin', 35);
beauty.setParameter('faceThin', 30);

await beauty.processPixelMapInPlace(pixelMap);
```

## License Loading

The HarmonyOS SDK uses the same Uyali license JSON format as iOS and Android. Load it from your app resources:

```ts
const result = beauty.loadLicenseFromRawfile(context, 'uyali/license.lic');
```

Or pass the license text directly after fetching it from your own service:

```ts
const result = beauty.activateLicense(licenseText);
```

You can query the current state with `getLicenseStatus()`, `getLicenseMessage()`, and `getLicenseTrialSecondsRemaining()`.

## Evaluation Limits

The public evaluation SDK keeps `white` and `skin` available without a time limit. Other beauty, reshape, body, makeup, and landmark-output capabilities are available for 120 seconds after each SDK engine instance is created.
