class DemoEntry {
  title: string;
  desc: string;
  url: string;

  constructor(title: string, desc: string, url: string) {
    this.title = title;
    this.desc = desc;
    this.url = url;
  }
}

const DEMO_ENTRIES: DemoEntry[] = [
  new DemoEntry('相机美颜', '实时预览美颜、美型、美体和美妆效果。', 'pages/CameraBeautyPage'),
  new DemoEntry('图片美颜', '选择图片或使用示例图，体验完整美颜参数。', 'pages/ImageBeautyPage'),
];

@Entry
@Component
struct Index {
  private openPage(url: string): void {
    this.getUIContext().getRouter().pushUrl({ url }).catch(() => {
    });
  }

  build() {
    Column({ space: 22 }) {
      Column({ space: 8 }) {
        Text('Uyali Beauty Harmony Demo')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#101418')
          .width('100%');
        Text('体验相机和图片两种美颜场景。')
          .fontSize(14)
          .fontColor('#5F6673')
          .width('100%');
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);

      ForEach(DEMO_ENTRIES, (entry: DemoEntry) => {
        Column({ space: 10 }) {
          Text(entry.title)
            .fontSize(21)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111318')
            .width('100%');
          Text(entry.desc)
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#69717F')
            .width('100%');
        }
        .width('100%')
        .padding(18)
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E2E6EC' })
        .onClick(() => {
          this.openPage(entry.url);
        });
      }, (entry: DemoEntry) => entry.url);

      Blank()
        .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 28, bottom: 20 })
    .backgroundColor('#F6F7F9');
  }
}
