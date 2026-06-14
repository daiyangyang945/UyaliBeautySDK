import image from '@ohos.multimedia.image';
import { camera } from '@kit.CameraKit';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import native from 'libuyali_beauty_harmony.so';

export interface CameraYuv420Frame {
  kind: 'yuv420';
  y: ArrayBuffer;
  u: ArrayBuffer;
  v: ArrayBuffer;
  width: number;
  height: number;
  yRowStride: number;
  yPixelStride: number;
  uRowStride: number;
  uPixelStride: number;
  vRowStride: number;
  vPixelStride: number;
  rotationDegrees: number;
  timestampNanos?: number;
}

export interface CameraPixelMapFrame {
  kind: 'pixelMap';
  pixelMap: image.PixelMap;
}

export interface CameraNativeImageFrame {
  kind: 'nativeImage';
  imageObject: image.Image;
  width: number;
  height: number;
  rotationDegrees: number;
  timestampNanos?: number;
}

export type CameraFrame = CameraYuv420Frame | CameraPixelMapFrame | CameraNativeImageFrame;
export type CameraFrameCallback = (frame: CameraFrame) => Promise<void>;
export type CameraStatusCallback = (message: string) => void;
export type CameraProfileCallback = (width: number, height: number) => void;

const CAMERA_FORMAT_RGBA_8888 = 3;
const CAMERA_FORMAT_YUV_420_SP = 1003;
const CAMERA_FORMAT_JPEG = 2000;
const IMAGE_FORMAT_YCBCR_422_SP = 1000;
const REALTIME_FRAME_TARGET_MAX_SIDE = 1280;
const REALTIME_FRAME_HARD_MAX_SIDE = 1440;
const ASPECT_MATCHED_FRAME_TARGET_MAX_SIDE = 1280;
const ASPECT_MATCHED_FRAME_SOFT_MAX_SIDE = 1440;
const FRAME_ASPECT_TOLERANCE = 0.025;
const IMAGE_RECEIVER_QUEUE_SIZE = 2;

export class DemoCameraController {
  private context: Context;
  private onFrame: CameraFrameCallback;
  private onStatus: CameraStatusCallback;
  private onProfile?: CameraProfileCallback;
  private cameraManager?: camera.CameraManager;
  private cameraInput?: camera.CameraInput;
  private session?: camera.PhotoSession;
  private displayPreviewOutput?: camera.PreviewOutput;
  private framePreviewOutput?: camera.PreviewOutput;
  private receiver?: image.ImageReceiver;
  private processingFrame: boolean = false;
  private droppingFrame: boolean = false;
  private started: boolean = false;
  private previewProfileFormat: number = CAMERA_FORMAT_YUV_420_SP;
  private receiverFormat: number = IMAGE_FORMAT_YCBCR_422_SP;
  private frameCount: number = 0;
  private position: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_FRONT;
  private nativeImageFastPath: boolean = false;
  private cachedFrameRotationDegrees?: number = undefined;

  constructor(context: Context,
    onFrame: CameraFrameCallback,
    onStatus: CameraStatusCallback,
    onProfile?: CameraProfileCallback) {
    this.context = context;
    this.onFrame = onFrame;
    this.onStatus = onStatus;
    this.onProfile = onProfile;
  }

