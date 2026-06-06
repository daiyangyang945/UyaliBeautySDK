package com.uyali.beauty.demo;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.SurfaceTexture;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Process;
import android.util.Range;
import android.util.Size;
import android.view.Surface;
import android.view.WindowManager;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

final class Camera2Controller {
    interface Listener {
        void onCameraError(String message);
        void onCameraFacingChanged(boolean front);
        void onCameraPreviewSizeSelected(int width, int height, int rotationDegrees);
        boolean needsAnalysisStream();
        boolean canAcceptAnalysisFrame();
        void onAnalysisImage(Image image, int rotationDegrees);
    }

    private static final long ANALYSIS_INTERVAL_NS = 12_000_000L;
    // The YUV stream is analysis-only; preview/effects render from the camera OES texture.
    private static final int ANALYSIS_MAX_EDGE = 640;

    private final Context context;
    private final Listener listener;
    private HandlerThread cameraThread;
    private Handler cameraHandler;
    private HandlerThread analysisThread;
    private Handler analysisHandler;
    private CameraDevice cameraDevice;
    private CameraCaptureSession captureSession;
    private ImageReader analysisReader;
    private CameraCharacteristics cameraCharacteristics;
    private Surface previewSurface;
    private SurfaceTexture previewSurfaceTexture;
    private boolean useFrontCamera = true;
    private volatile boolean openingCamera;
    private Size previewSize;
    private Size analysisSize;
    private int analysisRotationDegrees;
    private long lastAnalysisNs;
    private final AtomicBoolean analysisInFlight = new AtomicBoolean(false);

    Camera2Controller(Context context, Listener listener) {
        this.context = context.getApplicationContext();
        this.listener = listener;
    }

    void setPreviewSurface(Surface surface, SurfaceTexture surfaceTexture) {
        previewSurface = surface;
        previewSurfaceTexture = surfaceTexture;
        if (surface != null) {
            start();
        } else {
            stop();
        }
    }

    void switchCamera() {
        useFrontCamera = !useFrontCamera;
        stop();
        start();
    }

    boolean isFrontCamera() {
        return useFrontCamera;
    }

    @SuppressLint("MissingPermission")
    void start() {
        if (previewSurface == null || cameraDevice != null || openingCamera) {
            return;
        }
        if (context.checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        ensureThread();
        try {
            CameraManager manager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
            String cameraId = findCamera(manager, useFrontCamera);
            if (cameraId == null) {
                notifyError("No usable camera found");
                return;
            }
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);
            cameraCharacteristics = characteristics;
            previewSize = choosePreviewSize(characteristics);
            if (previewSurfaceTexture != null && previewSize != null) {
                previewSurfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
            }
            analysisRotationDegrees = computeAnalysisRotation(characteristics, useFrontCamera);
            if (listener != null && previewSize != null) {
                listener.onCameraPreviewSizeSelected(previewSize.getWidth(), previewSize.getHeight(), analysisRotationDegrees);
            }
            analysisSize = chooseAnalysisSize(characteristics, previewSize);
            openingCamera = true;
            manager.openCamera(cameraId, new CameraDevice.StateCallback() {
                @Override
                public void onOpened(CameraDevice camera) {
                    openingCamera = false;
                    if (previewSurface == null) {
                        camera.close();
                        return;
                    }
                    cameraDevice = camera;
                    createSession();
                    if (listener != null) {
                        listener.onCameraFacingChanged(useFrontCamera);
                    }
                }

                @Override
                public void onDisconnected(CameraDevice camera) {
                    openingCamera = false;
                    camera.close();
                    cameraDevice = null;
                }

                @Override
                public void onError(CameraDevice camera, int error) {
                    openingCamera = false;
                    camera.close();
                    cameraDevice = null;
                    notifyError("Camera error: " + error);
                }
            }, cameraHandler);
        } catch (Exception error) {
            openingCamera = false;
            notifyError(error.getMessage());
        }
    }

