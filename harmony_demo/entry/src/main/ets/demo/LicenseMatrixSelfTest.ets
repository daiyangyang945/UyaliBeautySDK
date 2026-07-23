import hilog from '@ohos.hilog';
import {
  UyaliBeautyEngine,
  UyaliBeautyFeature,
  UyaliBeautyLicenseResult,
  UyaliBeautyLicenseStatus,
} from 'uyali_beauty_sdk';

const DOMAIN = 0x5561;
const TAG = 'UyaliLicenseMatrix';

class LicenseCase {
  readonly name: string;
  readonly rawfilePath: string;
  readonly expectedStatus: UyaliBeautyLicenseStatus;
  readonly expectedModules: string[];

  constructor(name: string,
              rawfilePath: string,
              expectedStatus: UyaliBeautyLicenseStatus,
              expectedModules: string[]) {
    this.name = name;
    this.rawfilePath = rawfilePath;
    this.expectedStatus = expectedStatus;
    this.expectedModules = expectedModules;
  }
}

class FeatureProbe {
  readonly name: string;
  readonly feature: UyaliBeautyFeature;

  constructor(name: string, feature: UyaliBeautyFeature) {
    this.name = name;
    this.feature = feature;
  }
}

class NativeModuleProbe {
  readonly name: string;
  readonly parameter: string;
  readonly value: number;
  readonly debugKey: string;
  readonly typeParameter: string;
  readonly typeValue: number;

  constructor(name: string,
              parameter: string,
              value: number,
              debugKey: string,
              typeParameter: string = '',
              typeValue: number = 0) {
    this.name = name;
    this.parameter = parameter;
    this.value = value;
    this.debugKey = debugKey;
    this.typeParameter = typeParameter;
    this.typeValue = typeValue;
  }
}

const FEATURE_PROBES: FeatureProbe[] = [
  new FeatureProbe('beauty', UyaliBeautyFeature.BEAUTY),
  new FeatureProbe('reshape', UyaliBeautyFeature.RESHAPE),
  new FeatureProbe('body', UyaliBeautyFeature.BODY),
  new FeatureProbe('makeup', UyaliBeautyFeature.MAKEUP),
];

const NATIVE_MODULE_PROBES: NativeModuleProbe[] = [
  new NativeModuleProbe('beauty', 'white', 80, 'white'),
  new NativeModuleProbe('reshape', 'faceThin', 80, 'reshape'),
  new NativeModuleProbe('body', 'bodySlim', 80, 'reshape'),
  new NativeModuleProbe('makeup', 'makeupEyebrow', 80, 'makeup', 'makeupEyebrowType', 1),
];

const PROBE_FRAME_WIDTH = 32;
const PROBE_FRAME_HEIGHT = 32;
const ACTIVE_EPSILON = 0.001;

const LICENSE_CASES: LicenseCase[] = [
  new LicenseCase('android_beauty', 'uyali/licenses/android_beauty.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_beauty_body', 'uyali/licenses/android_beauty_body.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_beauty_body_makeup', 'uyali/licenses/android_beauty_body_makeup.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_beauty_makeup', 'uyali/licenses/android_beauty_makeup.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_beauty_reshape', 'uyali/licenses/android_beauty_reshape.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_beauty_reshape_body', 'uyali/licenses/android_beauty_reshape_body.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_beauty_reshape_body_makeup', 'uyali/licenses/android_beauty_reshape_body_makeup.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('android_error_id', 'uyali/licenses/android_error_id.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('harmony_beauty', 'uyali/licenses/harmony_beauty.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty']),
  new LicenseCase('harmony_beauty_body', 'uyali/licenses/harmony_beauty_body.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty', 'body']),
  new LicenseCase('harmony_beauty_body_makeup', 'uyali/licenses/harmony_beauty_body_makeup.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty', 'body', 'makeup']),
  new LicenseCase('harmony_beauty_makeup', 'uyali/licenses/harmony_beauty_makeup.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty', 'makeup']),
  new LicenseCase('harmony_beauty_reshape', 'uyali/licenses/harmony_beauty_reshape.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty', 'reshape']),
  new LicenseCase('harmony_beauty_reshape_body', 'uyali/licenses/harmony_beauty_reshape_body.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty', 'reshape', 'body']),
  new LicenseCase('harmony_beauty_reshape_body_makeup', 'uyali/licenses/harmony_beauty_reshape_body_makeup.uyali', UyaliBeautyLicenseStatus.VALID, ['beauty', 'reshape', 'body', 'makeup']),
  new LicenseCase('harmony_error_id', 'uyali/licenses/harmony_error_id.uyali', UyaliBeautyLicenseStatus.APP_MISMATCH, []),
  new LicenseCase('ios_beauty', 'uyali/licenses/ios_beauty.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_beauty_body', 'uyali/licenses/ios_beauty_body.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_beauty_body_makeup', 'uyali/licenses/ios_beauty_body_makeup.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_beauty_makeup', 'uyali/licenses/ios_beauty_makeup.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_beauty_reshape', 'uyali/licenses/ios_beauty_reshape.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_beauty_reshape_body', 'uyali/licenses/ios_beauty_reshape_body.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_beauty_reshape_body_makeup', 'uyali/licenses/ios_beauty_reshape_body_makeup.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
  new LicenseCase('ios_error_id', 'uyali/licenses/ios_error_id.uyali', UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED, []),
];

