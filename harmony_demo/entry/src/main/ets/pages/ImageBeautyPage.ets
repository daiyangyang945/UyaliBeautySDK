import image from '@ohos.multimedia.image';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { BusinessError } from '@kit.BasicServicesKit';
import { UyaliBeautyEngine, UyaliBeautyPoint } from 'uyali_beauty_sdk';
import {
  BEAUTY_CATEGORIES,
  BeautyCategory,
  BeautyItem,
  getItemsByCategory,
  getMakeupOptions,
  MAKEUP_GROUPS,
  MakeupGroup,
  MakeupOption,
  resetBeautyValues,
  syncBeautyState,
} from '../demo/BeautyCatalog';
import { cloneEditablePixelMap, createDemoPortraitPixelMap, loadEditablePixelMap } from '../demo/DemoImageTools';

@Entry
@Component
struct ImageBeautyPage {
  private engine: UyaliBeautyEngine = new UyaliBeautyEngine();
  private sourcePixelMap?: image.PixelMap = undefined;
  private values: Map<string, number> = new Map<string, number>();
  private makeupTypes: Map<string, number> = new Map<string, number>();
  private renderAgainRequested: boolean = false;

  @State private previewPixelMap?: image.PixelMap = undefined;
  @State private selectedCategoryId: string = 'beauty';
  @State private selectedItemId: string = 'white';
  @State private selectedMakeupGroupId: string = 'eyebrow';
  @State private selectedMakeupOptionId: string = 'none';
  @State private status: string = '准备图片';
  @State private rendering: boolean = false;
  @State private valuesVersion: number = 0;
  @State private previewAspectRatio: number = 9 / 16;
  @State private showLandmarks: boolean = false;
  @State private faceLandmarks: UyaliBeautyPoint[] = [];
  @State private bodyLandmarks: UyaliBeautyPoint[] = [];