  async start(frontCamera: boolean, displaySurfaceId: string = ''): Promise<void> {
    await this.stop();
    this.position = frontCamera ? camera.CameraPosition.CAMERA_POSITION_FRONT :
      camera.CameraPosition.CAMERA_POSITION_BACK;
    try {
      this.cameraManager = camera.getCameraManager(this.context);
      const device = this.pickDevice(this.position);
      if (device === undefined) {
        this.onStatus('没有找到可用摄像头');
        return;
      }
      this.cameraInput = this.cameraManager.createCameraInput(device);
      await this.cameraInput.open();

      const sceneMode = camera.SceneMode.NORMAL_PHOTO;
      const profiles = this.supportedPreviewProfiles(device, sceneMode);
      const displayProfile = this.pickDisplayPreviewProfile(profiles);
      const frameProfile = this.pickFramePreviewProfile(profiles, displayProfile);
      this.previewProfileFormat = frameProfile.format;
      this.onProfile?.(displayProfile.size.width, displayProfile.size.height);
      this.frameCount = 0;
      this.nativeImageFastPath = false;
      this.cachedFrameRotationDegrees = undefined;
      if (displaySurfaceId.length > 0) {
        this.displayPreviewOutput = this.cameraManager.createPreviewOutput(displayProfile, displaySurfaceId);
      }
      this.receiver = this.createReceiver(frameProfile);
      const surfaceId = await this.receiver.getReceivingSurfaceId();
      this.listenToFrames(this.receiver);
      this.framePreviewOutput = this.cameraManager.createPreviewOutput(frameProfile, surfaceId);

      const session = this.cameraManager.createSession(sceneMode) as camera.PhotoSession;
      session.beginConfig();
      session.addInput(this.cameraInput);
      if (this.displayPreviewOutput !== undefined) {
        session.addOutput(this.displayPreviewOutput);
      }
      session.addOutput(this.framePreviewOutput);
      await session.commitConfig();
      await session.start();
      this.session = session;
      this.started = true;
      this.onStatus(`${frontCamera ? '前置' : '后置'}相机已启动`);
    } catch (error) {
      await this.stop();
      const err = error as BusinessError;
      this.onStatus(`相机启动失败: ${err.message ?? JSON.stringify(error)}`);
    }
  }

  async stop(): Promise<void> {
    this.started = false;
    this.processingFrame = false;
    this.droppingFrame = false;
    try {
      await this.session?.stop();
    } catch (_) {
    }
    try {
      await this.displayPreviewOutput?.release();
    } catch (_) {
    }
    try {
      await this.framePreviewOutput?.release();
    } catch (_) {
    }
    try {
      this.receiver?.off('imageArrival');
      await this.receiver?.release();
    } catch (_) {
    }
    try {
      await this.cameraInput?.close();
    } catch (_) {
    }
    try {
      await this.session?.release();
    } catch (_) {
    }
    this.session = undefined;
    this.displayPreviewOutput = undefined;
    this.framePreviewOutput = undefined;
    this.receiver = undefined;
    this.cameraInput = undefined;
    this.cachedFrameRotationDegrees = undefined;
  }

  private pickDevice(position: camera.CameraPosition): camera.CameraDevice | undefined {
    const devices = this.cameraManager?.getSupportedCameras() ?? [];
    return devices.find((device: camera.CameraDevice) => device.cameraPosition === position) ?? devices[0];
  }

  private supportedPreviewProfiles(device: camera.CameraDevice, sceneMode: camera.SceneMode): camera.Profile[] {
    const outputCapability = this.cameraManager?.getSupportedOutputCapability(device, sceneMode);
    const profiles = outputCapability?.previewProfiles ?? [];
    if (profiles.length === 0) {
      throw new Error('No preview profile');
    }
    const sortedProfiles = profiles.sort((a: camera.Profile, b: camera.Profile) => {
      const aScore = this.displayProfileScore(a);
      const bScore = this.displayProfileScore(b);
      return aScore - bScore;
    });
    const formatSummary = sortedProfiles.map((profile: camera.Profile) =>
      `${profile.format}:${profile.size.width}x${profile.size.height}`).join(',');
    this.onStatus(`可用相机格式 ${formatSummary}`);
    return sortedProfiles;
  }

  private pickDisplayPreviewProfile(sortedProfiles: camera.Profile[]): camera.Profile {
    const displayProfiles = sortedProfiles.filter((profile: camera.Profile) =>
      profile.format === IMAGE_FORMAT_YCBCR_422_SP ||
        profile.format === CAMERA_FORMAT_YUV_420_SP ||
        profile.format === CAMERA_FORMAT_RGBA_8888 ||
        profile.format === CAMERA_FORMAT_JPEG);
    const candidates = displayProfiles.length > 0 ? displayProfiles : sortedProfiles;
    return candidates.sort((a: camera.Profile, b: camera.Profile) =>
      this.displayProfileScore(a) - this.displayProfileScore(b))[0];
  }

