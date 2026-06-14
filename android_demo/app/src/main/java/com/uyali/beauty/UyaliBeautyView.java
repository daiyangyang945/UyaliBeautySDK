package com.uyali.beauty;

import android.content.Context;
import android.graphics.Bitmap;
import android.media.Image;
import android.graphics.SurfaceTexture;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.GLUtils;
import android.os.Handler;
import android.os.Looper;
import android.os.Process;
import android.util.AttributeSet;
import android.view.Surface;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

public class UyaliBeautyView extends GLSurfaceView implements GLSurfaceView.Renderer, SurfaceTexture.OnFrameAvailableListener {
    public interface CameraSurfaceListener {
        void onCameraSurfaceCreated(Surface surface, SurfaceTexture surfaceTexture);
        void onCameraSurfaceDestroyed();
    }

    public interface StillImageAnalysisListener {
        void onStillImageAnalysisComplete();
    }

    private static final long IMAGE_REFRESH_INTERVAL_MS = 33L;
    private static final float[] BITMAP_TEXTURE_TRANSFORM = {
            1, 0, 0, 0,
            0, -1, 0, 0,
            0, 0, 1, 0,
            0, 1, 0, 1
    };
    private static final float[] IDENTITY_TEXTURE_TRANSFORM = {
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
    };
    private static final int SYNC_CAMERA_FRAME_POOL_SIZE = 6;
    private static final long SYNC_FRAME_MATCH_TOLERANCE_NS = 50_000_000L;
    private static final long SYNC_FRAME_NO_STALENESS_LIMIT_NS = Long.MAX_VALUE;
    private static final String OES_COPY_VERTEX_SHADER =
            "attribute vec2 aPosition;\n" +
            "attribute vec2 aTexCoord;\n" +
            "uniform mat4 uTransform;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = vec4(aPosition, 0.0, 1.0);\n" +
            "    vTexCoord = (uTransform * vec4(aTexCoord, 0.0, 1.0)).xy;\n" +
            "}\n";
    private static final String OES_COPY_FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "uniform samplerExternalOES uTexture;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_FragColor = texture2D(uTexture, vTexCoord);\n" +
            "}\n";
    private static final String TEXTURE_2D_COPY_FRAGMENT_SHADER =
            "precision mediump float;\n" +
            "uniform sampler2D uTexture;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_FragColor = texture2D(uTexture, vTexCoord);\n" +
            "}\n";
    private static final String YUV_TO_RGB_FRAGMENT_SHADER =
            "precision mediump float;\n" +
            "uniform sampler2D uYTexture;\n" +
            "uniform sampler2D uUTexture;\n" +
            "uniform sampler2D uVTexture;\n" +
            "uniform int uRotation;\n" +
            "varying vec2 vTexCoord;\n" +
            "vec2 sourceCoord(vec2 p) {\n" +
            "    if (uRotation == 90) {\n" +
            "        return vec2(p.y, 1.0 - p.x);\n" +
            "    }\n" +
            "    if (uRotation == 180) {\n" +
            "        return vec2(1.0 - p.x, 1.0 - p.y);\n" +
            "    }\n" +
            "    if (uRotation == 270) {\n" +
            "        return vec2(1.0 - p.y, p.x);\n" +
            "    }\n" +
            "    return p;\n" +
            "}\n" +
            "void main() {\n" +
            "    vec2 uv = sourceCoord(vTexCoord);\n" +
            "    float y = texture2D(uYTexture, uv).r;\n" +
            "    float u = texture2D(uUTexture, uv).r - 0.5;\n" +
            "    float v = texture2D(uVTexture, uv).r - 0.5;\n" +
            "    vec3 rgb;\n" +
            "    rgb.r = y + 1.402 * v;\n" +
            "    rgb.g = y - 0.344136 * u - 0.714136 * v;\n" +
            "    rgb.b = y + 1.772 * u;\n" +
            "    gl_FragColor = vec4(clamp(rgb, 0.0, 1.0), 1.0);\n" +
            "}\n";
    private static final float[] FULLSCREEN_QUAD = {
            -1f, -1f, 0f, 0f,
             1f, -1f, 1f, 0f,
            -1f,  1f, 0f, 1f,
             1f,  1f, 1f, 1f
    };