  aboutToAppear(): void {
    resetBeautyValues(this.values, this.makeupTypes);
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) {
      this.engine.initialize(context);
    }
    this.resetToSample();
  }

  aboutToDisappear(): void {
    this.engine.release();
  }

  private currentItems(): BeautyItem[] {
    return getItemsByCategory(this.selectedCategoryId);
  }

  private activeItem(): BeautyItem | undefined {
    const items = this.currentItems();
    return items.find((item: BeautyItem) => item.id === this.selectedItemId) ?? items[0];
  }

  private activeItemTitle(): string {
    return this.activeItem()?.title ?? '';
  }

  private activeItemParameter(): string {
    return this.activeItem()?.parameter ?? '';
  }

  private activeItemMin(): number {
    return this.activeItem()?.min ?? 0;
  }

  private activeItemMax(): number {
    return this.activeItem()?.max ?? 100;
  }

  private activeMakeupGroup(): MakeupGroup {
    return MAKEUP_GROUPS.find((group: MakeupGroup) => group.id === this.selectedMakeupGroupId) ?? MAKEUP_GROUPS[0];
  }

  private valueFor(parameter: string): number {
    const version = this.valuesVersion;
    if (version < 0) {
      return 0;
    }
    return this.values.get(parameter) ?? 0;
  }

  private typeFor(typeParameter: string): number {
    const version = this.valuesVersion;
    if (version < 0) {
      return 0;
    }
    return this.makeupTypes.get(typeParameter) ?? 0;
  }

  private setBeautyValue(parameter: string, value: number, shouldRender: boolean = true): void {
    const nextValue = Math.round(value);
    if ((this.values.get(parameter) ?? 0) === nextValue) {
      return;
    }
    this.values.set(parameter, nextValue);
    this.valuesVersion += 1;
    if (shouldRender) {
      this.renderFromSource();
    }
  }

  private setMakeupOption(option: MakeupOption): void {
    const group = this.activeMakeupGroup();
    this.selectedMakeupOptionId = option.id;
    this.makeupTypes.set(group.typeParameter, option.typeValue);
    if (option.typeValue === 0) {
      this.values.set(group.parameter, 0);
    } else if ((this.values.get(group.parameter) ?? 0) === 0) {
      this.values.set(group.parameter, 55);
    }
    this.valuesVersion += 1;
    this.renderFromSource();
  }

  private async resetToSample(): Promise<void> {
    this.status = '加载示例图';
    const context = this.getUIContext().getHostContext();
    this.sourcePixelMap = await createDemoPortraitPixelMap(context);
    this.engine.resetAllFilters();
    await this.renderFromSource();
  }

  private async pickImage(): Promise<void> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      options.isPhotoTakingSupported = false;
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select(options);
      if (result.photoUris.length === 0) {
        return;
      }
      this.status = '加载相册图片';
      this.sourcePixelMap = await loadEditablePixelMap(result.photoUris[0]);
      this.engine.resetAllFilters();
      await this.renderFromSource();
    } catch (error) {
      const err = error as BusinessError;
      this.status = `选图失败: ${err.message ?? JSON.stringify(error)}`;
    }
  }

  private resetAll(): void {
    resetBeautyValues(this.values, this.makeupTypes);
    this.selectedCategoryId = 'beauty';
    this.selectedItemId = 'white';
    this.selectedMakeupGroupId = 'eyebrow';
    this.selectedMakeupOptionId = 'none';
    this.valuesVersion += 1;
    this.engine.resetAllFilters();
    this.renderFromSource();
  }

  private async renderFromSource(): Promise<void> {
    if (this.sourcePixelMap === undefined) {
      return;
    }
    if (this.rendering) {
      this.renderAgainRequested = true;
      return;
    }
    this.rendering = true;
    try {
      const frame = await cloneEditablePixelMap(this.sourcePixelMap);
      syncBeautyState(this.engine, this.values, this.makeupTypes, false);
      const ok = await this.engine.processPixelMapInPlace(frame);
      const info = await frame.getImageInfo();
      const shortSide = Math.min(info.size.width, info.size.height);
      const longSide = Math.max(info.size.width, info.size.height);
      this.previewAspectRatio = longSide > 0 ? shortSide / longSide : 9 / 16;
      this.previewPixelMap = frame;
      this.faceLandmarks = this.engine.latestAllFaceLandmarks();
      this.bodyLandmarks = this.engine.latestBodyLandmarks();
      this.status = ok ? '已处理当前图片' : '当前图片处理失败';
    } catch (error) {
      const err = error as BusinessError;
      this.status = `处理失败: ${err.message ?? JSON.stringify(error)}`;
    } finally {
      this.rendering = false;
      if (this.renderAgainRequested) {
        this.renderAgainRequested = false;
        this.renderFromSource();
      }
    }
  }

  @Builder
  private LandmarkOverlay() {
    if (this.showLandmarks) {
      Stack() {
        ForEach(this.faceLandmarks, (point: UyaliBeautyPoint, index: number) => {
          Text('•')
            .fontSize(7)
            .fontColor('#20F0B7')
            .width(10)
            .height(10)
            .textAlign(TextAlign.Center)
            .position({ x: `${Math.max(0, Math.min(1, point.x)) * 100}%`,
              y: `${Math.max(0, Math.min(1, point.y)) * 100}%` });
        }, (point: UyaliBeautyPoint, index: number) => `f-${index}-${Math.round(point.x * 10000)}-${Math.round(point.y * 10000)}`);
        ForEach(this.bodyLandmarks, (point: UyaliBeautyPoint, index: number) => {
          Text('•')
            .fontSize(9)
            .fontColor('#FFD54A')
            .width(12)
            .height(12)
            .textAlign(TextAlign.Center)
            .position({ x: `${Math.max(0, Math.min(1, point.x)) * 100}%`,
              y: `${Math.max(0, Math.min(1, point.y)) * 100}%` });
        }, (point: UyaliBeautyPoint, index: number) => `b-${index}-${Math.round(point.x * 10000)}-${Math.round(point.y * 10000)}`);
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None);
    }
  }

  @Builder
  private Header() {
    Row({ space: 10 }) {
      Button('<')
        .width(42)
        .height(38)
        .onClick(() => {
          try {
            this.getUIContext().getRouter().back();
          } catch (_) {
          }
        });
      Column({ space: 2 }) {
        Text('图片美颜')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111318');
        Text('相册/示例图 -> PixelMap -> SDK 帧处理')
          .fontSize(12)
          .fontColor('#687181');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
      Button('选图')
        .height(38)
        .onClick(() => {
          this.pickImage();
        });
      Button('重置')
        .height(38)
        .onClick(() => {
          this.resetAll();
        });
    }
    .width('100%');
  }

  @Builder
  private CategoryTabs() {
    Row({ space: 8 }) {
      ForEach(BEAUTY_CATEGORIES, (category: BeautyCategory) => {
        Button(category.title)
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(this.selectedCategoryId === category.id ? '#1B1F25' : '#333333')
          .onClick(() => {
            this.selectedCategoryId = category.id;
            if (category.id !== 'makeup') {
              const items = getItemsByCategory(category.id);
              this.selectedItemId = items.length > 0 ? items[0].id : '';
            }
          });
      }, (category: BeautyCategory) => category.id);
    }
    .width('100%');
  }

  @Builder
  private ParameterPanel() {
    if (this.selectedCategoryId === 'makeup') {
      Column({ space: 12 }) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(MAKEUP_GROUPS, (group: MakeupGroup) => {
              Button(group.title)
                .height(34)
                .fontSize(13)
                .fontColor('#FFFFFF')
                .backgroundColor(this.selectedMakeupGroupId === group.id ? '#1B1F25' : '#333333')
                .onClick(() => {
                  this.selectedMakeupGroupId = group.id;
                  const typeValue = this.typeFor(group.typeParameter);
                  const options = getMakeupOptions(group.id);
                  const option = options.find((item: MakeupOption) => item.typeValue === typeValue) ?? options[0];
                  this.selectedMakeupOptionId = option.id;
                });
            }, (group: MakeupGroup) => group.id);
          }
          .padding({ left: 2, right: 2 });
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');

        Scroll() {
          Row({ space: 8 }) {
            ForEach(getMakeupOptions(this.selectedMakeupGroupId), (option: MakeupOption) => {
              Button(option.title)
                .height(34)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor(this.selectedMakeupOptionId === option.id ? '#2E6F64' : '#333333')
                .onClick(() => {
                  this.setMakeupOption(option);
                });
            }, (option: MakeupOption) => option.id);
          }
          .padding({ left: 2, right: 2 });
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');

        Row({ space: 12 }) {
          Text(`${this.activeMakeupGroup().title}强度`)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .width(72);
          Slider({
            value: this.valueFor(this.activeMakeupGroup().parameter),
            min: 0,
            max: 100,
            step: 1,
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.setBeautyValue(this.activeMakeupGroup().parameter, value);
            });
          Text(`${Math.round(this.valueFor(this.activeMakeupGroup().parameter))}`)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .width(54)
            .textAlign(TextAlign.End);
        }
        .width('100%');
      }
      .width('100%');
    } else {
      Column({ space: 12 }) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.currentItems(), (item: BeautyItem) => {
              Button(item.title)
                .height(34)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor(this.selectedItemId === item.id ? '#2E6F64' : '#333333')
                .onClick(() => {
                  this.selectedItemId = item.id;
                });
            }, (item: BeautyItem) => item.id);
          }
          .padding({ left: 2, right: 2 });
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%');

        Row({ space: 12 }) {
          Text(this.activeItemTitle())
            .fontSize(13)
            .fontColor('#FFFFFF')
            .width(72);
          Slider({
            value: this.valueFor(this.activeItemParameter()),
            min: this.activeItemMin(),
            max: this.activeItemMax(),
            step: 1,
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.setBeautyValue(this.activeItemParameter(), value);
            });
          Text(`${Math.round(this.valueFor(this.activeItemParameter()))}`)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .width(54)
            .textAlign(TextAlign.End);
        }
        .width('100%');
      }
      .width('100%');
    }
  }

  build() {
    Stack() {
      Stack({ alignContent: Alignment.Center }) {
        Stack() {
          if (this.previewPixelMap !== undefined) {
            Image(this.previewPixelMap)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain);
          } else {
            Text('加载中')
              .fontSize(16)
              .fontColor('#9AA3AF');
          }
          this.LandmarkOverlay();
        }
          .width('100%')
          .aspectRatio(this.previewAspectRatio)
          .backgroundColor('#000000');
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000');

      Column() {
        Row() {
          Button('关闭')
            .fontSize(15)
            .fontColor('#2589FF')
            .backgroundColor('#00000000')
            .width(64)
            .height(50)
            .onClick(() => {
              try {
                this.getUIContext().getRouter().back();
              } catch (_) {
              }
            });
          Blank()
            .layoutWeight(1);
          Blank()
            .layoutWeight(1);
          Button('选图')
            .fontSize(15)
            .fontColor('#2589FF')
            .backgroundColor('#00000000')
            .width(64)
            .height(50)
            .onClick(() => {
              this.pickImage();
            });
        }
        .width('100%')
        .height(86)
        .padding({ left: 6, right: 6, top: 36 });

        Blank()
          .layoutWeight(1);

        if (this.rendering) {
          Text('处理中')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#66000000')
            .borderRadius(8)
            .margin({ bottom: 8 });
        }

        Text(this.status)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .width('100%')
          .padding({ left: 12, right: 12, top: 4, bottom: 4 })
          .backgroundColor('#33000000');

        Column({ space: 10 }) {
          this.ParameterPanel();
        }
        .width('100%')
        .height(this.selectedCategoryId === 'makeup' ? 184 : 130)
        .padding({ left: 12, right: 12, top: 10, bottom: 8 })
        .backgroundColor('#CC000000');

        Row({ space: 0 }) {
          ForEach(BEAUTY_CATEGORIES, (category: BeautyCategory) => {
            Button(category.title)
              .layoutWeight(1)
              .height(50)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#00000000')
              .onClick(() => {
                this.selectedCategoryId = category.id;
                if (category.id !== 'makeup') {
                  const items = getItemsByCategory(category.id);
                  this.selectedItemId = items.length > 0 ? items[0].id : '';
                }
              });
          }, (category: BeautyCategory) => category.id);
        }
        .width('100%')
        .height(50)
        .backgroundColor('#66000000');
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000');
  }
}
