import image from '@ohos.multimedia.image';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UyaliBeautyEngine, UyaliBeautyPoint, UyaliNativeImageFrame, UyaliYuv420Frame } from 'uyali_beauty_sdk';
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
import {
  CameraFrame,
  CameraNativeImageFrame,
  CameraYuv420Frame,
  DemoCameraController,
} from '../demo/DemoCameraController';

@Entry
@Component
struct CameraBeautyPage {
  private engine: UyaliBeautyEngine = new UyaliBeautyEngine();
  private controller?: DemoCameraController = undefined;
  private xComponentController: XComponentController = new XComponentController();
  private displaySurfaceId: string = '';
  private displaySurfaceWidth: number = 0;
  private displaySurfaceHeight: number = 0;
  private values: Map<string, number> = new Map<string, number>();
  private makeupTypes: Map<string, number> = new Map<string, number>();
  private surfaceCaptureTimer: number = -1;
  private surfaceCaptureBusy: boolean = false;
  private cameraFrameBusy: boolean = false;
  private latestFrameStreamMs: number = 0;
  private cameraOutputRgba?: ArrayBuffer = undefined;
  private cameraOutputWidth: number = 0;
  private cameraOutputHeight: number = 0;
  private previewPixelMapPool: image.PixelMap[] = [];
  private previewPixelMapPoolWidth: number = 0;
  private previewPixelMapPoolHeight: number = 0;
  private previewPixelMapPoolIndex: number = 0;
  private landmarkCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private latestLandmarkRefreshMs: number = 0;
  private latestBodyLandmarkRefreshMs: number = 0;
  private latestLandmarkDrawMs: number = 0;
  private landmarkRenderTimer: number = -1;
  private displayPreviewAspectRatio: number = 9 / 16;
  private readonly cameraProcessingMaxSide: number = 1280;
  private readonly surfaceCaptureIntervalMs: number = 360;
  private readonly surfaceCaptureFallbackDelayMs: number = 1000;
  private readonly landmarkRefreshIntervalMs: number = 24;
  private readonly landmarkRenderIntervalMs: number = 16;
  private readonly bodyLandmarkRefreshIntervalMs: number = 360;

  @State private previewPixelMap?: image.PixelMap = undefined;
  @State private selectedCategoryId: string = 'beauty';
  @State private selectedItemId: string = 'white';
  @State private selectedMakeupGroupId: string = 'eyebrow';
  @State private selectedMakeupOptionId: string = 'none';
  @State private status: string = '准备相机';
  @State private running: boolean = false;
  @State private frontCamera: boolean = true;
  @State private valuesVersion: number = 0;
  @State private previewAspectRatio: number = 9 / 16;
  @State private showLandmarks: boolean = false;
  private faceLandmarks: UyaliBeautyPoint[] = [];
  private bodyLandmarks: UyaliBeautyPoint[] = [];

  aboutToAppear(): void {
    resetBeautyValues(this.values, this.makeupTypes);
    this.status = '准备相机';
  }

  aboutToDisappear(): void {
    this.stopSurfaceCaptureLoop();
    this.stopLandmarkRenderLoop();
    this.controller?.stop();
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
    return this.makeupTypes.get(typeParameter) ?? 0;
  }