    private final UyaliBeautyTextureProcessor textureProcessor;
    private final UyaliBeautyEngine engine;
    private final float[] transform = new float[16];
    private final FloatBuffer fullscreenQuadBuffer = ByteBuffer
            .allocateDirect(FULLSCREEN_QUAD.length * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer();
    private final AtomicBoolean frameAvailable = new AtomicBoolean(false);
    private final Object imageLock = new Object();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final Runnable imageRefreshTicker = new Runnable() {
        @Override
        public void run() {
            if (!imageMode || released) {
                return;
            }
            requestRender();
            mainHandler.postDelayed(this, IMAGE_REFRESH_INTERVAL_MS);
        }
    };

    private SurfaceTexture cameraSurfaceTexture;
    private Surface cameraSurface;
    private CameraSurfaceListener cameraSurfaceListener;
    private StillImageAnalysisListener stillImageAnalysisListener;
    private int oesTextureId;
    private int imageTextureId;
    private int viewWidth;
    private int viewHeight;
    private volatile int cameraBufferWidth;
    private volatile int cameraBufferHeight;
    private volatile int cameraRotationDegrees;
    private volatile boolean imageMode;
    private volatile boolean videoFrameMode;
    private volatile boolean processedVideoFrameMode;
    private volatile boolean processedYuvFrameMode;
    private volatile boolean gpuTextureProcessing = true;
    private volatile boolean released;
    private boolean surfaceReady;
    private boolean mirrorFrontCamera = false;
    private int imageTextureWidth;
    private int imageTextureHeight;
    private int imageWidth;
    private int imageHeight;
    private int imageGeneration;
    private ByteBuffer imageRgbaBuffer;
    private ByteBuffer pendingFrameUploadBuffer;
    private ByteBuffer spareFrameUploadBuffer;
    private ByteBuffer pendingYuvYBuffer;
    private ByteBuffer pendingYuvUBuffer;
    private ByteBuffer pendingYuvVBuffer;
    private ByteBuffer spareYuvYBuffer;
    private ByteBuffer spareYuvUBuffer;
    private ByteBuffer spareYuvVBuffer;
    private Bitmap pendingImageUploadBitmap;
    private int yuvSourceWidth;
    private int yuvSourceHeight;
    private int yuvRotationDegrees;
    private volatile boolean synchronizedCameraMode;
    private final SyncCameraFrame[] syncCameraFrames = new SyncCameraFrame[SYNC_CAMERA_FRAME_POOL_SIZE];
    private int syncCameraFrameCursor;
    private int syncCameraDisplayIndex = -1;
    private long pendingAnalyzedTimestampNs = Long.MIN_VALUE;
    private volatile long syncCameraFrameMaxStalenessNs = SYNC_FRAME_NO_STALENESS_LIMIT_NS;
    private int oesCopyProgram;
    private int textureCopyProgram;
    private int oesCopyFramebuffer;
    private int yuvToRgbProgram;
    private int yuvFramebuffer;
    private int yuvRgbTextureId;
    private int yuvYTextureId;
    private int yuvUTextureId;
    private int yuvVTextureId;
    private int yuvRgbTextureWidth;
    private int yuvRgbTextureHeight;
    private int yuvYTextureWidth;
    private int yuvYTextureHeight;
    private int yuvUTextureWidth;
    private int yuvUTextureHeight;
    private int yuvVTextureWidth;
    private int yuvVTextureHeight;

    public UyaliBeautyView(Context context) {
        this(context, null);
    }

    public UyaliBeautyView(Context context, AttributeSet attrs) {
        super(context, attrs);
        textureProcessor = new UyaliBeautyTextureProcessor(context);
        textureProcessor.setAnalysisCompleteListener(new UyaliBeautyTextureProcessor.AnalysisCompleteListener() {
            @Override
            public void onTextureAnalysisComplete(long timestampNanos) {
                if (!released && !imageMode) {
                    requestRender();
                }
            }
        });
        engine = textureProcessor.engine();
        fullscreenQuadBuffer.put(FULLSCREEN_QUAD);
        fullscreenQuadBuffer.position(0);
        setEGLContextClientVersion(3);
        setPreserveEGLContextOnPause(true);
        setRenderer(this);
        setRenderMode(RENDERMODE_WHEN_DIRTY);
    }

    public UyaliBeautyEngine engine() {
        return engine;
    }

    public UyaliBeautyTextureProcessor textureProcessor() {
        return textureProcessor;
    }

    public void setCameraSurfaceListener(CameraSurfaceListener listener) {
        cameraSurfaceListener = listener;
        if (listener != null && cameraSurface != null) {
            listener.onCameraSurfaceCreated(cameraSurface, cameraSurfaceTexture);
        }
    }

    public void setStillImageAnalysisListener(StillImageAnalysisListener listener) {
        stillImageAnalysisListener = listener;
    }

    public void setOutputMirrored(boolean mirrored) {
        this.mirrorFrontCamera = mirrored;
        requestRender();
    }

    void setOutputMirroredInternal(boolean mirrored) {
        setOutputMirrored(mirrored);
    }

    public void setCameraBufferSize(final int width, final int height) {
        setCameraBufferSize(width, height, 0);
    }

    public void setCameraBufferSize(final int width, final int height, final int rotationDegrees) {
        if (width <= 0 || height <= 0) {
            return;
        }
        cameraBufferWidth = width;
        cameraBufferHeight = height;
        cameraRotationDegrees = normalizeDegrees(rotationDegrees);
        queueEvent(new Runnable() {
            @Override
            public void run() {
                applyCameraBufferSize();
            }
        });
    }

    public void setSynchronizedCameraMode(final boolean enabled) {
        textureProcessor.setSynchronizedCameraMode(enabled);
        if (synchronizedCameraMode == enabled) {
            return;
        }
        synchronizedCameraMode = enabled;
        if (!enabled) {
            pendingAnalyzedTimestampNs = Long.MIN_VALUE;
            queueEvent(new Runnable() {
                @Override
                public void run() {
                    syncCameraDisplayIndex = -1;
                    for (SyncCameraFrame frame : syncCameraFrames) {
                        if (frame != null) {
                            frame.valid = false;
                        }
                    }
                    requestRender();
                }
            });
        } else {
            requestRender();
        }
    }

    public void setSynchronizedCameraFrameMaxStalenessNs(long maxStalenessNs) {
        syncCameraFrameMaxStalenessNs = maxStalenessNs <= 0L
                ? SYNC_FRAME_NO_STALENESS_LIMIT_NS
                : maxStalenessNs;
        textureProcessor.setSynchronizedCameraFrameMaxStalenessNs(syncCameraFrameMaxStalenessNs);
    }

    public void renderSynchronizedCameraFrame(final long timestampNs) {
        textureProcessor.notifyAnalyzedFrame(timestampNs);
        if (timestampNs <= 0L || released) {
            return;
        }
        pendingAnalyzedTimestampNs = timestampNs;
        if (!synchronizedCameraMode) {
            requestRender();
            return;
        }
        queueEvent(new Runnable() {
            @Override
            public void run() {
                pendingAnalyzedTimestampNs = timestampNs;
                selectSynchronizedCameraFrame(timestampNs);
                requestRender();
            }
        });
    }

    public void setImageBitmap(Bitmap bitmap) {
        if (bitmap == null || bitmap.isRecycled()) {
            clearImageBitmap();
            return;
        }
        final Bitmap uploadBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, false);
        if (uploadBitmap == null) {
            return;
        }
        final ByteBuffer rgba = UyaliBeautyEngine.bitmapToRgbaBuffer(uploadBitmap);
        if (rgba == null) {
            uploadBitmap.recycle();
            return;
        }
        final int width = uploadBitmap.getWidth();
        final int height = uploadBitmap.getHeight();
        final int generation;
        synchronized (imageLock) {
            imageMode = true;
            videoFrameMode = false;
            processedVideoFrameMode = false;
            imageWidth = width;
            imageHeight = height;
            imageRgbaBuffer = rgba;
            pendingFrameUploadBuffer = null;
            spareFrameUploadBuffer = null;
            if (pendingImageUploadBitmap != null && !pendingImageUploadBitmap.isRecycled()) {
                pendingImageUploadBitmap.recycle();
            }
            pendingImageUploadBitmap = uploadBitmap;
            imageGeneration++;
            generation = imageGeneration;
        }
        startImageRefresh();
        queueEvent(new Runnable() {
            @Override
            public void run() {
                uploadPendingImageTexture(generation);
            }
        });
        analyzeStillImage(rgba, width, height, generation);
    }

    public void setVideoRgbaFrame(ByteBuffer rgba, int width, int height, boolean mirrored) {
        setRgbaFrame(rgba, width, height, mirrored, false, true);
    }

    public ByteBuffer acquireVideoRgbaFrameBuffer(int requiredBytes) {
        if (requiredBytes <= 0) {
            return null;
        }
        synchronized (imageLock) {
            ByteBuffer buffer = spareFrameUploadBuffer != null && spareFrameUploadBuffer.capacity() >= requiredBytes
                    ? spareFrameUploadBuffer
                    : ByteBuffer.allocateDirect(requiredBytes);
            if (buffer == spareFrameUploadBuffer) {
                spareFrameUploadBuffer = null;
            }
            buffer.clear();
            buffer.limit(requiredBytes);
            return buffer;
        }
    }

    public void setVideoRgbaFrameOwned(ByteBuffer rgba, int width, int height, boolean mirrored) {
        setRgbaFrame(rgba, width, height, mirrored, false, false);
    }

    public void setProcessedRgbaFrame(ByteBuffer rgba, int width, int height, boolean mirrored) {
        setRgbaFrame(rgba, width, height, mirrored, true, true);
    }

