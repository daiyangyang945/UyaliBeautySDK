import image from '@ohos.multimedia.image';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

function packRgbaRows(buffer: ArrayBuffer, width: number, height: number, rowStride: number): ArrayBuffer {
  const compactStride = width * 4;
  if (rowStride === compactStride) {
    return buffer;
  }
  const input = new Uint8Array(buffer);
  const packedBuffer = new ArrayBuffer(compactStride * height);
  const packed = new Uint8Array(packedBuffer);
  for (let row = 0; row < height; row += 1) {
    const sourceStart = row * rowStride;
    const targetStart = row * compactStride;
    packed.set(input.subarray(sourceStart, sourceStart + compactStride), targetStart);
  }
  return packedBuffer;
}

export async function createDemoPortraitPixelMap(context?: Context,
  width: number = 720,
  height: number = 960): Promise<image.PixelMap> {
  if (context !== undefined) {
    try {
      const bytes = context.resourceManager.getRawFileContentSync('uyali/demo/single_pose_portrait.jpeg');
      const buffer = new ArrayBuffer(bytes.byteLength);
      new Uint8Array(buffer).set(bytes);
      const imageSource = image.createImageSource(buffer);
      try {
        return await imageSource.createPixelMap({
          editable: true,
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
        });
      } finally {
        imageSource.release();
      }
    } catch (_) {
    }
  }

  const rgba = new ArrayBuffer(width * height * 4);
  const pixels = new Uint8Array(rgba);
  const cx = width * 0.5;
  const cy = height * 0.42;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const index = (y * width + x) * 4;
      const bg = 238 - Math.floor((y / height) * 34);
      pixels[index] = bg;
      pixels[index + 1] = bg + 5;
      pixels[index + 2] = bg + 9;
      pixels[index + 3] = 255;
      const faceMask = Math.max(0, 1 - Math.hypot((x - cx) / (width * 0.25), (y - cy) / (height * 0.27)));
      if (faceMask > 0) {
        const tone = Math.floor(faceMask * 54);
        pixels[index] = 183 + tone;
        pixels[index + 1] = 128 + Math.floor(tone * 0.62);
        pixels[index + 2] = 112 + Math.floor(tone * 0.42);
      }
      const bodyMask = Math.max(0, 1 - Math.hypot((x - cx) / (width * 0.34), (y - height * 0.82) / (height * 0.34)));
      if (bodyMask > 0) {
        pixels[index] = 92 + Math.floor(bodyMask * 52);
        pixels[index + 1] = 107 + Math.floor(bodyMask * 36);
        pixels[index + 2] = 145 + Math.floor(bodyMask * 24);
      }
    }
  }

  return image.createPixelMap(rgba, {
    size: { width, height },
    srcPixelFormat: image.PixelMapFormat.RGBA_8888,
    pixelFormat: image.PixelMapFormat.RGBA_8888,
    editable: true,
  });
}

export async function loadEditablePixelMap(uri: string, maxSide: number = 1440): Promise<image.PixelMap> {
  let file: fileIo.File | undefined = undefined;
  let imageSource: image.ImageSource | undefined = undefined;
  try {
    file = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
    imageSource = image.createImageSource(file.fd);
    const info = await imageSource.getImageInfo();
    const srcW = info.size.width;
    const srcH = info.size.height;
    const longSide = Math.max(srcW, srcH);
    let targetW = srcW;
    let targetH = srcH;
    if (longSide > maxSide) {
      const scale = maxSide / longSide;
      targetW = Math.max(1, Math.round(srcW * scale));
      targetH = Math.max(1, Math.round(srcH * scale));
    }

    const pixelMap = await imageSource.createPixelMap({
      editable: true,
      desiredSize: { width: targetW, height: targetH },
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
    });
    return pixelMap;
  } catch (error) {
    const err = error as BusinessError;
    throw new Error(`加载图片失败: ${err.message ?? JSON.stringify(error)}`);
  } finally {
    try {
      imageSource?.release();
    } catch (_) {
    }
    try {
      if (file !== undefined) {
        await fileIo.close(file);
      }
    } catch (_) {
    }
  }
}

export async function cloneEditablePixelMap(source: image.PixelMap): Promise<image.PixelMap> {
  const info = await source.getImageInfo();
  if (info.pixelFormat !== image.PixelMapFormat.RGBA_8888) {
    try {
      await source.convertPixelFormat(image.PixelMapFormat.RGBA_8888);
    } catch (_) {
    }
  }
  const updatedInfo = await source.getImageInfo();
  const width = updatedInfo.size.width;
  const height = updatedInfo.size.height;
  const stride = updatedInfo.stride > 0 ? updatedInfo.stride : width * 4;
  const buffer = new ArrayBuffer(stride * height);
  await source.readPixelsToBuffer(buffer);
  const packedBuffer = packRgbaRows(buffer, width, height, stride);
  return image.createPixelMap(packedBuffer, {
    size: { width, height },
    srcPixelFormat: image.PixelMapFormat.RGBA_8888,
    pixelFormat: image.PixelMapFormat.RGBA_8888,
    editable: true,
  });
}