  private pickFramePreviewProfile(sortedProfiles: camera.Profile[], displayProfile: camera.Profile): camera.Profile {
    const realtimeProfiles = sortedProfiles.filter((profile: camera.Profile) =>
      profile.format === IMAGE_FORMAT_YCBCR_422_SP ||
        profile.format === CAMERA_FORMAT_YUV_420_SP ||
        profile.format === CAMERA_FORMAT_RGBA_8888);
    const targetAspect = this.profileAspect(displayProfile);
    const aspectMatchedRealtimeProfiles = realtimeProfiles.filter((profile: camera.Profile) =>
      this.profileAspectDelta(profile, targetAspect) <= FRAME_ASPECT_TOLERANCE);
    if (aspectMatchedRealtimeProfiles.length > 0) {
      return aspectMatchedRealtimeProfiles.sort((a: camera.Profile, b: camera.Profile) =>
        this.aspectMatchedFrameProfileScore(a, targetAspect) -
          this.aspectMatchedFrameProfileScore(b, targetAspect))[0];
    }

    const aspectMatchedProfiles = sortedProfiles.filter((profile: camera.Profile) =>
      this.profileAspectDelta(profile, targetAspect) <= FRAME_ASPECT_TOLERANCE);
    if (aspectMatchedProfiles.length > 0) {
      return aspectMatchedProfiles.sort((a: camera.Profile, b: camera.Profile) =>
        this.aspectMatchedFrameProfileScore(a, targetAspect) -
          this.aspectMatchedFrameProfileScore(b, targetAspect))[0];
    }

    const boundedProfiles = realtimeProfiles.filter((profile: camera.Profile) =>
      Math.max(profile.size.width, profile.size.height) <= REALTIME_FRAME_HARD_MAX_SIDE);
    const candidates = boundedProfiles.length > 0 ? boundedProfiles :
      (realtimeProfiles.length > 0 ? realtimeProfiles : sortedProfiles);
    return candidates.sort((a: camera.Profile, b: camera.Profile) =>
      this.realtimeProfileScore(a, targetAspect) - this.realtimeProfileScore(b, targetAspect))[0];
  }

  private realtimeProfileScore(profile: camera.Profile, targetAspect: number): number {
    const maxSide = Math.max(profile.size.width, profile.size.height);
    const aspect = this.profileAspect(profile);
    const formatScore = profile.format === IMAGE_FORMAT_YCBCR_422_SP ? 0 :
      (profile.format === CAMERA_FORMAT_YUV_420_SP ? 1200 :
        (profile.format === CAMERA_FORMAT_RGBA_8888 ? 2500 : 50000));
    const sizeScore = Math.abs(maxSide - REALTIME_FRAME_TARGET_MAX_SIDE);
    const oversizeScore = maxSide > REALTIME_FRAME_HARD_MAX_SIDE ? (maxSide - REALTIME_FRAME_HARD_MAX_SIDE) * 12 : 0;
    const aspectScore = Math.round(Math.abs(aspect - targetAspect) * 12000);
    const squarePenalty = aspect > 0.82 && targetAspect < 0.72 ? 16000 : 0;
    return formatScore + sizeScore + oversizeScore + aspectScore + squarePenalty;
  }

