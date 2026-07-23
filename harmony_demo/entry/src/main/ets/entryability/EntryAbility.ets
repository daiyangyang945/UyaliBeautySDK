import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import { runHarmonyLicenseMatrixSelfTest } from '../demo/LicenseMatrixSelfTest';

const DOMAIN = 0x5561;

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    hilog.info(DOMAIN, 'UyaliBeautyDemo', 'EntryAbility onCreate');
    runHarmonyLicenseMatrixSelfTest(this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'UyaliBeautyDemo', 'EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'UyaliBeautyDemo', 'Failed to load page: %{public}s', JSON.stringify(err));
      }
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'UyaliBeautyDemo', 'WindowStage destroyed');
  }
}