    public void setProcessedYuv420Frame(Image image, int rotationDegrees, boolean mirrored) {
        if (image == null || image.getWidth() <= 0 || image.getHeight() <= 0) {
            return;
        }
        Image.Plane[] planes = image.getPlanes();
        if (planes == null || planes.length < 3) {
            return;
        }
        int width = image.getWidth();
        int height = image.getHeight();
        int chromaWidth = (width + 1) / 2;
        int chromaHeight = (height + 1) / 2;
        int yBytes = width * height;
        int uvBytes = chromaWidth * chromaHeight;
        int rotation = normalizeDegrees(rotationDegrees);
        boolean rotated = rotation == 90 || rotation == 270;
        int outputWidth = rotated ? height : width;
        int outputHeight = rotated ? width : height;

        final int generation;
        synchronized (imageLock) {
            ByteBuffer yUpload = takeBuffer(spareYuvYBuffer, yBytes);
            spareYuvYBuffer = null;
            ByteBuffer uUpload = takeBuffer(spareYuvUBuffer, uvBytes);
            spareYuvUBuffer = null;
            ByteBuffer vUpload = takeBuffer(spareYuvVBuffer, uvBytes);
            spareYuvVBuffer = null;

            if (!copyImagePlane(planes[0], width, height, yUpload) ||
                    !copyImagePlane(planes[1], chromaWidth, chromaHeight, uUpload) ||
                    !copyImagePlane(planes[2], chromaWidth, chromaHeight, vUpload)) {
                spareYuvYBuffer = yUpload;
                spareYuvUBuffer = uUpload;
                spareYuvVBuffer = vUpload;
                return;
            }

            imageMode = true;
            videoFrameMode = true;
            processedVideoFrameMode = true;
            processedYuvFrameMode = true;
            mirrorFrontCamera = mirrored;
            imageWidth = outputWidth;
            imageHeight = outputHeight;
            yuvSourceWidth = width;
            yuvSourceHeight = height;
            yuvRotationDegrees = rotation;
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = null;
            if (pendingYuvYBuffer != null) {
                spareYuvYBuffer = pendingYuvYBuffer;
            }
            if (pendingYuvUBuffer != null) {
                spareYuvUBuffer = pendingYuvUBuffer;
            }
            if (pendingYuvVBuffer != null) {
                spareYuvVBuffer = pendingYuvVBuffer;
            }
            pendingYuvYBuffer = yUpload;
            pendingYuvUBuffer = uUpload;
            pendingYuvVBuffer = vUpload;
            if (pendingImageUploadBitmap != null && !pendingImageUploadBitmap.isRecycled()) {
                pendingImageUploadBitmap.recycle();
            }
            pendingImageUploadBitmap = null;
            imageGeneration++;
            generation = imageGeneration;
        }
        stopImageRefresh();
        engine.setRenderLandmarkPredictionEnabled(false);
        queueEvent(new Runnable() {
            @Override
            public void run() {
                uploadPendingYuvFrame(generation);
            }
        });
    }

    private static ByteBuffer takeBuffer(ByteBuffer buffer, int requiredBytes) {
        ByteBuffer output = buffer != null && buffer.capacity() >= requiredBytes
                ? buffer
                : ByteBuffer.allocateDirect(requiredBytes);
        output.clear();
        output.limit(requiredBytes);
        return output;
    }

    private static boolean copyImagePlane(Image.Plane plane, int width, int height, ByteBuffer output) {
        if (plane == null || width <= 0 || height <= 0 || output == null || output.capacity() < width * height) {
            return false;
        }
        ByteBuffer input = plane.getBuffer();
        if (input == null) {
            return false;
        }
        ByteBuffer source = input.duplicate();
        int rowStride = plane.getRowStride();
        int pixelStride = plane.getPixelStride();
        if (rowStride <= 0 || pixelStride <= 0) {
            return false;
        }
        output.clear();
        output.limit(width * height);
        for (int row = 0; row < height; row++) {
            int rowStart = row * rowStride;
            int rowEnd = rowStart + (width - 1) * pixelStride + 1;
            if (rowEnd > source.capacity()) {
                return false;
            }
            if (pixelStride == 1) {
                source.limit(source.capacity());
                source.position(rowStart);
                source.limit(rowStart + width);
                output.put(source);
            } else {
                for (int col = 0; col < width; col++) {
                    output.put(source.get(rowStart + col * pixelStride));
                }
            }
        }
        output.flip();
        return true;
    }

    private void setRgbaFrame(ByteBuffer rgba, int width, int height, boolean mirrored, boolean processed, boolean copyFrame) {
        if (rgba == null || width <= 0 || height <= 0) {
            return;
        }
        int requiredBytes = width * height * 4;
        if (requiredBytes <= 0 || rgba.capacity() < requiredBytes) {
            return;
        }
        ByteBuffer source = null;
        if (copyFrame) {
            source = rgba.duplicate();
            source.position(0);
            source.limit(requiredBytes);
        } else {
            rgba.position(0);
            rgba.limit(requiredBytes);
        }

        final int generation;
        synchronized (imageLock) {
            ByteBuffer uploadBuffer = copyFrame ? pendingFrameUploadBuffer : rgba;
            if (copyFrame && (uploadBuffer == null || uploadBuffer.capacity() < requiredBytes)) {
                uploadBuffer = spareFrameUploadBuffer != null && spareFrameUploadBuffer.capacity() >= requiredBytes
                        ? spareFrameUploadBuffer
                        : ByteBuffer.allocateDirect(requiredBytes);
                spareFrameUploadBuffer = null;
            }
            if (copyFrame) {
                uploadBuffer.clear();
                uploadBuffer.limit(requiredBytes);
                uploadBuffer.put(source);
                uploadBuffer.flip();
            }
            if (!copyFrame && pendingFrameUploadBuffer != null && pendingFrameUploadBuffer != uploadBuffer) {
                if (spareFrameUploadBuffer == null || spareFrameUploadBuffer.capacity() < pendingFrameUploadBuffer.capacity()) {
                    spareFrameUploadBuffer = pendingFrameUploadBuffer;
                }
            }

            imageMode = true;
            videoFrameMode = true;
            processedVideoFrameMode = processed;
            processedYuvFrameMode = false;
            mirrorFrontCamera = mirrored;
            imageWidth = width;
            imageHeight = height;
            yuvSourceWidth = 0;
            yuvSourceHeight = 0;
            yuvRotationDegrees = 0;
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = uploadBuffer;
            pendingYuvYBuffer = null;
            pendingYuvUBuffer = null;
            pendingYuvVBuffer = null;
            if (pendingImageUploadBitmap != null && !pendingImageUploadBitmap.isRecycled()) {
                pendingImageUploadBitmap.recycle();
            }
            pendingImageUploadBitmap = null;
            imageGeneration++;
            generation = imageGeneration;
        }
        stopImageRefresh();
        engine.setRenderLandmarkPredictionEnabled(false);
        queueEvent(new Runnable() {
            @Override
            public void run() {
                uploadPendingRgbaFrame(generation);
            }
        });
    }