    void stop() {
        openingCamera = false;
        try {
            if (captureSession != null) {
                captureSession.stopRepeating();
                captureSession.close();
                captureSession = null;
            }
        } catch (Exception ignored) {
            captureSession = null;
        }
        if (cameraDevice != null) {
            cameraDevice.close();
            cameraDevice = null;
        }
        cameraCharacteristics = null;
        closeAnalysisReader();
        lastAnalysisNs = 0L;
        analysisInFlight.set(false);
    }

    void release() {
        stop();
        if (analysisThread != null) {
            analysisThread.quitSafely();
            try {
                analysisThread.join(800);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }
            analysisThread = null;
            analysisHandler = null;
        }
        if (cameraThread != null) {
            cameraThread.quitSafely();
            try {
                cameraThread.join(800);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
            }
            cameraThread = null;
            cameraHandler = null;
        }
    }

    private void ensureThread() {
        if (cameraThread != null) {
            return;
        }
        cameraThread = new HandlerThread("UyaliBeautyCamera", Process.THREAD_PRIORITY_DISPLAY);
        cameraThread.start();
        cameraHandler = new Handler(cameraThread.getLooper());
        analysisThread = new HandlerThread("UyaliBeautyAnalysis", Process.THREAD_PRIORITY_DISPLAY);
        analysisThread.start();
        analysisHandler = new Handler(analysisThread.getLooper());
    }

    private String findCamera(CameraManager manager, boolean front) throws Exception {
        int desired = front ? CameraCharacteristics.LENS_FACING_FRONT : CameraCharacteristics.LENS_FACING_BACK;
        for (String id : manager.getCameraIdList()) {
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(id);
            Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
            if (facing != null && facing == desired) {
                return id;
            }
        }
        String[] ids = manager.getCameraIdList();
        return ids.length == 0 ? null : ids[0];
    }

    private void createSession() {
        if (cameraDevice == null || previewSurface == null) {
            return;
        }
        try {
            closeAnalysisReader();
            List<Surface> surfaces = new ArrayList<>();
            if (previewSurface != null) {
                surfaces.add(previewSurface);
            }
            if (analysisSize != null && listener != null && listener.needsAnalysisStream()) {
                analysisReader = ImageReader.newInstance(
                        analysisSize.getWidth(),
                        analysisSize.getHeight(),
                        ImageFormat.YUV_420_888,
                        2);
                analysisReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
                    @Override
                    public void onImageAvailable(ImageReader reader) {
                        handleAnalysisImage(reader);
                    }
                }, analysisHandler);
                surfaces.add(analysisReader.getSurface());
            }
            if (surfaces.isEmpty()) {
                notifyError("Camera session has no output surface");
                return;
            }