export function runHarmonyLicenseMatrixSelfTest(context: Context): void {
  let failures = 0;
  hilog.info(DOMAIN, TAG, 'UYALI_PUBLIC_HARMONY_LICENSE_MATRIX_BEGIN');

  for (const item of LICENSE_CASES) {
    const engine = new UyaliBeautyEngine(context);
    const result = engine.loadLicenseFromRawfile(context, item.rawfilePath);
    const granted = grantedModules(engine);
    const trialSeconds = engine.getLicenseTrialSecondsRemaining();
    const row = `${item.name}: status=${statusName(result.status)} granted=${granted.join(',')} trial=${trialSeconds}`;
    hilog.info(DOMAIN, TAG, '%{public}s', row);

    if (!caseMatches(item, result, granted, trialSeconds)) {
      failures += 1;
    }
    if (result.status === UyaliBeautyLicenseStatus.VALID) {
      failures += nativeModuleGateFailures(item, engine);
    }
    engine.release();
  }

  hilog.info(DOMAIN, TAG, 'UYALI_PUBLIC_HARMONY_LICENSE_MATRIX_END failures=%{public}d', failures);
}

function grantedModules(engine: UyaliBeautyEngine): string[] {
  const granted: string[] = [];
  for (const probe of FEATURE_PROBES) {
    if (engine.canUseFeature(probe.feature)) {
      granted.push(probe.name);
    }
  }
  return granted;
}

function caseMatches(item: LicenseCase,
                     result: UyaliBeautyLicenseResult,
                     granted: string[],
                     trialSeconds: number): boolean {
  if (result.status !== item.expectedStatus) {
    return false;
  }
  if (!stringArrayEquals(granted, item.expectedModules)) {
    return false;
  }
  return trialSeconds === 0;
}

function nativeModuleGateFailures(item: LicenseCase, engine: UyaliBeautyEngine): number {
  let failures = 0;
  for (const probe of NATIVE_MODULE_PROBES) {
    engine.resetAllFilters();
    engine.setParameter(probe.parameter, probe.value);
    if (probe.typeParameter.length > 0) {
      engine.setMakeupType(probe.typeParameter, probe.typeValue);
    }
    const processResult = engine.processRgba({
      data: createProbeFrame(),
      width: PROBE_FRAME_WIDTH,
      height: PROBE_FRAME_HEIGHT,
      rowStride: PROBE_FRAME_WIDTH * 4,
    });
    const debugText = engine.debugInfo().rawText;
    const actualValue = debugNumber(debugText, probe.debugKey);
    const expectedActive = stringArrayContains(item.expectedModules, probe.name);
    const actualActive = actualValue > ACTIVE_EPSILON;
    const ok = processResult.ok && expectedActive === actualActive;
    hilog.info(
      DOMAIN,
      TAG,
      '%{public}s',
      `${item.name}: native=${probe.name} expected=${expectedActive ? 'on' : 'off'} actual=${actualValue} ok=${ok ? 'yes' : 'no'}`
    );
    if (!ok) {
      failures += 1;
      hilog.error(DOMAIN, TAG, '%{public}s', `${item.name}: native gate debug ${debugPreview(debugText)}`);
    }
  }
  return failures;
}