    public void clearImageBitmap() {
        synchronized (imageLock) {
            imageMode = false;
            videoFrameMode = false;
            processedVideoFrameMode = false;
            processedYuvFrameMode = false;
            imageWidth = 0;
            imageHeight = 0;
            yuvSourceWidth = 0;
            yuvSourceHeight = 0;
            yuvRotationDegrees = 0;
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = null;
            spareFrameUploadBuffer = null;
            pendingYuvYBuffer = null;
            pendingYuvUBuffer = null;
            pendingYuvVBuffer = null;
            spareYuvYBuffer = null;
            spareYuvUBuffer = null;
            spareYuvVBuffer = null;
            if (pendingImageUploadBitmap != null && !pendingImageUploadBitmap.isRecycled()) {
                pendingImageUploadBitmap.recycle();
            }
            pendingImageUploadBitmap = null;
            imageGeneration++;
        }
        stopImageRefresh();
        if (released) {
            return;
        }
        queueEvent(new Runnable() {
            @Override
            public void run() {
                deleteImageTexture();
                requestRender();
            }
        });
    }

    public void requestBeautyRender() {
        requestRender();
    }

    public void setGpuTextureProcessing(boolean enabled) {
        gpuTextureProcessing = enabled;
        if (enabled) {
            clearImageBitmap();
        }
        requestRender();
    }

    public Surface getCameraSurface() {
        return cameraSurface;
    }

    @Override
    public void onResume() {
        super.onResume();
        if (imageMode && !videoFrameMode) {
            startImageRefresh();
        }
    }