            cameraDevice.createCaptureSession(surfaces,
                    new CameraCaptureSession.StateCallback() {
                        @Override
                        public void onConfigured(CameraCaptureSession session) {
                            captureSession = session;
                            try {
                                CaptureRequest.Builder builder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
                                if (previewSurface != null) {
                                    builder.addTarget(previewSurface);
                                }
                                if (analysisReader != null) {
                                    builder.addTarget(analysisReader.getSurface());
                                }
                                configureLowLatencyRequest(builder);
                                session.setRepeatingRequest(builder.build(), null, cameraHandler);
                            } catch (Exception error) {
                                notifyError(error.getMessage());
                            }
                        }

                        @Override
                        public void onConfigureFailed(CameraCaptureSession session) {
                            notifyError("Camera session configure failed");
                        }
                    },
                    cameraHandler);
        } catch (Exception error) {
            notifyError(error.getMessage());
        }
    }

    private void notifyError(String message) {
        if (listener != null) {
            listener.onCameraError(message == null ? "unknown" : message);
        }
    }

    private void configureLowLatencyRequest(CaptureRequest.Builder builder) {
        builder.set(CaptureRequest.CONTROL_MODE, CaptureRequest.CONTROL_MODE_AUTO);
        builder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO);
        Range<Integer> fpsRange = choosePreviewFpsRange(cameraCharacteristics);
        if (fpsRange != null) {
            builder.set(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, fpsRange);
        }
        setRequestModeIfSupported(builder,
                CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE,
                CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES,
                CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE_OFF);
        setRequestModeIfSupported(builder,
                CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE,
                CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION,
                CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE_OFF);
        setRequestModeIfSupported(builder,
                CaptureRequest.EDGE_MODE,
                CameraCharacteristics.EDGE_AVAILABLE_EDGE_MODES,
                CaptureRequest.EDGE_MODE_FAST);
        setRequestModeIfSupported(builder,
                CaptureRequest.NOISE_REDUCTION_MODE,
                CameraCharacteristics.NOISE_REDUCTION_AVAILABLE_NOISE_REDUCTION_MODES,
                CaptureRequest.NOISE_REDUCTION_MODE_FAST);
        setRequestModeIfSupported(builder,
                CaptureRequest.COLOR_CORRECTION_ABERRATION_MODE,
                CameraCharacteristics.COLOR_CORRECTION_AVAILABLE_ABERRATION_MODES,
                CaptureRequest.COLOR_CORRECTION_ABERRATION_MODE_FAST);
    }

    private Range<Integer> choosePreviewFpsRange(CameraCharacteristics characteristics) {
        Range<Integer>[] ranges = characteristics == null
                ? null
                : characteristics.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES);
        if (ranges == null || ranges.length == 0) {
            return null;
        }
        Range<Integer> best = null;
        for (Range<Integer> range : ranges) {
            if (range == null || range.getUpper() == null || range.getLower() == null || range.getUpper() < 24) {
                continue;
            }
            if (best == null ||
                    range.getLower() > best.getLower() ||
                    (range.getLower().equals(best.getLower()) && range.getUpper() > best.getUpper())) {
                best = range;
            }
        }
        return best;
    }

    private void setRequestModeIfSupported(CaptureRequest.Builder builder,
                                           CaptureRequest.Key<Integer> requestKey,
                                           CameraCharacteristics.Key<int[]> characteristicsKey,
                                           int mode) {
        int[] modes = cameraCharacteristics == null ? null : cameraCharacteristics.get(characteristicsKey);
        if (modes == null) {
            return;
        }
        for (int supportedMode : modes) {
            if (supportedMode == mode) {
                builder.set(requestKey, mode);
                return;
            }
        }
    }

    private void closeAnalysisReader() {
        if (analysisReader != null) {
            analysisReader.close();
            analysisReader = null;
        }
    }

    private Size chooseAnalysisSize(CameraCharacteristics characteristics, Size targetPreviewSize) {
        StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
        Size[] sizes = map == null ? null : map.getOutputSizes(ImageFormat.YUV_420_888);
        if (sizes == null || sizes.length == 0) {
            return new Size(640, 480);
        }
        Size bestUnderMax = null;
        double bestUnderMaxScore = Double.MAX_VALUE;
        Size bestOverMax = null;
        double bestOverMaxScore = Double.MAX_VALUE;
        double targetAspect = targetPreviewSize == null || targetPreviewSize.getHeight() <= 0
                ? 4.0 / 3.0
                : (double) targetPreviewSize.getWidth() / (double) targetPreviewSize.getHeight();
        for (Size size : sizes) {
            int longEdge = Math.max(size.getWidth(), size.getHeight());
            double aspect = size.getHeight() <= 0 ? targetAspect : (double) size.getWidth() / (double) size.getHeight();
            double aspectPenalty = Math.abs(aspect - targetAspect) * 10.0;
            if (longEdge <= ANALYSIS_MAX_EDGE) {
                double score = aspectPenalty + (ANALYSIS_MAX_EDGE - longEdge) / (double) ANALYSIS_MAX_EDGE * 0.20;
                if (bestUnderMax == null ||
                        score < bestUnderMaxScore ||
                        (Math.abs(score - bestUnderMaxScore) < 0.0001 && pixels(size) > pixels(bestUnderMax))) {
                    bestUnderMax = size;
                    bestUnderMaxScore = score;
                }
            } else {
                double score = aspectPenalty + 4.0 + (longEdge - ANALYSIS_MAX_EDGE) / (double) ANALYSIS_MAX_EDGE;
                if (bestOverMax == null ||
                        score < bestOverMaxScore ||
                        (Math.abs(score - bestOverMaxScore) < 0.0001 && pixels(size) < pixels(bestOverMax))) {
                    bestOverMax = size;
                    bestOverMaxScore = score;
                }
            }
        }
        return bestUnderMax != null ? bestUnderMax : bestOverMax;
    }

    private Size choosePreviewSize(CameraCharacteristics characteristics) {
        StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
        Size[] sizes = map == null ? null : map.getOutputSizes(SurfaceTexture.class);
        if (sizes == null || sizes.length == 0) {
            return new Size(1280, 720);
        }
        Size bestUnderMax = null;
        Size smallestOverMax = null;
        for (Size size : sizes) {
            int longEdge = Math.max(size.getWidth(), size.getHeight());
            if (longEdge <= 1280) {
                if (bestUnderMax == null || pixels(size) > pixels(bestUnderMax)) {
                    bestUnderMax = size;
                }
            } else if (smallestOverMax == null || pixels(size) < pixels(smallestOverMax)) {
                smallestOverMax = size;
            }
        }
        return bestUnderMax != null ? bestUnderMax : smallestOverMax;
    }

    private long pixels(Size size) {
        return (long) size.getWidth() * (long) size.getHeight();
    }

    private int computeAnalysisRotation(CameraCharacteristics characteristics, boolean frontCamera) {
        Integer sensor = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
        int sensorOrientation = sensor == null ? 0 : sensor;
        int displayRotation = getDisplayRotationDegrees();
        if (frontCamera) {
            return normalizeDegrees(sensorOrientation + displayRotation);
        }
        return normalizeDegrees(sensorOrientation - displayRotation);
    }

    private int getDisplayRotationDegrees() {
        WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        if (windowManager == null || windowManager.getDefaultDisplay() == null) {
            return 0;
        }
        switch (windowManager.getDefaultDisplay().getRotation()) {
            case Surface.ROTATION_90:
                return 90;
            case Surface.ROTATION_180:
                return 180;
            case Surface.ROTATION_270:
                return 270;
            case Surface.ROTATION_0:
            default:
                return 0;
        }
    }

    private static int normalizeDegrees(int degrees) {
        int value = degrees % 360;
        return value < 0 ? value + 360 : value;
    }

    private void handleAnalysisImage(ImageReader reader) {
        try {
            long now = System.nanoTime();
            if (now - lastAnalysisNs < ANALYSIS_INTERVAL_NS) {
                closeLatestImage(reader);
                return;
            }
            if (listener == null || !listener.canAcceptAnalysisFrame()) {
                closeLatestImage(reader);
                return;
            }
            if (analysisInFlight.get()) {
                closeLatestImage(reader);
                return;
            }
            processLatestAnalysisImage(reader, analysisRotationDegrees);
        } catch (Exception error) {
            notifyError("analysis: " + error.getMessage());
        }
    }

    private void processLatestAnalysisImage(ImageReader reader, int rotationDegrees) {
        Image image = null;
        boolean markedInFlight = false;
        try {
            if (listener == null || !listener.canAcceptAnalysisFrame()) {
                closeLatestImage(reader);
                return;
            }
            if (!analysisInFlight.compareAndSet(false, true)) {
                closeLatestImage(reader);
                return;
            }
            markedInFlight = true;
            image = reader.acquireLatestImage();
            if (image == null) {
                return;
            }
            lastAnalysisNs = System.nanoTime();
            listener.onAnalysisImage(image, rotationDegrees);
        } catch (Exception error) {
            notifyError("analysis: " + error.getMessage());
        } finally {
            if (image != null) {
                image.close();
            }
            if (markedInFlight) {
                analysisInFlight.set(false);
            }
        }
    }

    private void closeLatestImage(ImageReader reader) {
        Image image = null;
        try {
            image = reader.acquireLatestImage();
        } catch (Exception ignored) {
            image = null;
        } finally {
            if (image != null) {
                image.close();
            }
        }
    }

}