  private aspectMatchedFrameProfileScore(profile: camera.Profile, targetAspect: number): number {
    const maxSide = Math.max(profile.size.width, profile.size.height);
    const formatScore = profile.format === IMAGE_FORMAT_YCBCR_422_SP ? 0 :
      (profile.format === CAMERA_FORMAT_YUV_420_SP ? 1200 :
        (profile.format === CAMERA_FORMAT_RGBA_8888 ? 2500 :
          (profile.format === CAMERA_FORMAT_JPEG ? 14000 : 50000)));
    const sizeScore = Math.abs(maxSide - ASPECT_MATCHED_FRAME_TARGET_MAX_SIDE);
    const oversizeScore = maxSide > ASPECT_MATCHED_FRAME_SOFT_MAX_SIDE ?
      (maxSide - ASPECT_MATCHED_FRAME_SOFT_MAX_SIDE) * 10 : 0;
    const aspectScore = Math.round(this.profileAspectDelta(profile, targetAspect) * 80000);
    return formatScore + sizeScore + oversizeScore + aspectScore;
  }

  private displayProfileScore(profile: camera.Profile): number {
    const maxSide = Math.max(profile.size.width, profile.size.height);
    const aspect = this.profileAspect(profile);
    const portraitAspect = 9 / 16;
    const formatScore = profile.format === IMAGE_FORMAT_YCBCR_422_SP ? 0 :
      (profile.format === CAMERA_FORMAT_YUV_420_SP ? 800 :
        (profile.format === CAMERA_FORMAT_RGBA_8888 ? 2200 :
          (profile.format === CAMERA_FORMAT_JPEG ? 12000 : 50000)));
    const aspectScore = Math.round(Math.abs(aspect - portraitAspect) * 12000);
    const squarePenalty = aspect > 0.82 ? 18000 : 0;
    const sizeScore = Math.abs(maxSide - 1280);
    return formatScore + aspectScore + squarePenalty + sizeScore;
  }

  private profileAspect(profile: camera.Profile): number {
    const maxSide = Math.max(profile.size.width, profile.size.height);
    const minSide = Math.min(profile.size.width, profile.size.height);
    return maxSide > 0 ? minSide / maxSide : 1;
  }

  private profileAspectDelta(profile: camera.Profile, targetAspect: number): number {
    return Math.abs(this.profileAspect(profile) - targetAspect);
  }

  private createReceiver(profile: camera.Profile): image.ImageReceiver {
    let lastError = '';
    if (profile.format === CAMERA_FORMAT_JPEG) {
      try {
        const receiver = image.createImageReceiver({
          width: profile.size.width,
          height: profile.size.height,
        }, image.ImageFormat.JPEG, IMAGE_RECEIVER_QUEUE_SIZE);
        this.receiverFormat = CAMERA_FORMAT_JPEG;
        return receiver;
      } catch (error) {
        const err = error as BusinessError;
        lastError = err.message ?? JSON.stringify(error);
      }
    }

    if (profile.format === IMAGE_FORMAT_YCBCR_422_SP || profile.format === CAMERA_FORMAT_YUV_420_SP) {
      try {
        const receiver = image.createImageReceiver({
          width: profile.size.width,
          height: profile.size.height,
        }, image.ImageFormat.YCBCR_422_SP, IMAGE_RECEIVER_QUEUE_SIZE);
        this.receiverFormat = IMAGE_FORMAT_YCBCR_422_SP;
        return receiver;
      } catch (error) {
        const err = error as BusinessError;
        lastError = err.message ?? JSON.stringify(error);
      }
    }

    const candidateFormats: number[] = profile.format === CAMERA_FORMAT_YUV_420_SP ?
      [IMAGE_FORMAT_YCBCR_422_SP, CAMERA_FORMAT_JPEG] :
      [profile.format, IMAGE_FORMAT_YCBCR_422_SP, CAMERA_FORMAT_JPEG];
    for (const format of candidateFormats) {
      try {
        const receiver = image.createImageReceiver(profile.size.width, profile.size.height, format, IMAGE_RECEIVER_QUEUE_SIZE);
        this.receiverFormat = format;
        return receiver;
      } catch (error) {
        const err = error as BusinessError;
        lastError = err.message ?? JSON.stringify(error);
      }
    }
    throw new Error(`ImageReceiver 创建失败: ${lastError}`);
  }