    @Override
    public void onPause() {
        stopImageRefresh();
        super.onPause();
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        surfaceReady = true;
        oesTextureId = createExternalTexture();
        cameraSurfaceTexture = new SurfaceTexture(oesTextureId);
        cameraSurfaceTexture.setOnFrameAvailableListener(this);
        cameraSurface = new Surface(cameraSurfaceTexture);
        applyCameraBufferSize();
        if (cameraSurfaceListener != null) {
            cameraSurfaceListener.onCameraSurfaceCreated(cameraSurface, cameraSurfaceTexture);
        }
        int generation = 0;
        boolean shouldUploadImage;
        synchronized (imageLock) {
            shouldUploadImage = imageMode;
            generation = imageGeneration;
        }
        if (shouldUploadImage) {
            uploadPendingImageTexture(generation);
        }
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        viewWidth = width;
        viewHeight = height;
        GLES20.glViewport(0, 0, width, height);
        engine.setViewport(width, height);
        applyCameraBufferSize();
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        GLES20.glClearColor(0f, 0f, 0f, 1f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        if (imageMode) {
            drainCameraTexture();
            renderImageFrame();
            return;
        }
        SurfaceTexture texture = cameraSurfaceTexture;
        if (texture == null || oesTextureId == 0) {
            return;
        }
        boolean updatedCameraTexture = false;
        if (frameAvailable.getAndSet(false)) {
            try {
                texture.updateTexImage();
                updatedCameraTexture = true;
            } catch (RuntimeException ignored) {
                return;
            }
        }
        texture.getTransformMatrix(transform);
        int bufferWidth = cameraBufferWidth > 0 ? cameraBufferWidth : viewWidth;
        int bufferHeight = cameraBufferHeight > 0 ? cameraBufferHeight : viewHeight;
        boolean rotated = cameraRotationDegrees == 90 || cameraRotationDegrees == 270;
        int sourceWidth = rotated ? bufferHeight : bufferWidth;
        int sourceHeight = rotated ? bufferWidth : bufferHeight;
        if (!gpuTextureProcessing) {
            return;
        }
        UyaliBeautyTextureInput input = UyaliBeautyTextureInput.externalOes(oesTextureId,
                transform,
                viewWidth,
                viewHeight,
                sourceWidth,
                sourceHeight,
                mirrorFrontCamera,
                texture.getTimestamp(),
                updatedCameraTexture);
        UyaliBeautyTextureFrame outputFrame = textureProcessor.process(input);
        if (outputFrame != null && outputFrame.isValid()) {
            drawTexture2dToViewport(outputFrame.textureId(),
                    UyaliBeautyTextureInput.IDENTITY_TRANSFORM,
                    viewWidth,
                    viewHeight,
                    outputFrame.width(),
                    outputFrame.height(),
                    true);
        }
    }

    private void drainCameraTexture() {
        SurfaceTexture texture = cameraSurfaceTexture;
        if (texture == null || oesTextureId == 0) {
            return;
        }
        if (frameAvailable.getAndSet(false)) {
            try {
                texture.updateTexImage();
            } catch (RuntimeException ignored) {
            }
        }
    }

    @Override
    public void onFrameAvailable(SurfaceTexture surfaceTexture) {
        frameAvailable.set(true);
        requestRender();
    }

    public void release() {
        released = true;
        stopImageRefresh();
        synchronized (imageLock) {
            imageMode = false;
            videoFrameMode = false;
            processedVideoFrameMode = false;
            processedYuvFrameMode = false;
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = null;
            spareFrameUploadBuffer = null;
            pendingYuvYBuffer = null;
            pendingYuvUBuffer = null;
            pendingYuvVBuffer = null;
            spareYuvYBuffer = null;
            spareYuvUBuffer = null;
            spareYuvVBuffer = null;
            if (pendingImageUploadBitmap != null && !pendingImageUploadBitmap.isRecycled()) {
                pendingImageUploadBitmap.recycle();
            }
            pendingImageUploadBitmap = null;
            imageGeneration++;
        }
        queueEvent(new Runnable() {
            @Override
            public void run() {
                if (cameraSurfaceListener != null) {
                    cameraSurfaceListener.onCameraSurfaceDestroyed();
                }
                if (cameraSurface != null) {
                    cameraSurface.release();
                    cameraSurface = null;
                }
                if (cameraSurfaceTexture != null) {
                    cameraSurfaceTexture.release();
                    cameraSurfaceTexture = null;
                }
                if (oesTextureId != 0) {
                    int[] textures = new int[]{oesTextureId};
                    GLES20.glDeleteTextures(1, textures, 0);
                    oesTextureId = 0;
                }
                deleteImageTexture();
                deleteYuvResources();
                deleteSyncCameraResources();
                textureProcessor.setAnalysisCompleteListener(null);
                textureProcessor.release();
            }
        });
    }

    private void renderImageFrame() {
        uploadPendingRgbaFrame(imageGeneration);
        uploadPendingYuvFrame(imageGeneration);
        boolean yuvMode;
        synchronized (imageLock) {
            yuvMode = processedYuvFrameMode;
        }
        if (!yuvMode && imageTextureId == 0) {
            uploadPendingImageTexture(imageGeneration);
        }
        int textureId = yuvMode ? yuvRgbTextureId : imageTextureId;
        int sourceWidth;
        int sourceHeight;
        synchronized (imageLock) {
            sourceWidth = imageWidth;
            sourceHeight = imageHeight;
        }
        if (textureId == 0 || sourceWidth <= 0 || sourceHeight <= 0) {
            return;
        }
        if (yuvMode) {
            engine.setRenderLandmarkPredictionEnabled(false);
            engine.renderTexture2dFitCenter(textureId,
                    BITMAP_TEXTURE_TRANSFORM,
                    viewWidth,
                    viewHeight,
                    sourceWidth,
                    sourceHeight,
                    mirrorFrontCamera);
            return;
        }
        if (processedVideoFrameMode) {
            drawTexture2dToViewport(textureId,
                    BITMAP_TEXTURE_TRANSFORM,
                    viewWidth,
                    viewHeight,
                    sourceWidth,
                    sourceHeight,
                    true);
            return;
        }
        engine.setRenderLandmarkPredictionEnabled(false);
        engine.renderTexture2dFitCenter(textureId, BITMAP_TEXTURE_TRANSFORM, viewWidth, viewHeight, sourceWidth, sourceHeight, mirrorFrontCamera);
    }

    private void uploadPendingYuvFrame(int generation) {
        ByteBuffer yBuffer;
        ByteBuffer uBuffer;
        ByteBuffer vBuffer;
        int sourceWidth;
        int sourceHeight;
        int outputWidth;
        int outputHeight;
        int rotation;
        synchronized (imageLock) {
            if (!surfaceReady || !imageMode || released || generation != imageGeneration ||
                    !processedYuvFrameMode ||
                    pendingYuvYBuffer == null || pendingYuvUBuffer == null || pendingYuvVBuffer == null) {
                return;
            }
            yBuffer = pendingYuvYBuffer;
            uBuffer = pendingYuvUBuffer;
            vBuffer = pendingYuvVBuffer;
            pendingYuvYBuffer = null;
            pendingYuvUBuffer = null;
            pendingYuvVBuffer = null;
            sourceWidth = yuvSourceWidth;
            sourceHeight = yuvSourceHeight;
            outputWidth = imageWidth;
            outputHeight = imageHeight;
            rotation = yuvRotationDegrees;
        }
        int chromaWidth = (sourceWidth + 1) / 2;
        int chromaHeight = (sourceHeight + 1) / 2;
        if (sourceWidth <= 0 || sourceHeight <= 0 || outputWidth <= 0 || outputHeight <= 0 ||
                !ensureYuvTextures() ||
                !uploadYuvPlane(0, yBuffer, sourceWidth, sourceHeight) ||
                !uploadYuvPlane(1, uBuffer, chromaWidth, chromaHeight) ||
                !uploadYuvPlane(2, vBuffer, chromaWidth, chromaHeight) ||
                !renderYuvToRgbTexture(outputWidth, outputHeight, rotation)) {
            synchronized (imageLock) {
                if (imageMode && !released && generation == imageGeneration && processedYuvFrameMode) {
                    if (pendingYuvYBuffer == null) {
                        pendingYuvYBuffer = yBuffer;
                    }
                    if (pendingYuvUBuffer == null) {
                        pendingYuvUBuffer = uBuffer;
                    }
                    if (pendingYuvVBuffer == null) {
                        pendingYuvVBuffer = vBuffer;
                    }
                }
            }
            return;
        }
        synchronized (imageLock) {
            if (spareYuvYBuffer == null || spareYuvYBuffer.capacity() < yBuffer.capacity()) {
                spareYuvYBuffer = yBuffer;
            }
            if (spareYuvUBuffer == null || spareYuvUBuffer.capacity() < uBuffer.capacity()) {
                spareYuvUBuffer = uBuffer;
            }
            if (spareYuvVBuffer == null || spareYuvVBuffer.capacity() < vBuffer.capacity()) {
                spareYuvVBuffer = vBuffer;
            }
        }
        requestRender();
    }

    private void uploadPendingRgbaFrame(int generation) {
        ByteBuffer frameBuffer;
        int width;
        int height;
        synchronized (imageLock) {
            if (!surfaceReady || !imageMode || released || generation != imageGeneration || pendingFrameUploadBuffer == null) {
                return;
            }
            frameBuffer = pendingFrameUploadBuffer;
            pendingFrameUploadBuffer = null;
            width = imageWidth;
            height = imageHeight;
        }
        if (imageTextureId == 0) {
            imageTextureId = createTexture2d();
        }
        if (imageTextureId == 0 || width <= 0 || height <= 0) {
            synchronized (imageLock) {
                if (imageMode && !released && generation == imageGeneration && pendingFrameUploadBuffer == null) {
                    pendingFrameUploadBuffer = frameBuffer;
                }
            }
            return;
        }
        uploadRgbaTexture2d(imageTextureId, frameBuffer, width, height);
        synchronized (imageLock) {
            if (spareFrameUploadBuffer == null || spareFrameUploadBuffer.capacity() < frameBuffer.capacity()) {
                spareFrameUploadBuffer = frameBuffer;
            }
        }
        requestRender();
    }

    private void uploadPendingImageTexture(int generation) {
        Bitmap uploadBitmap;
        synchronized (imageLock) {
            if (!surfaceReady || !imageMode || released || generation != imageGeneration || pendingImageUploadBitmap == null) {
                return;
            }
            uploadBitmap = pendingImageUploadBitmap;
            pendingImageUploadBitmap = null;
        }
        if (imageTextureId == 0) {
            imageTextureId = createTexture2d();
        }
        if (imageTextureId == 0) {
            synchronized (imageLock) {
                if (imageMode && !released && generation == imageGeneration && pendingImageUploadBitmap == null) {
                    pendingImageUploadBitmap = uploadBitmap;
                    return;
                }
            }
        } else {
            uploadTexture2d(imageTextureId, uploadBitmap);
            imageTextureWidth = uploadBitmap.getWidth();
            imageTextureHeight = uploadBitmap.getHeight();
        }
        if (!uploadBitmap.isRecycled()) {
            uploadBitmap.recycle();
        }
        requestRender();
    }

    private void analyzeStillImage(final ByteBuffer rgba, final int width, final int height, final int generation) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND);
                synchronized (imageLock) {
                    if (!imageMode || released || generation != imageGeneration || imageRgbaBuffer != rgba) {
                        return;
                    }
                }
                ByteBuffer analysisBuffer = rgba.duplicate();
                analysisBuffer.rewind();
                engine.analyzeStillImageRgba(analysisBuffer, width, height);
                synchronized (imageLock) {
                    if (!imageMode || released || generation != imageGeneration || imageRgbaBuffer != rgba) {
                        return;
                    }
                }
                requestRender();
                final StillImageAnalysisListener listener = stillImageAnalysisListener;
                if (listener != null) {
                    mainHandler.post(new Runnable() {
                        @Override
                        public void run() {
                            synchronized (imageLock) {
                                if (!imageMode || released || generation != imageGeneration || imageRgbaBuffer != rgba) {
                                    return;
                                }
                            }
                            listener.onStillImageAnalysisComplete();
                        }
                    });
                }
            }
        }, "UyaliBeautyImageAnalyze").start();
    }

    private void startImageRefresh() {
        mainHandler.removeCallbacks(imageRefreshTicker);
        mainHandler.post(imageRefreshTicker);
    }

    private void stopImageRefresh() {
        mainHandler.removeCallbacks(imageRefreshTicker);
    }

    private void copyCurrentCameraFrameToSyncTexture(long timestampNs,
                                                     float[] textureTransform,
                                                     int sourceWidth,
                                                     int sourceHeight) {
        if (timestampNs <= 0L || sourceWidth <= 0 || sourceHeight <= 0 || oesTextureId == 0) {
            return;
        }
        if (!ensureOesCopyResources()) {
            return;
        }
        SyncCameraFrame frame = syncCameraFrames[syncCameraFrameCursor];
        if (frame == null) {
            frame = new SyncCameraFrame();
            syncCameraFrames[syncCameraFrameCursor] = frame;
        }
        if (!ensureSyncFrameTexture(frame, sourceWidth, sourceHeight)) {
            return;
        }

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, oesCopyFramebuffer);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER,
                GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_TEXTURE_2D,
                frame.textureId,
                0);
        if (GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER) != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
            GLES20.glViewport(0, 0, viewWidth, viewHeight);
            return;
        }

        GLES20.glViewport(0, 0, sourceWidth, sourceHeight);
        GLES20.glUseProgram(oesCopyProgram);
        int positionLocation = GLES20.glGetAttribLocation(oesCopyProgram, "aPosition");
        int texCoordLocation = GLES20.glGetAttribLocation(oesCopyProgram, "aTexCoord");
        int transformLocation = GLES20.glGetUniformLocation(oesCopyProgram, "uTransform");
        int textureLocation = GLES20.glGetUniformLocation(oesCopyProgram, "uTexture");

        fullscreenQuadBuffer.position(0);
        GLES20.glEnableVertexAttribArray(positionLocation);
        GLES20.glVertexAttribPointer(positionLocation, 2, GLES20.GL_FLOAT, false, 16, fullscreenQuadBuffer);
        fullscreenQuadBuffer.position(2);
        GLES20.glEnableVertexAttribArray(texCoordLocation);
        GLES20.glVertexAttribPointer(texCoordLocation, 2, GLES20.GL_FLOAT, false, 16, fullscreenQuadBuffer);
        GLES20.glUniformMatrix4fv(transformLocation, 1, false, textureTransform, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTextureId);
        GLES20.glUniform1i(textureLocation, 0);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(positionLocation);
        GLES20.glDisableVertexAttribArray(texCoordLocation);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glViewport(0, 0, viewWidth, viewHeight);
        fullscreenQuadBuffer.position(0);

        frame.timestampNs = timestampNs;
        frame.width = sourceWidth;
        frame.height = sourceHeight;
        frame.valid = true;
        syncCameraFrameCursor = (syncCameraFrameCursor + 1) % syncCameraFrames.length;
        if (pendingAnalyzedTimestampNs != Long.MIN_VALUE) {
            selectSynchronizedCameraFrame(pendingAnalyzedTimestampNs);
        }
    }

    private boolean selectSynchronizedCameraFrame(long timestampNs) {
        int bestIndex = -1;
        long bestDelta = Long.MAX_VALUE;
        for (int i = 0; i < syncCameraFrames.length; i++) {
            SyncCameraFrame frame = syncCameraFrames[i];
            if (frame == null || !frame.valid || frame.textureId == 0 || frame.timestampNs <= 0L) {
                continue;
            }
            long delta = Math.abs(frame.timestampNs - timestampNs);
            if (delta < bestDelta) {
                bestDelta = delta;
                bestIndex = i;
            }
        }
        if (bestIndex >= 0 && bestDelta <= SYNC_FRAME_MATCH_TOLERANCE_NS) {
            syncCameraDisplayIndex = bestIndex;
            pendingAnalyzedTimestampNs = Long.MIN_VALUE;
            return true;
        }
        return false;
    }

    private boolean isFreshSynchronizedFrame(SyncCameraFrame frame, long cameraTimestampNs) {
        if (frame == null || !frame.valid || frame.textureId == 0 || frame.timestampNs <= 0L) {
            return false;
        }
        if (cameraTimestampNs <= 0L) {
            return true;
        }
        long stalenessNs = cameraTimestampNs - frame.timestampNs;
        return stalenessNs <= syncCameraFrameMaxStalenessNs;
    }

    private boolean ensureOesCopyResources() {
        if (oesCopyProgram == 0) {
            oesCopyProgram = linkProgram(OES_COPY_VERTEX_SHADER, OES_COPY_FRAGMENT_SHADER);
        }
        if (oesCopyProgram == 0) {
            return false;
        }
        if (oesCopyFramebuffer == 0) {
            int[] framebuffers = new int[1];
            GLES20.glGenFramebuffers(1, framebuffers, 0);
            oesCopyFramebuffer = framebuffers[0];
        }
        return oesCopyFramebuffer != 0;
    }

    private boolean ensureTextureCopyProgram() {
        if (textureCopyProgram == 0) {
            textureCopyProgram = linkProgram(OES_COPY_VERTEX_SHADER, TEXTURE_2D_COPY_FRAGMENT_SHADER);
        }
        return textureCopyProgram != 0;
    }

    private boolean ensureYuvToRgbProgram() {
        if (yuvToRgbProgram == 0) {
            yuvToRgbProgram = linkProgram(OES_COPY_VERTEX_SHADER, YUV_TO_RGB_FRAGMENT_SHADER);
        }
        return yuvToRgbProgram != 0;
    }

    private boolean ensureYuvTextures() {
        if (yuvYTextureId == 0) {
            yuvYTextureId = createTexture2d();
        }
        if (yuvUTextureId == 0) {
            yuvUTextureId = createTexture2d();
        }
        if (yuvVTextureId == 0) {
            yuvVTextureId = createTexture2d();
        }
        return yuvYTextureId != 0 && yuvUTextureId != 0 && yuvVTextureId != 0;
    }

    private boolean uploadYuvPlane(int plane, ByteBuffer buffer, int width, int height) {
        int textureId;
        int currentWidth;
        int currentHeight;
        if (plane == 0) {
            textureId = yuvYTextureId;
            currentWidth = yuvYTextureWidth;
            currentHeight = yuvYTextureHeight;
        } else if (plane == 1) {
            textureId = yuvUTextureId;
            currentWidth = yuvUTextureWidth;
            currentHeight = yuvUTextureHeight;
        } else {
            textureId = yuvVTextureId;
            currentWidth = yuvVTextureWidth;
            currentHeight = yuvVTextureHeight;
        }
        if (textureId == 0 || buffer == null || width <= 0 || height <= 0 || buffer.capacity() < width * height) {
            return false;
        }
        buffer.position(0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);
        if (currentWidth != width || currentHeight != height) {
            GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D,
                    0,
                    GLES20.GL_LUMINANCE,
                    width,
                    height,
                    0,
                    GLES20.GL_LUMINANCE,
                    GLES20.GL_UNSIGNED_BYTE,
                    buffer);
            if (plane == 0) {
                yuvYTextureWidth = width;
                yuvYTextureHeight = height;
            } else if (plane == 1) {
                yuvUTextureWidth = width;
                yuvUTextureHeight = height;
            } else {
                yuvVTextureWidth = width;
                yuvVTextureHeight = height;
            }
        } else {
            GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D,
                    0,
                    0,
                    0,
                    width,
                    height,
                    GLES20.GL_LUMINANCE,
                    GLES20.GL_UNSIGNED_BYTE,
                    buffer);
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        return true;
    }

    private boolean ensureYuvRgbTarget(int width, int height) {
        if (width <= 0 || height <= 0) {
            return false;
        }
        if (yuvRgbTextureId == 0) {
            yuvRgbTextureId = createTexture2d();
        }
        if (yuvFramebuffer == 0) {
            int[] framebuffers = new int[1];
            GLES20.glGenFramebuffers(1, framebuffers, 0);
            yuvFramebuffer = framebuffers[0];
        }
        if (yuvRgbTextureId == 0 || yuvFramebuffer == 0) {
            return false;
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, yuvRgbTextureId);
        if (yuvRgbTextureWidth != width || yuvRgbTextureHeight != height) {
            GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D,
                    0,
                    GLES20.GL_RGBA,
                    width,
                    height,
                    0,
                    GLES20.GL_RGBA,
                    GLES20.GL_UNSIGNED_BYTE,
                    null);
            yuvRgbTextureWidth = width;
            yuvRgbTextureHeight = height;
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        return true;
    }

    private boolean renderYuvToRgbTexture(int width, int height, int rotationDegrees) {
        if (!ensureYuvToRgbProgram() || !ensureYuvRgbTarget(width, height)) {
            return false;
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, yuvFramebuffer);
        GLES20.glFramebufferTexture2D(GLES20.GL_FRAMEBUFFER,
                GLES20.GL_COLOR_ATTACHMENT0,
                GLES20.GL_TEXTURE_2D,
                yuvRgbTextureId,
                0);
        if (GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER) != GLES20.GL_FRAMEBUFFER_COMPLETE) {
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
            GLES20.glViewport(0, 0, viewWidth, viewHeight);
            return false;
        }

        GLES20.glViewport(0, 0, width, height);
        GLES20.glUseProgram(yuvToRgbProgram);
        int positionLocation = GLES20.glGetAttribLocation(yuvToRgbProgram, "aPosition");
        int texCoordLocation = GLES20.glGetAttribLocation(yuvToRgbProgram, "aTexCoord");
        int transformLocation = GLES20.glGetUniformLocation(yuvToRgbProgram, "uTransform");
        int rotationLocation = GLES20.glGetUniformLocation(yuvToRgbProgram, "uRotation");
        int yLocation = GLES20.glGetUniformLocation(yuvToRgbProgram, "uYTexture");
        int uLocation = GLES20.glGetUniformLocation(yuvToRgbProgram, "uUTexture");
        int vLocation = GLES20.glGetUniformLocation(yuvToRgbProgram, "uVTexture");

        fullscreenQuadBuffer.position(0);
        GLES20.glEnableVertexAttribArray(positionLocation);
        GLES20.glVertexAttribPointer(positionLocation, 2, GLES20.GL_FLOAT, false, 16, fullscreenQuadBuffer);
        fullscreenQuadBuffer.position(2);
        GLES20.glEnableVertexAttribArray(texCoordLocation);
        GLES20.glVertexAttribPointer(texCoordLocation, 2, GLES20.GL_FLOAT, false, 16, fullscreenQuadBuffer);
        GLES20.glUniformMatrix4fv(transformLocation, 1, false, IDENTITY_TEXTURE_TRANSFORM, 0);
        GLES20.glUniform1i(rotationLocation, normalizeDegrees(rotationDegrees));
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, yuvYTextureId);
        GLES20.glUniform1i(yLocation, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, yuvUTextureId);
        GLES20.glUniform1i(uLocation, 1);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, yuvVTextureId);
        GLES20.glUniform1i(vLocation, 2);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);

        GLES20.glDisableVertexAttribArray(positionLocation);
        GLES20.glDisableVertexAttribArray(texCoordLocation);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE2);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE1);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glUseProgram(0);
        GLES20.glViewport(0, 0, viewWidth, viewHeight);
        fullscreenQuadBuffer.position(0);
        return true;
    }

    private void drawTexture2dToViewport(int textureId,
                                         float[] textureTransform,
                                         int viewportWidth,
                                         int viewportHeight,
                                         int sourceWidth,
                                         int sourceHeight,
                                         boolean fitCenter) {
        if (textureId == 0 || viewportWidth <= 0 || viewportHeight <= 0 || !ensureTextureCopyProgram()) {
            return;
        }
        int drawX = 0;
        int drawY = 0;
        int drawWidth = viewportWidth;
        int drawHeight = viewportHeight;
        if (fitCenter && sourceWidth > 0 && sourceHeight > 0) {
            float scale = Math.min(viewportWidth / (float) sourceWidth, viewportHeight / (float) sourceHeight);
            drawWidth = Math.max(1, Math.round(sourceWidth * scale));
            drawHeight = Math.max(1, Math.round(sourceHeight * scale));
            drawX = (viewportWidth - drawWidth) / 2;
            drawY = (viewportHeight - drawHeight) / 2;
        }
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
        GLES20.glViewport(drawX, drawY, drawWidth, drawHeight);
        GLES20.glUseProgram(textureCopyProgram);
        int positionLocation = GLES20.glGetAttribLocation(textureCopyProgram, "aPosition");
        int texCoordLocation = GLES20.glGetAttribLocation(textureCopyProgram, "aTexCoord");
        int transformLocation = GLES20.glGetUniformLocation(textureCopyProgram, "uTransform");
        int textureLocation = GLES20.glGetUniformLocation(textureCopyProgram, "uTexture");

        fullscreenQuadBuffer.position(0);
        GLES20.glEnableVertexAttribArray(positionLocation);
        GLES20.glVertexAttribPointer(positionLocation, 2, GLES20.GL_FLOAT, false, 16, fullscreenQuadBuffer);
        fullscreenQuadBuffer.position(2);
        GLES20.glEnableVertexAttribArray(texCoordLocation);
        GLES20.glVertexAttribPointer(texCoordLocation, 2, GLES20.GL_FLOAT, false, 16, fullscreenQuadBuffer);
        GLES20.glUniformMatrix4fv(transformLocation, 1, false,
                textureTransform == null ? UyaliBeautyTextureInput.IDENTITY_TRANSFORM : textureTransform,
                0);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        GLES20.glUniform1i(textureLocation, 0);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glDisableVertexAttribArray(positionLocation);
        GLES20.glDisableVertexAttribArray(texCoordLocation);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        GLES20.glUseProgram(0);
        GLES20.glViewport(0, 0, viewportWidth, viewportHeight);
        fullscreenQuadBuffer.position(0);
    }

    private boolean ensureSyncFrameTexture(SyncCameraFrame frame, int width, int height) {
        if (frame.textureId == 0) {
            frame.textureId = createTexture2d();
        }
        if (frame.textureId == 0) {
            return false;
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, frame.textureId);
        if (frame.width != width || frame.height != height) {
            GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D,
                    0,
                    GLES20.GL_RGBA,
                    width,
                    height,
                    0,
                    GLES20.GL_RGBA,
                    GLES20.GL_UNSIGNED_BYTE,
                    null);
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        return true;
    }

    private void deleteSyncCameraResources() {
        for (SyncCameraFrame frame : syncCameraFrames) {
            if (frame != null && frame.textureId != 0) {
                int[] textures = new int[]{frame.textureId};
                GLES20.glDeleteTextures(1, textures, 0);
                frame.textureId = 0;
                frame.valid = false;
            }
        }
        if (oesCopyFramebuffer != 0) {
            int[] framebuffers = new int[]{oesCopyFramebuffer};
            GLES20.glDeleteFramebuffers(1, framebuffers, 0);
            oesCopyFramebuffer = 0;
        }
        if (oesCopyProgram != 0) {
            GLES20.glDeleteProgram(oesCopyProgram);
            oesCopyProgram = 0;
        }
        if (textureCopyProgram != 0) {
            GLES20.glDeleteProgram(textureCopyProgram);
            textureCopyProgram = 0;
        }
        syncCameraDisplayIndex = -1;
        pendingAnalyzedTimestampNs = Long.MIN_VALUE;
    }

    private void deleteYuvResources() {
        int[] textures = new int[4];
        int count = 0;
        if (yuvRgbTextureId != 0) {
            textures[count++] = yuvRgbTextureId;
            yuvRgbTextureId = 0;
        }
        if (yuvYTextureId != 0) {
            textures[count++] = yuvYTextureId;
            yuvYTextureId = 0;
        }
        if (yuvUTextureId != 0) {
            textures[count++] = yuvUTextureId;
            yuvUTextureId = 0;
        }
        if (yuvVTextureId != 0) {
            textures[count++] = yuvVTextureId;
            yuvVTextureId = 0;
        }
        if (count > 0) {
            GLES20.glDeleteTextures(count, textures, 0);
        }
        if (yuvFramebuffer != 0) {
            int[] framebuffers = new int[]{yuvFramebuffer};
            GLES20.glDeleteFramebuffers(1, framebuffers, 0);
            yuvFramebuffer = 0;
        }
        if (yuvToRgbProgram != 0) {
            GLES20.glDeleteProgram(yuvToRgbProgram);
            yuvToRgbProgram = 0;
        }
        yuvRgbTextureWidth = 0;
        yuvRgbTextureHeight = 0;
        yuvYTextureWidth = 0;
        yuvYTextureHeight = 0;
        yuvUTextureWidth = 0;
        yuvUTextureHeight = 0;
        yuvVTextureWidth = 0;
        yuvVTextureHeight = 0;
    }

    private static int compileShader(int type, String source) {
        int shader = GLES20.glCreateShader(type);
        if (shader == 0) {
            return 0;
        }
        GLES20.glShaderSource(shader, source);
        GLES20.glCompileShader(shader);
        int[] compiled = new int[1];
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0);
        if (compiled[0] == 0) {
            GLES20.glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    private static int linkProgram(String vertexSource, String fragmentSource) {
        int vertexShader = compileShader(GLES20.GL_VERTEX_SHADER, vertexSource);
        int fragmentShader = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource);
        if (vertexShader == 0 || fragmentShader == 0) {
            if (vertexShader != 0) {
                GLES20.glDeleteShader(vertexShader);
            }
            if (fragmentShader != 0) {
                GLES20.glDeleteShader(fragmentShader);
            }
            return 0;
        }
        int program = GLES20.glCreateProgram();
        if (program == 0) {
            GLES20.glDeleteShader(vertexShader);
            GLES20.glDeleteShader(fragmentShader);
            return 0;
        }
        GLES20.glAttachShader(program, vertexShader);
        GLES20.glAttachShader(program, fragmentShader);
        GLES20.glLinkProgram(program);
        int[] linked = new int[1];
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linked, 0);
        GLES20.glDeleteShader(vertexShader);
        GLES20.glDeleteShader(fragmentShader);
        if (linked[0] == 0) {
            GLES20.glDeleteProgram(program);
            return 0;
        }
        return program;
    }

    private static int createExternalTexture() {
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textures[0]);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0);
        return textures[0];
    }

    private static int createTexture2d() {
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textures[0]);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T, GLES20.GL_CLAMP_TO_EDGE);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
        return textures[0];
    }

    private static void uploadTexture2d(int textureId, Bitmap bitmap) {
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);
        GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
    }

    private void uploadRgbaTexture2d(int textureId, ByteBuffer rgba, int width, int height) {
        rgba.position(0);
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId);
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1);
        if (imageTextureWidth != width || imageTextureHeight != height) {
            GLES20.glTexImage2D(GLES20.GL_TEXTURE_2D,
                    0,
                    GLES20.GL_RGBA,
                    width,
                    height,
                    0,
                    GLES20.GL_RGBA,
                    GLES20.GL_UNSIGNED_BYTE,
                    rgba);
            imageTextureWidth = width;
            imageTextureHeight = height;
        } else {
            GLES20.glTexSubImage2D(GLES20.GL_TEXTURE_2D,
                    0,
                    0,
                    0,
                    width,
                    height,
                    GLES20.GL_RGBA,
                    GLES20.GL_UNSIGNED_BYTE,
                    rgba);
        }
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0);
    }

    private void deleteImageTexture() {
        if (imageTextureId != 0) {
            int[] textures = new int[]{imageTextureId};
            GLES20.glDeleteTextures(1, textures, 0);
            imageTextureId = 0;
        }
        imageTextureWidth = 0;
        imageTextureHeight = 0;
    }

    private static int normalizeDegrees(int degrees) {
        int value = degrees % 360;
        return value < 0 ? value + 360 : value;
    }

    private void applyCameraBufferSize() {
        if (cameraSurfaceTexture == null) {
            return;
        }
        int width = cameraBufferWidth > 0 ? cameraBufferWidth : viewWidth;
        int height = cameraBufferHeight > 0 ? cameraBufferHeight : viewHeight;
        if (width > 0 && height > 0) {
            cameraSurfaceTexture.setDefaultBufferSize(width, height);
        }
    }

    private static final class SyncCameraFrame {
        int textureId;
        int width;
        int height;
        long timestampNs;
        boolean valid;
    }
}