  private setBeautyValue(parameter: string, value: number): void {
    this.values.set(parameter, Math.round(value));
    this.valuesVersion += 1;
    this.latestLandmarkRefreshMs = 0;
    this.latestBodyLandmarkRefreshMs = 0;
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);
  }

  private updateDisplayPreviewAspectRatio(width: number, height: number): void {
    if (width <= 0 || height <= 0) {
      return;
    }
    const shortSide = Math.min(width, height);
    const longSide = Math.max(width, height);
    this.displayPreviewAspectRatio = shortSide / longSide;
    this.previewAspectRatio = this.displayPreviewAspectRatio;
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
    this.latestLandmarkRefreshMs = 0;
    this.latestBodyLandmarkRefreshMs = 0;
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);
  }

  private resetAll(): void {
    resetBeautyValues(this.values, this.makeupTypes);
    this.selectedCategoryId = 'beauty';
    this.selectedItemId = 'white';
    this.selectedMakeupGroupId = 'eyebrow';
    this.selectedMakeupOptionId = 'none';
    this.valuesVersion += 1;
    this.latestLandmarkRefreshMs = 0;
    this.latestBodyLandmarkRefreshMs = 0;
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);
  }

  private nonZeroParameter(parameter: string): boolean {
    return Math.abs(this.values.get(parameter) ?? 0) > 0;
  }

  private hasAnyActiveEffect(): boolean {
    let active = false;
    BEAUTY_CATEGORIES.forEach((category: BeautyCategory) => {
      getItemsByCategory(category.id).forEach((item: BeautyItem) => {
        if (this.nonZeroParameter(item.parameter)) {
          active = true;
        }
      });
    });
    MAKEUP_GROUPS.forEach((group: MakeupGroup) => {
      if (this.nonZeroParameter(group.parameter) && (this.makeupTypes.get(group.typeParameter) ?? 0) > 0) {
        active = true;
      }
    });
    return active;
  }

  private hasFaceLandmarkDependentEffect(): boolean {
    const faceParameters: string[] = [
      'skin', 'eyeBright', 'teethBright', 'darkCircle',
      'headReduce', 'faceThin', 'faceNarrow', 'faceV', 'faceSmall', 'chin', 'forehead', 'cheekbone',
      'eyeBig', 'eyeDistance', 'eyeCorner', 'eyelidDown', 'noseThin', 'noseWing', 'noseLong',
      'noseRoot', 'eyebrowDistance', 'eyebrowThin', 'mouth',
    ];
    if (faceParameters.some((parameter: string) => this.nonZeroParameter(parameter))) {
      return true;
    }
    return MAKEUP_GROUPS.some((group: MakeupGroup) =>
      this.nonZeroParameter(group.parameter) && (this.makeupTypes.get(group.typeParameter) ?? 0) > 0);
  }

  private hasBodyLandmarkDependentEffect(): boolean {
    const bodyParameters: string[] = [
      'bodySlim', 'waistSlim', 'legSlim', 'shoulderNarrow', 'armSlim', 'calfSlim',
      'abdomenSlim', 'legLong', 'bodyHeight', 'legShape', 'neckLength', 'shoulderShape',
    ];
    return bodyParameters.some((parameter: string) => this.nonZeroParameter(parameter));
  }

  private hasRealtimeFaceMaskEffect(): boolean {
    return this.nonZeroParameter('eyeBright') ||
      this.nonZeroParameter('teethBright') ||
      this.nonZeroParameter('darkCircle');
  }

  private hasActiveMakeupEffect(): boolean {
    return MAKEUP_GROUPS.some((group: MakeupGroup) =>
      this.nonZeroParameter(group.parameter) && (this.makeupTypes.get(group.typeParameter) ?? 0) > 0);
  }

  private shouldUseMakeupLandmarksForOverlay(): boolean {
    return this.hasRealtimeFaceMaskEffect() || this.hasActiveMakeupEffect();
  }

  private hasLandmarkDependentEffect(): boolean {
    return this.hasFaceLandmarkDependentEffect() || this.hasBodyLandmarkDependentEffect();
  }

  private shouldRefreshLandmarks(nowMs: number): boolean {
    if (!this.showLandmarks && !this.hasLandmarkDependentEffect()) {
      return false;
    }
    if (this.latestLandmarkRefreshMs === 0 || nowMs - this.latestLandmarkRefreshMs >= this.landmarkRefreshIntervalMs) {
      this.latestLandmarkRefreshMs = nowMs;
      return true;
    }
    return false;
  }

  private shouldRefreshBodyLandmarks(nowMs: number): boolean {
    if (this.latestBodyLandmarkRefreshMs === 0 ||
      nowMs - this.latestBodyLandmarkRefreshMs >= this.bodyLandmarkRefreshIntervalMs) {
      this.latestBodyLandmarkRefreshMs = nowMs;
      return true;
    }
    return false;
  }

  private shouldProcessCameraFrame(): boolean {
    return true;
  }

  private shouldShowProcessedPreview(): boolean {
    return this.displaySurfaceId.length === 0 && this.hasAnyActiveEffect();
  }

  private refreshDisplaySurfaceId(): boolean {
    if (this.displaySurfaceId.length === 0) {
      try {
        const surfaceId = this.xComponentController.getXComponentSurfaceId();
        if (surfaceId !== undefined && surfaceId.length > 0) {
          this.displaySurfaceId = surfaceId;
        }
      } catch (_) {
      }
    }
    const hasSurface = this.displaySurfaceId !== undefined && this.displaySurfaceId.length > 0;
    if (hasSurface) {
      this.engine.setCameraOutputSurface(this.displaySurfaceId);
    } else {
      this.engine.clearCameraOutputSurface();
    }
    return hasSurface;
  }

  private updateDisplaySurfaceSize(width: number, height: number): void {
    if (width <= 0 || height <= 0) {
      return;
    }
    this.displaySurfaceWidth = Math.round(width);
    this.displaySurfaceHeight = Math.round(height);
  }

  private displayPointX(point: UyaliBeautyPoint): number {
    return Math.max(0, Math.min(1, point.x));
  }

  private displayPointY(point: UyaliBeautyPoint): number {
    return Math.max(0, Math.min(1, point.y));
  }

  private scheduleLandmarkDraw(): void {
    this.drawLandmarkCanvas();
  }

  private drawLandmarkCanvas(): void {
    const startMs = Date.now();
    const context = this.landmarkCanvasContext;
    const width = context.width;
    const height = context.height;
    if (width <= 0 || height <= 0) {
      this.latestLandmarkDrawMs = 0;
      return;
    }
    context.clearRect(0, 0, width, height);
    if (!this.showLandmarks) {
      this.latestLandmarkDrawMs = Date.now() - startMs;
      return;
    }
    this.drawPointSet(this.faceLandmarks, '#20F0B7', 2.2, width, height);
    this.drawPointSet(this.bodyLandmarks, '#FFD54A', 2.8, width, height);
    this.latestLandmarkDrawMs = Date.now() - startMs;
  }

  private drawPointSet(points: UyaliBeautyPoint[], color: string, radius: number, width: number, height: number): void {
    const context = this.landmarkCanvasContext;
    context.fillStyle = color;
    points.forEach((point: UyaliBeautyPoint) => {
      const x = this.displayPointX(point) * width;
      const y = this.displayPointY(point) * height;
      context.beginPath();
      context.arc(x, y, radius, 0, Math.PI * 2);
      context.fill();
    });
  }

  private async requestCameraPermission(): Promise<boolean> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        this.status = '无法获取应用上下文';
        return false;
      }
      const permissions: Permissions[] = ['ohos.permission.CAMERA'];
      const data = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions);
      return data.authResults.length > 0 && data.authResults[0] === 0;
    } catch (error) {
      const err = error as BusinessError;
      this.status = `相机权限请求失败: ${err.message ?? JSON.stringify(error)}`;
      return false;
    }
  }

  private async startCamera(): Promise<void> {
    const granted = await this.requestCameraPermission();
    if (!granted) {
      this.running = false;
      this.status = '没有相机权限';
      return;
    }
    if (this.controller === undefined) {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) {
        this.running = false;
        this.status = '无法获取应用上下文';
        return;
      }
      this.engine.initialize(context);
      this.controller = new DemoCameraController(context, async (frame: CameraFrame) => {
        await this.handleCameraFrame(frame);
      }, (message: string) => {
        this.status = message;
      }, (width: number, height: number) => {
        this.updateDisplayPreviewAspectRatio(width, height);
      });
    }
    this.running = true;
    this.latestFrameStreamMs = 0;
    this.cameraFrameBusy = false;
    this.latestLandmarkRefreshMs = 0;
    this.latestBodyLandmarkRefreshMs = 0;
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);
    await this.controller.start(this.frontCamera, '');
    if (this.showLandmarks) {
      this.startLandmarkRenderLoop();
    }
  }

  private async stopCamera(): Promise<void> {
    this.stopSurfaceCaptureLoop();
    this.stopLandmarkRenderLoop();
    await this.controller?.stop();
    this.running = false;
    this.status = '相机已停止';
  }

  private async switchCamera(): Promise<void> {
    this.frontCamera = !this.frontCamera;
    this.latestLandmarkRefreshMs = 0;
    this.latestBodyLandmarkRefreshMs = 0;
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);
    if (this.running) {
      this.latestFrameStreamMs = 0;
      this.cameraFrameBusy = false;
      await this.controller?.start(this.frontCamera, '');
      if (this.showLandmarks) {
        this.startLandmarkRenderLoop();
      }
    }
  }

  private startSurfaceCaptureLoop(): void {
    this.stopSurfaceCaptureLoop();
    this.surfaceCaptureTimer = setInterval(() => {
      this.captureSurfaceFrame();
    }, this.surfaceCaptureIntervalMs);
  }

  private stopSurfaceCaptureLoop(): void {
    if (this.surfaceCaptureTimer >= 0) {
      clearInterval(this.surfaceCaptureTimer);
      this.surfaceCaptureTimer = -1;
    }
    this.surfaceCaptureBusy = false;
  }

  private startLandmarkRenderLoop(): void {
    this.stopLandmarkRenderLoop();
    this.landmarkRenderTimer = setInterval(() => {
      this.refreshLandmarkOverlay();
    }, this.landmarkRenderIntervalMs);
  }

  private stopLandmarkRenderLoop(): void {
    if (this.landmarkRenderTimer >= 0) {
      clearInterval(this.landmarkRenderTimer);
      this.landmarkRenderTimer = -1;
    }
  }

  private refreshLandmarkOverlay(): void {
    if (!this.running || !this.showLandmarks) {
      return;
    }
    const nextFace = this.engine.latestAllFaceLandmarks();
    const nextBody = this.engine.latestBodyLandmarks();
    this.faceLandmarks = nextFace;
    this.bodyLandmarks = nextFace.length > 0 ? nextBody : [];
    this.scheduleLandmarkDraw();
  }

  private async captureSurfaceFrame(): Promise<void> {
    if (!this.running || this.surfaceCaptureBusy || this.displaySurfaceId.length === 0) {
      return;
    }
    const nowMs = Date.now();
    if (this.latestFrameStreamMs > 0 && nowMs - this.latestFrameStreamMs < this.surfaceCaptureFallbackDelayMs) {
      return;
    }
    if (!this.shouldProcessCameraFrame()) {
      return;
    }
    if (this.hasAnyActiveEffect()) {
      this.status = '等待相机帧流 | 美颜预览不再使用 Surface 截图兜底';
      return;
    }
    if (this.showLandmarks && !this.hasAnyActiveEffect() && this.latestLandmarkRefreshMs !== 0 &&
      nowMs - this.latestLandmarkRefreshMs < this.landmarkRefreshIntervalMs) {
      return;
    }
    this.surfaceCaptureBusy = true;
    let surfacePixelMap: image.PixelMap | undefined = undefined;
    try {
      surfacePixelMap = await image.createPixelMapFromSurface(this.displaySurfaceId);
      if (this.showLandmarks && !this.hasAnyActiveEffect()) {
        this.latestLandmarkRefreshMs = nowMs;
        await this.scalePixelMapForCamera(surfacePixelMap);
        await this.handleAnalysisPixelMap(surfacePixelMap);
        return;
      }
      await this.scalePixelMapForCamera(surfacePixelMap);
      const framePixelMap = await this.editableRgbaCopy(surfacePixelMap);
      await this.handleCameraFrame({
        kind: 'pixelMap',
        pixelMap: framePixelMap,
      }, false);
    } catch (_) {
    } finally {
      try {
        surfacePixelMap?.release();
      } catch (_) {
      }
      this.surfaceCaptureBusy = false;
    }
  }

  private async scalePixelMapForCamera(pixelMap: image.PixelMap): Promise<void> {
    try {
      const info = await pixelMap.getImageInfo();
      const maxSide = Math.max(info.size.width, info.size.height);
      if (maxSide <= this.cameraProcessingMaxSide || maxSide <= 0) {
        return;
      }
      const scale = this.cameraProcessingMaxSide / maxSide;
      await pixelMap.scale(scale, scale);
    } catch (_) {
    }
  }

  private async handleAnalysisPixelMap(pixelMap: image.PixelMap): Promise<void> {
    const startMs = Date.now();
    let analysisPixelMap: image.PixelMap | undefined = undefined;
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);
    try {
      analysisPixelMap = await this.editableRgbaCopy(pixelMap);
      const shouldAnalyzeBody = this.shouldRefreshBodyLandmarks(startMs);
      const ok = await this.engine.analyzePixelMap(analysisPixelMap, true, shouldAnalyzeBody);
      this.previewAspectRatio = this.displayPreviewAspectRatio;
      this.faceLandmarks = this.engine.latestAllFaceLandmarks();
      const nextBody = this.engine.latestBodyLandmarks();
      this.bodyLandmarks = this.faceLandmarks.length > 0 ? nextBody : [];
      this.scheduleLandmarkDraw();
      this.status = ok ? '相机预览中' : '当前帧处理失败';
    } finally {
      try {
        analysisPixelMap?.release();
      } catch (_) {
      }
    }
  }

  private async editableRgbaCopy(source: image.PixelMap): Promise<image.PixelMap> {
    try {
      await source.convertPixelFormat(image.PixelMapFormat.RGBA_8888);
    } catch (_) {
    }
    const info = await source.getImageInfo();
    const rowStride = info.stride > 0 ? info.stride : info.size.width * 4;
    const buffer = new ArrayBuffer(rowStride * info.size.height);
    await source.readPixelsToBuffer(buffer);
    return image.createPixelMap(buffer, {
      size: { width: info.size.width, height: info.size.height },
      srcPixelFormat: info.pixelFormat,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      editable: true,
    });
  }

  private normalizedRotationDegrees(degrees: number): number {
    const value = degrees % 360;
    return value < 0 ? value + 360 : value;
  }

  private rotatedYuvWidth(frame: CameraYuv420Frame): number {
    const rotation = this.normalizedRotationDegrees(frame.rotationDegrees);
    return rotation === 90 || rotation === 270 ? frame.height : frame.width;
  }

  private rotatedYuvHeight(frame: CameraYuv420Frame): number {
    const rotation = this.normalizedRotationDegrees(frame.rotationDegrees);
    return rotation === 90 || rotation === 270 ? frame.width : frame.height;
  }

  private rotatedNativeImageWidth(frame: CameraNativeImageFrame): number {
    const rotation = this.normalizedRotationDegrees(frame.rotationDegrees);
    return rotation === 90 || rotation === 270 ? frame.height : frame.width;
  }

  private rotatedNativeImageHeight(frame: CameraNativeImageFrame): number {
    const rotation = this.normalizedRotationDegrees(frame.rotationDegrees);
    return rotation === 90 || rotation === 270 ? frame.width : frame.height;
  }

  private reusableOutputRgba(width: number, height: number): ArrayBuffer {
    if (this.cameraOutputRgba === undefined ||
      this.cameraOutputWidth !== width ||
      this.cameraOutputHeight !== height ||
      this.cameraOutputRgba.byteLength !== width * height * 4) {
      this.cameraOutputRgba = new ArrayBuffer(width * height * 4);
      this.cameraOutputWidth = width;
      this.cameraOutputHeight = height;
    }
    return this.cameraOutputRgba;
  }

  private releaseProcessedPreview(): void {
    const activePreview = this.previewPixelMap;
    const activePreviewIsPooled = activePreview !== undefined && this.isPooledPreviewPixelMap(activePreview);
    if (activePreview !== undefined && !activePreviewIsPooled) {
      try {
        activePreview.release();
      } catch (_) {
      }
    }
    this.releasePreviewPixelMapPool();
    this.previewPixelMap = undefined;
  }

  private releasePreviewPixelMapPool(): void {
    this.previewPixelMapPool.forEach((pixelMap: image.PixelMap) => {
      try {
        pixelMap.release();
      } catch (_) {
      }
    });
    this.previewPixelMapPool = [];
    this.previewPixelMapPoolWidth = 0;
    this.previewPixelMapPoolHeight = 0;
    this.previewPixelMapPoolIndex = 0;
  }

  private isPooledPreviewPixelMap(pixelMap: image.PixelMap): boolean {
    return this.previewPixelMapPool.indexOf(pixelMap) >= 0;
  }

  private async pooledPreviewPixelMapFromRgba(rgba: ArrayBuffer, width: number, height: number): Promise<image.PixelMap> {
    if (this.previewPixelMapPoolWidth !== width || this.previewPixelMapPoolHeight !== height) {
      this.releasePreviewPixelMapPool();
      this.previewPixelMapPoolWidth = width;
      this.previewPixelMapPoolHeight = height;
    }
    if (this.previewPixelMapPool.length < 2) {
      const pixelMap = await image.createPixelMap(rgba, {
        size: { width, height },
        srcPixelFormat: image.PixelMapFormat.RGBA_8888,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: true,
      });
      this.previewPixelMapPool.push(pixelMap);
      this.previewPixelMapPoolIndex = this.previewPixelMapPool.length % 2;
      return pixelMap;
    }
    const pixelMap = this.previewPixelMapPool[this.previewPixelMapPoolIndex];
    this.previewPixelMapPoolIndex = (this.previewPixelMapPoolIndex + 1) % this.previewPixelMapPool.length;
    try {
      pixelMap.writeBufferToPixelsSync(rgba);
    } catch (_) {
      await pixelMap.writeBufferToPixels(rgba);
    }
    return pixelMap;
  }

  private releaseFramePixelMap(frame: CameraFrame): void {
    if (frame.kind !== 'pixelMap') {
      return;
    }
    try {
      frame.pixelMap.release();
    } catch (_) {
    }
  }

  private syncLandmarksFromEngine(): void {
    const nextFaceLandmarks = this.engine.latestAllFaceLandmarks();
    const nextMakeupLandmarks = this.engine.latestMakeupLandmarks();
    this.faceLandmarks = this.shouldUseMakeupLandmarksForOverlay() && nextMakeupLandmarks.length > 0 ?
      nextMakeupLandmarks : nextFaceLandmarks;
    this.bodyLandmarks = this.engine.latestBodyLandmarks();
    this.scheduleLandmarkDraw();
  }

  private cameraFramePayload(frame: CameraYuv420Frame): UyaliYuv420Frame {
    return {
      y: frame.y,
      u: frame.u,
      v: frame.v,
      width: frame.width,
      height: frame.height,
      yRowStride: frame.yRowStride,
      yPixelStride: frame.yPixelStride,
      uRowStride: frame.uRowStride,
      uPixelStride: frame.uPixelStride,
      vRowStride: frame.vRowStride,
      vPixelStride: frame.vPixelStride,
      rotationDegrees: frame.rotationDegrees,
      timestampNanos: frame.timestampNanos,
    };
  }

  private async handleCameraFrame(frame: CameraFrame, fromFrameStream: boolean = true): Promise<void> {
    if (fromFrameStream) {
      this.latestFrameStreamMs = Date.now();
    }
    if (this.cameraFrameBusy) {
      this.releaseFramePixelMap(frame);
      return;
    }
    this.cameraFrameBusy = true;
    try {
      await this.processCameraFrame(frame);
    } finally {
      this.cameraFrameBusy = false;
    }
  }

  private async processCameraFrame(frame: CameraFrame): Promise<void> {
    const startMs = Date.now();
    if (!this.shouldProcessCameraFrame()) {
      this.releaseProcessedPreview();
      this.releaseFramePixelMap(frame);
      this.status = '相机预览中';
      return;
    }
    const activeEffects = this.hasAnyActiveEffect();
    const pointOnly = this.showLandmarks && !activeEffects;
    const shouldDetectNow = this.shouldRefreshLandmarks(startMs);
    const wantsFace = this.showLandmarks || this.hasFaceLandmarkDependentEffect();
    const wantsBody = this.showLandmarks || this.hasBodyLandmarkDependentEffect();
    const analyzeFace = wantsFace && (activeEffects || shouldDetectNow || this.hasRealtimeFaceMaskEffect());
    const analyzeBody = shouldDetectNow && wantsBody && this.shouldRefreshBodyLandmarks(startMs);
    this.engine.setCameraFrameAnalysis({ analyzeFace, analyzeBody });
    syncBeautyState(this.engine, this.values, this.makeupTypes, this.frontCamera);

    let ok = false;
    let pixelMap: image.PixelMap | undefined = undefined;
    if (frame.kind === 'yuv420') {
      const framePayload = this.cameraFramePayload(frame);
      if (this.displaySurfaceId.length === 0 && !this.refreshDisplaySurfaceId()) {
        this.releaseProcessedPreview();
        this.status = '正在准备预览';
        return;
      }
      const result = this.engine.processCameraFrame(framePayload);
      ok = result.ok;
      this.previewAspectRatio = this.displayPreviewAspectRatio;
      this.releaseProcessedPreview();
      this.syncLandmarksFromEngine();
      this.status = ok ? (activeEffects ? '实时美颜中' : '相机预览中') : '当前帧处理失败';
      return;
    } else if (frame.kind === 'nativeImage') {
      const framePayload: UyaliNativeImageFrame = {
        imageObject: frame.imageObject,
        width: frame.width,
        height: frame.height,
        rotationDegrees: frame.rotationDegrees,
        timestampNanos: frame.timestampNanos,
      };
      if (this.displaySurfaceId.length === 0 && !this.refreshDisplaySurfaceId()) {
        this.releaseProcessedPreview();
        this.status = '正在准备预览';
        return;
      }
      const result = this.engine.processCameraFrame(framePayload);
      ok = result.ok;
      this.previewAspectRatio = this.displayPreviewAspectRatio;
      this.releaseProcessedPreview();
      this.syncLandmarksFromEngine();
      this.status = ok ? (activeEffects ? '实时美颜中' : '相机预览中') : '当前帧处理失败';
      return;
    } else {
      pixelMap = frame.pixelMap;
      if (pointOnly) {
        await this.handleAnalysisPixelMap(pixelMap);
        this.releaseFramePixelMap(frame);
        return;
      }
      ok = await this.engine.processPixelMapInPlace(pixelMap);
    }
    if (pixelMap === undefined) {
      this.status = '当前帧处理失败';
      return;
    }
    this.previewAspectRatio = this.displayPreviewAspectRatio;
    if (this.previewPixelMap !== undefined &&
      this.previewPixelMap !== pixelMap &&
      !this.isPooledPreviewPixelMap(this.previewPixelMap)) {
      try {
        this.previewPixelMap.release();
      } catch (_) {
      }
    }
    this.previewPixelMap = pixelMap;
    this.syncLandmarksFromEngine();
    this.status = ok ? '实时美颜中' : '当前帧处理失败';
  }

  @Builder
  private LandmarkOverlay() {
    if (this.showLandmarks) {
      Canvas(this.landmarkCanvasContext)
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
        .onReady(() => {
          this.drawLandmarkCanvas();
        });
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
        Text('相机美颜')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111318');
        Text('实时预览美颜效果')
          .fontSize(12)
          .fontColor('#687181');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
      Button(this.running ? '停止' : '启动')
        .height(38)
        .onClick(() => {
          if (this.running) {
            this.stopCamera();
          } else {
            this.startCamera();
          }
        });
      Button('切换')
        .height(38)
        .onClick(() => {
          this.switchCamera();
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
            .width(38)
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
            .width(38)
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
          XComponent({
            type: XComponentType.SURFACE,
            controller: this.xComponentController,
          })
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .hitTestBehavior(HitTestMode.None)
            .onLoad(async () => {
              this.refreshDisplaySurfaceId();
              this.xComponentController.setXComponentSurfaceRotation({ lock: true });
              await this.startCamera();
            })
            .onAreaChange((_oldValue: Area, newValue: Area) => {
              this.updateDisplaySurfaceSize(Number(newValue.width), Number(newValue.height));
              this.refreshDisplaySurfaceId();
            });

          if (this.previewPixelMap !== undefined && this.shouldShowProcessedPreview()) {
            Image(this.previewPixelMap)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .backgroundColor('#000000');
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
          Button('切换')
            .fontSize(15)
            .fontColor('#2589FF')
            .backgroundColor('#00000000')
            .width(64)
            .height(50)
            .onClick(() => {
              this.switchCamera();
            });
        }
        .width('100%')
        .height(86)
        .padding({ left: 6, right: 6, top: 36 });

        Blank()
          .layoutWeight(1);

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