  private listenToFrames(receiver: image.ImageReceiver): void {
    receiver.on('imageArrival', async () => {
      if (this.processingFrame) {
        this.dropPendingFrame(receiver);
        return;
      }
      this.processingFrame = true;
      let nextImage: image.Image | undefined = undefined;
      try {
        nextImage = await receiver.readLatestImage();
        if (nextImage === undefined || nextImage.size === undefined) {
          this.onStatus('取帧失败: ImageReceiver 返回空帧');
          return;
        }
        const imageWidth = nextImage.size.width;
        const imageHeight = nextImage.size.height;
        const frame = await this.frameFromImage(nextImage);
        this.frameCount += 1;
        if (this.frameCount === 1 || this.frameCount % 30 === 0) {
          this.onStatus(`已接收相机帧 ${this.frameCount} fmt=${nextImage.format}` +
            ` ${imageWidth}x${imageHeight} rot=${this.frameRotationDegrees(imageWidth, imageHeight)}`);
        }
        await this.onFrame(frame);
      } catch (error) {
        const frameError = error as BusinessError;
        this.onStatus(`取帧失败: ${frameError.message ?? JSON.stringify(error)}`);
      } finally {
        try {
          await nextImage?.release();
        } catch (_) {
        }
        this.processingFrame = false;
      }
    });
  }

  private dropPendingFrame(receiver: image.ImageReceiver): void {
    if (this.droppingFrame) {
      return;
    }
    this.droppingFrame = true;
    receiver.readLatestImage(async (_err: BusinessError, nextImage: image.Image) => {
      try {
        await nextImage?.release();
      } catch (_) {
      } finally {
        this.droppingFrame = false;
      }
    });
  }

  private async frameFromImage(nextImage: image.Image): Promise<CameraFrame> {
    const format = nextImage.format;
    if (format !== CAMERA_FORMAT_JPEG) {
      if (this.nativeImageFastPath) {
        return this.nativeImageFrame(nextImage);
      }
      try {
        const y = await nextImage.getComponent(image.ComponentType.YUV_Y);
        const u = await nextImage.getComponent(image.ComponentType.YUV_U);
        const v = await nextImage.getComponent(image.ComponentType.YUV_V);
        return {
          kind: 'yuv420',
          y: y.byteBuffer,
          u: u.byteBuffer,
          v: v.byteBuffer,
          width: nextImage.size.width,
          height: nextImage.size.height,
          yRowStride: y.rowStride,
          yPixelStride: y.pixelStride,
          uRowStride: u.rowStride,
          uPixelStride: u.pixelStride,
          vRowStride: v.rowStride,
          vPixelStride: v.pixelStride,
          rotationDegrees: this.frameRotationDegrees(nextImage.size.width, nextImage.size.height),
          timestampNanos: nextImage.timestamp,
        };
      } catch (error) {
        const err = error as BusinessError;
        let probe = 'probe=unavailable';
        try {
          probe = native.probeImageComponents(nextImage);
        } catch (probeError) {
          const probeErr = probeError as BusinessError;
          probe = `probeError=${probeErr.message ?? JSON.stringify(probeError)}`;
        }
        if (probe.indexOf('comps=none') < 0 && probe.indexOf('nativeProbe') >= 0) {
          this.nativeImageFastPath = true;
          return this.nativeImageFrame(nextImage);
        }
        throw new Error(`YUV组件不可读 fmt=${format} size=${nextImage.size.width}x${nextImage.size.height}` +
          ` profile=${this.previewProfileFormat} receiver=${this.receiverFormat}` +
          ` err=${err.message ?? JSON.stringify(error)} | ${probe}`);
      }
    }
    if (format === CAMERA_FORMAT_JPEG || this.previewProfileFormat === CAMERA_FORMAT_JPEG) {
      const imgComponent = await nextImage.getComponent(image.ComponentType.JPEG);
      const pixelMap = this.previewProfileFormat === CAMERA_FORMAT_JPEG ?
        await this.pixelMapFromComponent(imgComponent, nextImage.size.width, nextImage.size.height) :
        await this.pixelMapFromNv21Component(imgComponent, nextImage.size.width, nextImage.size.height);
      await this.correctPreviewOrientation(pixelMap);
      return {
        kind: 'pixelMap',
        pixelMap,
      };
    }
    throw new Error(`Unsupported camera frame format: ${format}`);
  }