function createProbeFrame(): ArrayBuffer {
  const buffer = new ArrayBuffer(PROBE_FRAME_WIDTH * PROBE_FRAME_HEIGHT * 4);
  const pixels = new Uint8Array(buffer);
  for (let y = 0; y < PROBE_FRAME_HEIGHT; y += 1) {
    for (let x = 0; x < PROBE_FRAME_WIDTH; x += 1) {
      const index = (y * PROBE_FRAME_WIDTH + x) * 4;
      pixels[index] = 122 + ((x * 3 + y) % 32);
      pixels[index + 1] = 112 + ((x + y * 2) % 28);
      pixels[index + 2] = 104 + ((x * 2 + y * 3) % 36);
      pixels[index + 3] = 255;
    }
  }
  return buffer;
}

function debugNumber(text: string, key: string): number {
  const prefix = `${key}=`;
  const start = text.indexOf(prefix);
  if (start < 0) {
    return 0;
  }
  let cursor = start + prefix.length;
  while (cursor < text.length && isNumericDebugChar(text.charAt(cursor))) {
    cursor += 1;
  }
  if (cursor === start + prefix.length) {
    return 0;
  }
  const value = Number.parseFloat(text.substring(start + prefix.length, cursor));
  return value === value ? value : 0;
}

function isNumericDebugChar(value: string): boolean {
  return (value >= '0' && value <= '9') || value === '.' || value === '-' || value === '+';
}

function debugPreview(text: string): string {
  return text.length > 220 ? text.substring(0, 220) : text;
}

function stringArrayContains(values: string[], target: string): boolean {
  for (const value of values) {
    if (value === target) {
      return true;
    }
  }
  return false;
}

function stringArrayEquals(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  for (let index = 0; index < left.length; index += 1) {
    if (left[index] !== right[index]) {
      return false;
    }
  }
  return true;
}

function statusName(status: UyaliBeautyLicenseStatus): string {
  if (status === UyaliBeautyLicenseStatus.FREE) {
    return 'FREE';
  }
  if (status === UyaliBeautyLicenseStatus.VALID) {
    return 'VALID';
  }
  if (status === UyaliBeautyLicenseStatus.INVALID) {
    return 'INVALID';
  }
  if (status === UyaliBeautyLicenseStatus.INVALID_FORMAT) {
    return 'INVALID_FORMAT';
  }
  if (status === UyaliBeautyLicenseStatus.INVALID_SIGNATURE) {
    return 'INVALID_SIGNATURE';
  }
  if (status === UyaliBeautyLicenseStatus.UNSUPPORTED_ALGORITHM) {
    return 'UNSUPPORTED_ALGORITHM';
  }
  if (status === UyaliBeautyLicenseStatus.UNSUPPORTED_KEY) {
    return 'UNSUPPORTED_KEY';
  }
  if (status === UyaliBeautyLicenseStatus.PLATFORM_UNSUPPORTED) {
    return 'PLATFORM_UNSUPPORTED';
  }
  if (status === UyaliBeautyLicenseStatus.APP_MISMATCH) {
    return 'APP_MISMATCH';
  }
  if (status === UyaliBeautyLicenseStatus.EXPIRED) {
    return 'EXPIRED';
  }
  if (status === UyaliBeautyLicenseStatus.NOT_YET_VALID) {
    return 'NOT_YET_VALID';
  }
  if (status === UyaliBeautyLicenseStatus.TIME_ROLLBACK) {
    return 'TIME_ROLLBACK';
  }
  if (status === UyaliBeautyLicenseStatus.SDK_VERSION_UNSUPPORTED) {
    return 'SDK_VERSION_UNSUPPORTED';
  }
  return 'UNKNOWN';
}
