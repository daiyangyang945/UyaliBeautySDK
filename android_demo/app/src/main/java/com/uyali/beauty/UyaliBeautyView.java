package com.uyali.beauty;

import android.content.Context;
import android.graphics.Bitmap;
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
    private Bitmap pendingImageUploadBitmap;
    private volatile boolean synchronizedCameraMode;
    private final SyncCameraFrame[] syncCameraFrames = new SyncCameraFrame[SYNC_CAMERA_FRAME_POOL_SIZE];
    private int syncCameraFrameCursor;
    private int syncCameraDisplayIndex = -1;
    private long pendingAnalyzedTimestampNs = Long.MIN_VALUE;
    private volatile long syncCameraFrameMaxStalenessNs = SYNC_FRAME_NO_STALENESS_LIMIT_NS;
    private int oesCopyProgram;
    private int textureCopyProgram;
    private int oesCopyFramebuffer;

    public UyaliBeautyView(Context context) {
        this(context, null);
    }

    public UyaliBeautyView(Context context, AttributeSet attrs) {
        super(context, attrs);
        textureProcessor = new UyaliBeautyTextureProcessor(context);
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
        setRgbaFrame(rgba, width, height, mirrored, false);
    }

    public void setProcessedRgbaFrame(ByteBuffer rgba, int width, int height, boolean mirrored) {
        setRgbaFrame(rgba, width, height, mirrored, true);
    }

    private void setRgbaFrame(ByteBuffer rgba, int width, int height, boolean mirrored, boolean processed) {
        if (rgba == null || width <= 0 || height <= 0) {
            return;
        }
        int requiredBytes = width * height * 4;
        if (requiredBytes <= 0 || rgba.capacity() < requiredBytes) {
            return;
        }
        ByteBuffer source = rgba.duplicate();
        source.position(0);
        source.limit(requiredBytes);

        final int generation;
        synchronized (imageLock) {
            ByteBuffer uploadBuffer = pendingFrameUploadBuffer;
            if (uploadBuffer == null || uploadBuffer.capacity() < requiredBytes) {
                uploadBuffer = spareFrameUploadBuffer != null && spareFrameUploadBuffer.capacity() >= requiredBytes
                        ? spareFrameUploadBuffer
                        : ByteBuffer.allocateDirect(requiredBytes);
                spareFrameUploadBuffer = null;
            }
            uploadBuffer.clear();
            uploadBuffer.limit(requiredBytes);
            uploadBuffer.put(source);
            uploadBuffer.flip();

            imageMode = true;
            videoFrameMode = true;
            processedVideoFrameMode = processed;
            mirrorFrontCamera = mirrored;
            imageWidth = width;
            imageHeight = height;
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = uploadBuffer;
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
            imageWidth = 0;
            imageHeight = 0;
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = null;
            spareFrameUploadBuffer = null;
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
        UyaliBeautyTextureFrame outputFrame = textureProcessor.process(
                UyaliBeautyTextureInput.externalOes(oesTextureId,
                        transform,
                        viewWidth,
                        viewHeight,
                        sourceWidth,
                        sourceHeight,
                        mirrorFrontCamera,
                        texture.getTimestamp(),
                        updatedCameraTexture));
        if (outputFrame != null && outputFrame.isValid()) {
            drawTexture2dToViewport(outputFrame.textureId(),
                    UyaliBeautyTextureInput.IDENTITY_TRANSFORM,
                    viewWidth,
                    viewHeight,
                    outputFrame.width(),
                    outputFrame.height(),
                    false);
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
            imageRgbaBuffer = null;
            pendingFrameUploadBuffer = null;
            spareFrameUploadBuffer = null;
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
                deleteSyncCameraResources();
                textureProcessor.release();
            }
        });
    }

    private void renderImageFrame() {
        uploadPendingRgbaFrame(imageGeneration);
        if (imageTextureId == 0) {
            uploadPendingImageTexture(imageGeneration);
        }
        int textureId = imageTextureId;
        int sourceWidth;
        int sourceHeight;
        synchronized (imageLock) {
            sourceWidth = imageWidth;
            sourceHeight = imageHeight;
        }
        if (textureId == 0 || sourceWidth <= 0 || sourceHeight <= 0) {
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