  private nativeImageFrame(nextImage: image.Image): CameraNativeImageFrame {
    return {
      kind: 'nativeImage',
      imageObject: nextImage,
      width: nextImage.size.width,
      height: nextImage.size.height,
      rotationDegrees: this.frameRotationDegrees(nextImage.size.width, nextImage.size.height),
      timestampNanos: nextImage.timestamp,
    };
  }

  private async pixelMapFromComponent(imgComponent: image.Component, width: number, height: number): Promise<image.PixelMap> {
    if (this.previewProfileFormat === CAMERA_FORMAT_JPEG) {
      const imageSource = image.createImageSource(imgComponent.byteBuffer);
      try {
        return await imageSource.createPixelMap({
          editable: true,
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
        });
      } finally {
        imageSource.release();
      }
    }
    return image.createPixelMap(imgComponent.byteBuffer, {
      size: { width, height },
      srcPixelFormat: image.PixelMapFormat.RGBA_8888,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      editable: true,
    });
  }

  private async pixelMapFromNv21Component(imgComponent: image.Component, width: number, height: number): Promise<image.PixelMap> {
    const rowStride = imgComponent.rowStride > 0 ? imgComponent.rowStride : width;
    const planeHeight = Math.floor(height * 3 / 2);
    let buffer: ArrayBuffer = imgComponent.byteBuffer;
    if (rowStride !== width) {
      const input = new Uint8Array(imgComponent.byteBuffer);
      const packedBuffer: ArrayBuffer = new ArrayBuffer(width * planeHeight);
      const packed = new Uint8Array(packedBuffer);
      for (let row = 0; row < planeHeight; row += 1) {
        const sourceStart = row * rowStride;
        const targetStart = row * width;
        packed.set(input.subarray(sourceStart, sourceStart + width), targetStart);
      }
      buffer = packedBuffer;
    }
    return image.createPixelMap(buffer, {
      size: { width, height },
      srcPixelFormat: image.PixelMapFormat.NV21,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      editable: true,
    });
  }

  private previewRotationDegrees(): number {
    let displayRotation = 0;
    try {
      const displayDefault = display.getDefaultDisplaySync();
      displayRotation = (displayDefault.rotation ?? 0) * camera.ImageRotation.ROTATION_90;
    } catch (_) {
    }
    try {
      return this.framePreviewOutput?.getPreviewRotation(displayRotation) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  private frameRotationDegrees(width: number, height: number): number {
    if (this.cachedFrameRotationDegrees !== undefined) {
      return this.cachedFrameRotationDegrees;
    }
    const rotation = this.previewRotationDegrees();
    if (rotation !== 0 || width <= height) {
      this.cachedFrameRotationDegrees = rotation;
      return rotation;
    }
    this.cachedFrameRotationDegrees = this.position === camera.CameraPosition.CAMERA_POSITION_FRONT ?
      camera.ImageRotation.ROTATION_270 :
      camera.ImageRotation.ROTATION_90;
    return this.cachedFrameRotationDegrees;
  }

  private async correctPreviewOrientation(pixelMap: image.PixelMap): Promise<void> {
    let displayRotation = 0;
    try {
      const displayDefault = display.getDefaultDisplaySync();
      displayRotation = (displayDefault.rotation ?? 0) * camera.ImageRotation.ROTATION_90;
    } catch (_) {
    }
    try {
      const rotation = this.previewRotationDegrees();
      if (this.position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        if (displayRotation === 90 || displayRotation === 270) {
          await pixelMap.rotate((rotation + 180) % 360);
        } else {
          await pixelMap.rotate(rotation);
        }
        await pixelMap.flip(true, false);
      } else {
        await pixelMap.rotate(rotation);
      }
    } catch (_) {
    }
  }
}
