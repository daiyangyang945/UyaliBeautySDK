package com.uyali.beauty.demo;

import android.Manifest;
import android.app.Activity;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.SurfaceTexture;
import android.graphics.drawable.GradientDrawable;
import android.media.ExifInterface;
import android.media.Image;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.view.Gravity;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;
import com.uyali.beauty.UyaliBeautyDebugInfo;
import com.uyali.beauty.UyaliBeautyEngine;
import com.uyali.beauty.UyaliBeautyFrameProcessor;
import com.uyali.beauty.UyaliBeautyParameters;
import com.uyali.beauty.UyaliBeautyPoint;
import com.uyali.beauty.UyaliBeautyView;
import com.uyali.beauty.UyaliMakeupCatalog;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public final class MainActivity extends Activity implements Camera2Controller.Listener {
    private static final int CAMERA_PERMISSION_REQUEST = 1001;
    private static final int IMAGE_PICK_REQUEST = 1002;
    private static final int IMAGE_SAVE_PERMISSION_REQUEST = 1003;
    private static final int CATEGORY_NONE = -1;
    private static final int CATEGORY_BEAUTY = 0;
    private static final int CATEGORY_RESHAPE = 1;
    private static final int CATEGORY_BODY = 2;
    private static final int CATEGORY_MAKEUP = 3;
    private static final long SYNC_FRAME_NO_STALENESS_LIMIT_NS = Long.MAX_VALUE;
    private static final long SYNC_FRAME_BODY_COMBO_STALENESS_NS = 180_000_000L;
    private static final long SYNC_FRAME_FACE_REGION_COMBO_STALENESS_NS = 240_000_000L;
    private static final int PANEL_HEIGHT_DP = 130;
    private static final String[] CATEGORY_TITLES = {"美颜", "美型", "美体", "美妆"};

    private static final Feature[] BEAUTY_FEATURES = {
            new Feature("美白", "beauty_skin_white", "white", false),
            new Feature("磨皮", "beauty_skin_abrade", "skin", false),
            new Feature("亮眼", "beauty_bright_eye", "eyeBright", false),
            new Feature("白牙", "beauty_bright_teeth", "teethBright", false),
            new Feature("黑眼圈", "beauty_skin_abrade", "darkCircle", false)
    };

    private static final Feature[] RESHAPE_FEATURES = {
            new Feature("小头", "beauty_shape_head_reduce", "headReduce", false),
            new Feature("瘦脸", "beauty_shape_face_thin", "faceThin", false),
            new Feature("窄脸", "beauty_shape_face_narrow", "faceNarrow", false),
            new Feature("V脸", "beauty_shape_face_v", "faceV", false),
            new Feature("小脸", "beauty_shape_face_small", "faceSmall", false),
            new Feature("下巴", "beauty_shape_chin", "chin", true),
            new Feature("额头", "beauty_shape_forehead", "forehead", true),
            new Feature("颧骨", "beauty_shape_cheekbone", "cheekbone", true),
            new Feature("大眼", "beauty_shape_eye_big", "eyeBig", false),
            new Feature("眼距", "beauty_shape_eye_distance", "eyeDistance", true),
            new Feature("开眼角", "beauty_shape_eye_corner", "eyeCorner", false),
            new Feature("眼睑下至", "beauty_shape_eyelid_down", "eyelidDown", false),
            new Feature("瘦鼻", "beauty_shape_nose_thin", "noseThin", false),
            new Feature("鼻翼", "beauty_shape_nose_wing", "noseWing", false),
            new Feature("长鼻", "beauty_shape_nose_long", "noseLong", true),
            new Feature("山根", "beauty_shape_nose_root", "noseRoot", false),
            new Feature("眉间距", "beauty_shape_eyebrow_distance", "eyebrowDistance", true),
            new Feature("眉粗细", "beauty_shape_eyebrow_thin", "eyebrowThin", true),
            new Feature("嘴型", "beauty_shape_mouth", "mouth", true)
    };

    private static final Feature[] BODY_FEATURES = {
            new Feature("瘦身", "beauty_shape_body_slim", "bodySlim", false),
            new Feature("瘦腰", "beauty_shape_body_slim", "waistSlim", false),
            new Feature("瘦腿", "beauty_shape_leg_slim", "legSlim", false),
            new Feature("窄肩", "beauty_shape_body_slim", "shoulderNarrow", false),
            new Feature("瘦臂", "beauty_shape_body_slim", "armSlim", false),
            new Feature("小腿", "beauty_shape_leg_slim", "calfSlim", false),
            new Feature("收腹", "beauty_shape_body_slim", "abdomenSlim", false),
            new Feature("长腿", "beauty_shape_leg_long", "legLong", false),
            new Feature("增高", "beauty_shape_leg_long", "bodyHeight", false),
            new Feature("腿型", "beauty_shape_leg_slim", "legShape", false),
            new Feature("天鹅颈", "beauty_shape_body_slim", "neckLength", false),
            new Feature("直角肩", "beauty_shape_body_slim", "shoulderShape", false)
    };

    private static final String[] EYEBROW_NAMES = {
            "标准眉", "蹙颦眉", "罥烟眉", "流星眉", "柳叶眉",
            "秋波眉", "弯月眉", "新月眉", "野生眉", "远山眉"
    };
    private static final String[] EYEBROW_ICONS = {
            "eyebrow_biaozhun", "eyebrow_cupin", "eyebrow_juanyan", "eyebrow_liuxing", "eyebrow_liuye",
            "eyebrow_qiubo", "eyebrow_wanyue", "eyebrow_xinyue", "eyebrow_yesheng", "eyebrow_yuanshan"
    };

    private static final String[] EYESHADOW_NAMES = {
            "大地色", "复古色", "方糖粉", "活力橘", "金棕色", "朋克棕",
            "甜橙色", "星光粉", "烟粉色", "野蔷薇色", "元气橙"
    };
    private static final String[] EYESHADOW_ICONS = {
            "eyeshadow_dadise", "eyeshadow_fuguse", "eyeshadow_fangtangfen", "eyeshadow_huoliju",
            "eyeshadow_jinzongse", "eyeshadow_pengkezong", "eyeshadow_tianchengse", "eyeshadow_xingguangfen",
            "eyeshadow_yanfense", "eyeshadow_yeqiangweise", "eyeshadow_yuanqicheng"
    };

    private static final String[] PUPIL_NAMES = {
            "胶片棕", "蜜糖棕", "月球棕", "星夜蓝", "极昼黑", "勿扰灰", "春日粉",
            "甜茶绿", "四叶草绿", "旷野蓝", "蔷薇粉灰", "海风蓝"
    };
    private static final String[] PUPIL_ICONS = {
            "pupil_jiaopianzong", "pupil_mitangzong", "pupil_yueqiuzong", "pupil_xingyelan",
            "pupil_jizhouhei", "pupil_wuraohui", "pupil_chunrifen", "pupil_tianchalv", "pupil_siyecaolv",
            "pupil_kuangyelan", "pupil_qiangweifenhui", "pupil_haifenglan"
    };

    private static final String[] BLUSH_NAMES = {
            "奶杏色", "奶橘色", "蜜桃橘", "烟熏玫瑰", "牛奶草莓",
            "奶杏色", "奶橘色", "蜜桃橘", "烟熏玫瑰", "牛奶草莓",
            "奶杏色", "奶橘色", "蜜桃橘", "烟熏玫瑰", "牛奶草莓",
            "奶杏色", "奶橘色", "蜜桃橘", "烟熏玫瑰", "牛奶草莓",
            "奶杏色", "奶橘色", "蜜桃橘", "烟熏玫瑰", "牛奶草莓",
            "奶杏色", "奶橘色", "蜜桃橘", "烟熏玫瑰", "牛奶草莓"
    };
    private static final String[] BLUSH_ICONS = {
            "blush_wugu_naixingse", "blush_wugu_naijuse", "blush_wugu_mitaoju", "blush_wugu_yanxunmeigui", "blush_wugu_niunaicaomei",
            "blush_chayi_naixingse", "blush_chayi_naijuse", "blush_chayi_mitaoju", "blush_chayi_yanxunmeigui", "blush_chayi_niunaicaomei",
            "blush_chulian_naixingse", "blush_chulian_naijuse", "blush_chulian_mitaoju", "blush_chulian_yanxunmeigui", "blush_chulian_niunaicaomei",
            "blush_chunqing_naixingse", "blush_chunqing_naijuse", "blush_chunqing_mitaoju", "blush_chunqing_yanxunmeigui", "blush_chunqing_niunaicaomei",
            "blush_qiji_naixingse", "blush_qiji_naijuse", "blush_qiji_mitaoju", "blush_qiji_yanxunmeigui", "blush_qiji_niunaicaomei",
            "blush_shaonv_naixingse", "blush_shaonv_naijuse", "blush_shaonv_mitaoju", "blush_shaonv_yanxunmeigui", "blush_shaonv_niunaicaomei"
    };

    private static final String[] ROUGE_NAMES = {
            "梅子色", "豆沙粉", "复古色", "鬼魅红", "浆果色", "南瓜色",
            "石榴红", "蜜桃色", "珊瑚色", "星光红", "暗夜紫", "少女粉"
    };
    private static final String[] ROUGE_ICONS = {
            "lip_meizise", "lip_doushafen", "lip_fuguse", "lip_guimeihong", "lip_jiangguose", "lip_nanguase",
            "lip_shiliuhong", "lip_mitaose", "lip_shanhuse", "lip_xingguanghong", "lip_anyezi", "lip_shaonvfen"
    };

    private static final MakeupGroup[] MAKEUP_GROUPS = {
            new MakeupGroup("眉毛", "makeup_eyebrow", "makeupEyebrow", "makeupEyebrowType",
                    EYEBROW_NAMES, EYEBROW_ICONS, UyaliMakeupCatalog.EYEBROW_TYPES),
            new MakeupGroup("眼妆", "makeup_eyeshadow", "makeupEyeshadow", "makeupEyeshadowType",
                    EYESHADOW_NAMES, EYESHADOW_ICONS, UyaliMakeupCatalog.EYESHADOW_TYPES),
            new MakeupGroup("美瞳", "makeup_pupil", "makeupPupil", "makeupPupilType",
                    PUPIL_NAMES, PUPIL_ICONS, UyaliMakeupCatalog.PUPIL_TYPES),
            new MakeupGroup("腮红", "makeup_blush", "makeupBlush", "makeupBlushType",
                    BLUSH_NAMES, BLUSH_ICONS, UyaliMakeupCatalog.BLUSH_TYPES),
            new MakeupGroup("口红", "makeup_lip", "makeupRouge", "makeupRougeType",
                    ROUGE_NAMES, ROUGE_ICONS, UyaliMakeupCatalog.ROUGE_TYPES)
    };

    private enum ScreenMode {
        HOME,
        CAMERA,
        IMAGE
    }

    private enum CameraProcessingBackend {
        GPU,
        CPU
    }

    private FrameLayout root;
    private UyaliBeautyView beautyView;
    private Camera2Controller cameraController;
    private TextView debugText;
    private LandmarkOverlayView landmarkOverlay;
    private FrameLayout panelContainer;
    private LinearLayout categoryBar;
    private Bitmap sourceBitmap;
    private ScreenMode screenMode = ScreenMode.HOME;
    private int selectedCategory = CATEGORY_NONE;
    private int selectedMakeupGroup = CATEGORY_NONE;
    private final int[] selectedFeatureIndexes = {0, 0, 0, 0};
    private boolean landmarksVisible;
    private int previewSourceWidth;
    private int previewSourceHeight;
    private boolean previewMirrored;
    private boolean previewFitCenter;
    private CameraProcessingBackend cameraProcessingBackend = CameraProcessingBackend.GPU;
    private Button gpuBackendButton;
    private Button cpuBackendButton;
    private ByteBuffer cpuCameraOutputRgba;
    private final AtomicBoolean analysisBusy = new AtomicBoolean(false);
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final Runnable debugTicker = new Runnable() {
        @Override
        public void run() {
            updateDebugText();
            updateLandmarkOverlay();
            if (screenMode != ScreenMode.HOME) {
                mainHandler.postDelayed(this, screenMode == ScreenMode.CAMERA && landmarksVisible ? 33 : 500);
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (!showImageFromIntent(getIntent())) {
            showHome();
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        showImageFromIntent(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (screenMode == ScreenMode.CAMERA && beautyView != null) {
            beautyView.onResume();
            if (hasCameraPermission() && cameraController != null) {
                cameraController.start();
            }
            mainHandler.post(debugTicker);
        } else if (screenMode == ScreenMode.IMAGE) {
            if (beautyView != null) {
                beautyView.onResume();
            }
            mainHandler.post(debugTicker);
        }
    }

    @Override
    protected void onPause() {
        mainHandler.removeCallbacks(debugTicker);
        if (cameraController != null) {
            cameraController.stop();
        }
        if (beautyView != null) {
            beautyView.onPause();
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        releaseCameraSession();
        releaseImageSession();
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (screenMode == ScreenMode.HOME) {
            super.onBackPressed();
        } else {
            showHome();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == CAMERA_PERMISSION_REQUEST) {
            if (grantResults.length > 0 &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                    screenMode == ScreenMode.CAMERA &&
                    cameraController != null) {
                cameraController.start();
            } else if (debugText != null) {
                debugText.setVisibility(View.VISIBLE);
                debugText.setText("camera: permission denied");
            }
        } else if (requestCode == IMAGE_SAVE_PERMISSION_REQUEST &&
                grantResults.length > 0 &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                screenMode == ScreenMode.IMAGE) {
            saveImage();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != IMAGE_PICK_REQUEST || resultCode != RESULT_OK || data == null || data.getData() == null) {
            return;
        }
        Bitmap bitmap = decodePickedBitmap(data.getData());
        if (bitmap != null) {
            showImageMode(bitmap);
        }
    }

    private boolean showImageFromIntent(Intent intent) {
        if (intent == null) {
            return false;
        }
        Bitmap bitmap = null;
        String imagePath = intent.getStringExtra("uyali.image_path");
        if (imagePath == null || imagePath.length() == 0) {
            imagePath = intent.getStringExtra("image_path");
        }
        if (imagePath != null && imagePath.length() > 0) {
            bitmap = decodeImageFileBitmap(imagePath);
        }
        if (bitmap == null && intent.getData() != null) {
            bitmap = decodePickedBitmap(intent.getData());
        }
        if (bitmap == null) {
            return false;
        }
        showImageMode(bitmap);
        return true;
    }

    @Override
    public void onCameraError(String message) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (debugText != null) {
                    debugText.setVisibility(View.VISIBLE);
                    debugText.setText("camera: " + message);
                }
            }
        });
    }

    @Override
    public void onCameraFacingChanged(boolean front) {
        previewMirrored = false;
        if (beautyView != null) {
            beautyView.engine().setInputMirrored(cameraProcessingBackend == CameraProcessingBackend.CPU && front);
            beautyView.setOutputMirrored(false);
        }
        if (landmarkOverlay != null) {
            landmarkOverlay.setPreviewGeometry(previewSourceWidth, previewSourceHeight, previewMirrored, previewFitCenter);
        }
    }

    @Override
    public void onCameraPreviewSizeSelected(int width, int height, int rotationDegrees) {
        UyaliBeautyView view = beautyView;
        if (view != null) {
            view.setCameraBufferSize(width, height, rotationDegrees);
        }
        boolean rotated = normalizeDegrees(rotationDegrees) == 90 || normalizeDegrees(rotationDegrees) == 270;
        previewSourceWidth = rotated ? height : width;
        previewSourceHeight = rotated ? width : height;
        if (landmarkOverlay != null) {
            landmarkOverlay.setPreviewGeometry(previewSourceWidth, previewSourceHeight, previewMirrored, previewFitCenter);
        }
    }

    @Override
    public boolean needsAnalysisStream() {
        return screenMode == ScreenMode.CAMERA &&
                cameraProcessingBackend == CameraProcessingBackend.CPU;
    }

    @Override
    public boolean canAcceptAnalysisFrame() {
        return screenMode == ScreenMode.CAMERA &&
                beautyView != null &&
                cameraProcessingBackend == CameraProcessingBackend.CPU &&
                !analysisBusy.get();
    }

    @Override
    public void onAnalysisImage(Image image, int rotationDegrees) {
        if (!analysisBusy.compareAndSet(false, true)) {
            return;
        }
        try {
            UyaliBeautyView view = beautyView;
            if (screenMode == ScreenMode.CAMERA && view != null && image != null) {
                if (cameraProcessingBackend == CameraProcessingBackend.CPU) {
                    processCpuCameraFrame(view, image, rotationDegrees);
                }
            }
        } finally {
            analysisBusy.set(false);
        }
    }

    private void processCpuCameraFrame(UyaliBeautyView view, Image image, int rotationDegrees) {
        UyaliBeautyEngine engine = view.engine();
        int outputWidth = UyaliBeautyFrameProcessor.outputWidth(image, rotationDegrees);
        int outputHeight = UyaliBeautyFrameProcessor.outputHeight(image, rotationDegrees);
        int requiredBytes = UyaliBeautyFrameProcessor.requiredRgbaBufferSize(image, rotationDegrees);
        if (engine == null || outputWidth <= 0 || outputHeight <= 0 || requiredBytes <= 0) {
            return;
        }
        if (cpuCameraOutputRgba == null || cpuCameraOutputRgba.capacity() < requiredBytes) {
            cpuCameraOutputRgba = ByteBuffer.allocateDirect(requiredBytes);
        }
        cpuCameraOutputRgba.clear();
        cpuCameraOutputRgba.limit(requiredBytes);
        boolean ok = engine.process(image, rotationDegrees, cpuCameraOutputRgba);
        if (!ok) {
            return;
        }
        cpuCameraOutputRgba.position(0);
        cpuCameraOutputRgba.limit(requiredBytes);
        view.setProcessedRgbaFrame(cpuCameraOutputRgba, outputWidth, outputHeight, false);
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                if (screenMode == ScreenMode.CAMERA) {
                    updateLandmarkOverlay();
                    updateDebugText();
                }
            }
        });
    }

    private boolean shouldRunCameraAnalysis() {
        if (screenMode != ScreenMode.CAMERA || beautyView == null) {
            return false;
        }
        if (landmarksVisible) {
            return true;
        }
        UyaliBeautyParameters p = beautyView.engine().parameters();
        if (p == null) {
            return false;
        }
        return hasActiveFaceMesh(p) || hasActiveBody(p) || hasActiveMakeup(p);
    }

    private void updateCameraProcessingMode() {
        if (screenMode != ScreenMode.CAMERA || beautyView == null) {
            return;
        }
        UyaliBeautyParameters p = beautyView.engine().parameters();
        boolean useSynchronizedCamera = cameraProcessingBackend == CameraProcessingBackend.GPU &&
                shouldUseSynchronizedCameraProcessing(p);
        beautyView.textureProcessor().setAutomaticTextureAnalysisEnabled(true);
        beautyView.setSynchronizedCameraFrameMaxStalenessNs(synchronizedCameraFrameMaxStalenessNs(p));
        beautyView.setSynchronizedCameraMode(useSynchronizedCamera);
        if (cameraProcessingBackend == CameraProcessingBackend.GPU && !shouldRunCameraAnalysis()) {
            beautyView.setOutputMirrored(false);
            beautyView.clearImageBitmap();
        }
    }

    private boolean shouldUseSynchronizedCameraProcessing() {
        if (screenMode != ScreenMode.CAMERA || beautyView == null) {
            return false;
        }
        UyaliBeautyParameters p = beautyView.engine().parameters();
        return cameraProcessingBackend == CameraProcessingBackend.GPU &&
                shouldUseSynchronizedCameraProcessing(p);
    }

    private boolean shouldUseSynchronizedCameraProcessing(UyaliBeautyParameters p) {
        return hasActiveMakeup(p) || hasActiveFaceReshape(p);
    }

    private long synchronizedCameraFrameMaxStalenessNs(UyaliBeautyParameters p) {
        if (p == null) {
            return SYNC_FRAME_NO_STALENESS_LIMIT_NS;
        }
        if (hasActiveBody(p)) {
            return SYNC_FRAME_BODY_COMBO_STALENESS_NS;
        }
        if (hasActiveFaceRegionBeauty(p)) {
            return SYNC_FRAME_FACE_REGION_COMBO_STALENESS_NS;
        }
        return SYNC_FRAME_NO_STALENESS_LIMIT_NS;
    }

    private boolean hasActiveBody(UyaliBeautyParameters p) {
        return p != null &&
                (nonZero(p.bodySlim) ||
                nonZero(p.waistSlim) ||
                nonZero(p.legSlim) ||
                nonZero(p.shoulderNarrow) ||
                nonZero(p.armSlim) ||
                nonZero(p.calfSlim) ||
                nonZero(p.abdomenSlim) ||
                nonZero(p.legLong) ||
                nonZero(p.bodyHeight) ||
                nonZero(p.legShape) ||
                nonZero(p.neckLength) ||
                nonZero(p.shoulderShape));
    }

    private boolean hasActiveFaceMesh(UyaliBeautyParameters p) {
        return hasActiveFaceReshape(p) || hasActiveFaceRegionBeauty(p);
    }

    private boolean hasActiveFaceReshape(UyaliBeautyParameters p) {
        return p != null &&
                (nonZero(p.headReduce) ||
                nonZero(p.faceThin) ||
                nonZero(p.faceNarrow) ||
                nonZero(p.faceV) ||
                nonZero(p.faceSmall) ||
                nonZero(p.chin) ||
                nonZero(p.forehead) ||
                nonZero(p.cheekbone) ||
                nonZero(p.eyeBig) ||
                nonZero(p.eyeDistance) ||
                nonZero(p.eyeCorner) ||
                nonZero(p.eyelidDown) ||
                nonZero(p.noseThin) ||
                nonZero(p.noseWing) ||
                nonZero(p.noseLong) ||
                nonZero(p.noseRoot) ||
                nonZero(p.eyebrowDistance) ||
                nonZero(p.eyebrowThin) ||
                nonZero(p.mouth));
    }

    private boolean hasActiveFaceRegionBeauty(UyaliBeautyParameters p) {
        return p != null &&
                (nonZero(p.skin) ||
                nonZero(p.eyeBright) ||
                nonZero(p.teethBright) ||
                nonZero(p.darkCircle) ||
                nonZero(p.nasolabialFold));
    }

    private boolean hasActiveMakeup(UyaliBeautyParameters p) {
        return p != null &&
                ((nonZero(p.makeupEyebrow) && p.makeupEyebrowType > 0) ||
                (nonZero(p.makeupEyeshadow) && p.makeupEyeshadowType > 0) ||
                (nonZero(p.makeupPupil) && p.makeupPupilType > 0) ||
                (nonZero(p.makeupBlush) && p.makeupBlushType > 0) ||
                (nonZero(p.makeupRouge) && p.makeupRougeType > 0));
    }

    private static boolean nonZero(float value) {
        return Math.abs(value) > 0.0001f;
    }

    private void showHome() {
        releaseCameraSession();
        releaseImageSession();
        screenMode = ScreenMode.HOME;
        selectedCategory = CATEGORY_NONE;
        selectedMakeupGroup = CATEGORY_NONE;
        landmarksVisible = false;
        mainHandler.removeCallbacks(debugTicker);

        root = new FrameLayout(this);
        root.setBackgroundColor(Color.WHITE);

        LinearLayout buttons = new LinearLayout(this);
        buttons.setOrientation(LinearLayout.VERTICAL);
        buttons.setGravity(Gravity.CENTER);
        buttons.setPadding(dp(24), 0, dp(24), 0);
        root.addView(buttons, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        Button cameraButton = makeHomeButton("相机美颜");
        cameraButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showCameraMode();
            }
        });
        buttons.addView(cameraButton, new LinearLayout.LayoutParams(dp(160), dp(52)));

        Button imageButton = makeHomeButton("图片美颜");
        imageButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                pickImage();
            }
        });
        LinearLayout.LayoutParams imageParams = new LinearLayout.LayoutParams(dp(160), dp(52));
        imageParams.topMargin = dp(10);
        buttons.addView(imageButton, imageParams);

        setContentView(root);
    }

    private void showCameraMode() {
        releaseCameraSession();
        releaseImageSession();
        screenMode = ScreenMode.CAMERA;
        selectedCategory = CATEGORY_NONE;
        selectedMakeupGroup = CATEGORY_NONE;
        landmarksVisible = false;
        previewSourceWidth = 0;
        previewSourceHeight = 0;
        previewMirrored = false;
        previewFitCenter = false;
        cpuCameraOutputRgba = null;

        beautyView = new UyaliBeautyView(this);
        beautyView.setGpuTextureProcessing(cameraProcessingBackend == CameraProcessingBackend.GPU);
        cameraController = new Camera2Controller(this, this);
        beautyView.setCameraSurfaceListener(new UyaliBeautyView.CameraSurfaceListener() {
            @Override
            public void onCameraSurfaceCreated(Surface surface, SurfaceTexture surfaceTexture) {
                if (cameraController != null) {
                    cameraController.setPreviewSurface(surface, surfaceTexture);
                }
            }

            @Override
            public void onCameraSurfaceDestroyed() {
                if (cameraController != null) {
                    cameraController.setPreviewSurface(null, null);
                }
            }
        });

        root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);
        root.addView(beautyView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
        addLandmarkOverlay();

        addTopBar(true);
        addDebugText();
        addBottomControls();
        setContentView(root);

        beautyView.onResume();
        updateCameraProcessingMode();
        mainHandler.post(debugTicker);
        if (hasCameraPermission()) {
            cameraController.start();
        } else {
            requestPermissions(new String[]{Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST);
        }
    }

    private void showImageMode(Bitmap bitmap) {
        releaseCameraSession();
        releaseImageSession();
        screenMode = ScreenMode.IMAGE;
        selectedCategory = CATEGORY_NONE;
        selectedMakeupGroup = CATEGORY_NONE;
        landmarksVisible = false;
        sourceBitmap = bitmap.getConfig() == Bitmap.Config.ARGB_8888 ? bitmap : bitmap.copy(Bitmap.Config.ARGB_8888, false);
        previewSourceWidth = sourceBitmap.getWidth();
        previewSourceHeight = sourceBitmap.getHeight();
        previewMirrored = false;
        previewFitCenter = true;

        root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);

        beautyView = new UyaliBeautyView(this);
        root.addView(beautyView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
        addLandmarkOverlay();

        addTopBar(false);
        addDebugText();
        addBottomControls();
        setContentView(root);
        beautyView.onResume();
        beautyView.setImageBitmap(sourceBitmap);
        mainHandler.post(debugTicker);
    }

    private void addTopBar(boolean cameraMode) {
        FrameLayout topBar = new FrameLayout(this);
        root.addView(topBar, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                dp(84),
                Gravity.TOP));

        Button closeButton = makeTopButton("关闭");
        closeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showHome();
            }
        });
        FrameLayout.LayoutParams closeParams = new FrameLayout.LayoutParams(
                dp(64),
                dp(50),
                Gravity.START | Gravity.BOTTOM);
        closeParams.leftMargin = dp(8);
        topBar.addView(closeButton, closeParams);

        Button debugButton = makeTopButton("点位");
        debugButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                landmarksVisible = !landmarksVisible;
                if (landmarkOverlay != null) {
                    landmarkOverlay.setVisibility(landmarksVisible ? View.VISIBLE : View.GONE);
                    updateLandmarkOverlay();
                }
                if (debugText != null) {
                    debugText.setVisibility(landmarksVisible ? View.VISIBLE : View.GONE);
                    updateDebugText();
                }
                updateCameraProcessingMode();
                requestCurrentRender();
            }
        });
        topBar.addView(debugButton, new FrameLayout.LayoutParams(
                dp(64),
                dp(50),
                Gravity.CENTER_HORIZONTAL | Gravity.BOTTOM));

        Button rightButton = makeTopButton(cameraMode ? "切换" : "保存");
        rightButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (screenMode == ScreenMode.CAMERA && cameraController != null) {
                    cameraController.switchCamera();
                } else if (screenMode == ScreenMode.IMAGE) {
                    saveImage();
                }
            }
        });
        FrameLayout.LayoutParams rightParams = new FrameLayout.LayoutParams(
                dp(64),
                dp(50),
                Gravity.END | Gravity.BOTTOM);
        rightParams.rightMargin = dp(8);
        topBar.addView(rightButton, rightParams);
    }

    private void addDebugText() {
        debugText = new TextView(this);
        debugText.setTextColor(Color.WHITE);
        debugText.setTextSize(12f);
        debugText.setBackgroundColor(0x66000000);
        debugText.setPadding(dp(12), dp(10), dp(12), dp(10));
        debugText.setVisibility(View.GONE);
        FrameLayout.LayoutParams debugParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.TOP);
        debugParams.topMargin = dp(84);
        root.addView(debugText, debugParams);
    }

    private void setCameraProcessingBackend(CameraProcessingBackend backend) {
        if (backend == null) {
            return;
        }
        cameraProcessingBackend = backend;
        cpuCameraOutputRgba = null;
        if (beautyView != null && screenMode == ScreenMode.CAMERA) {
            beautyView.setGpuTextureProcessing(backend == CameraProcessingBackend.GPU);
            beautyView.engine().setInputMirrored(backend == CameraProcessingBackend.CPU &&
                    cameraController != null &&
                    cameraController.isFrontCamera());
            if (backend == CameraProcessingBackend.GPU) {
                beautyView.clearImageBitmap();
            }
            updateCameraProcessingMode();
            requestCurrentRender();
        }
        updateBackendButtons();
    }

    private void updateBackendButtons() {
        if (gpuBackendButton == null || cpuBackendButton == null) {
            return;
        }
        boolean gpu = cameraProcessingBackend == CameraProcessingBackend.GPU;
        gpuBackendButton.setTextColor(gpu ? Color.BLACK : Color.DKGRAY);
        cpuBackendButton.setTextColor(gpu ? Color.DKGRAY : Color.BLACK);
        gpuBackendButton.setBackground(roundedBackground(gpu ? 0xFFFFD166 : 0xFFEDEDED, 0xFFB0B0B0, 1, 4));
        cpuBackendButton.setBackground(roundedBackground(gpu ? 0xFFEDEDED : 0xFFFFD166, 0xFFB0B0B0, 1, 4));
    }

    private void addLandmarkOverlay() {
        landmarkOverlay = new LandmarkOverlayView(this);
        landmarkOverlay.setVisibility(View.GONE);
        landmarkOverlay.setPreviewGeometry(previewSourceWidth, previewSourceHeight, previewMirrored, previewFitCenter);
        root.addView(landmarkOverlay, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
    }

    private void addBottomControls() {
        panelContainer = new FrameLayout(this);
        panelContainer.setVisibility(View.GONE);
        FrameLayout.LayoutParams panelParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                dp(PANEL_HEIGHT_DP),
                Gravity.BOTTOM);
        panelParams.bottomMargin = dp(54);
        root.addView(panelContainer, panelParams);

        categoryBar = new LinearLayout(this);
        categoryBar.setOrientation(LinearLayout.HORIZONTAL);
        categoryBar.setGravity(Gravity.CENTER);
        categoryBar.setBackgroundColor(0xCC000000);
        root.addView(categoryBar, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                dp(54),
                Gravity.BOTTOM));

        for (int index = 0; index < CATEGORY_TITLES.length; index++) {
            final int category = index;
            Button button = makeCategoryButton(CATEGORY_TITLES[index]);
            button.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    toggleCategory(category);
                }
            });
            categoryBar.addView(button, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f));
        }
    }

    private void toggleCategory(int category) {
        if (selectedCategory == category) {
            selectedCategory = CATEGORY_NONE;
            selectedMakeupGroup = CATEGORY_NONE;
            panelContainer.removeAllViews();
            panelContainer.setVisibility(View.GONE);
        } else {
            selectedCategory = category;
            selectedMakeupGroup = CATEGORY_NONE;
            panelContainer.removeAllViews();
            panelContainer.addView(makePanelForCategory(category), new FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT));
            panelContainer.setVisibility(View.VISIBLE);
        }
        updateCategoryButtons();
    }

    private View makePanelForCategory(int category) {
        if (category == CATEGORY_MAKEUP) {
            return makeMakeupGroupPanel();
        }
        return makeFeaturePanel(category, featuresForCategory(category));
    }

    private View makeFeaturePanel(final int category, final Feature[] features) {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(0, 0, 0, dp(4));
        panel.setBackgroundColor(0xCC000000);

        final TextView valueLabel = makeValueLabel(false);
        panel.addView(valueLabel, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(24)));

        final SeekBar seekBar = new SeekBar(this);
        LinearLayout.LayoutParams seekParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(36));
        seekParams.leftMargin = dp(16);
        seekParams.rightMargin = dp(16);
        panel.addView(seekBar, seekParams);

        HorizontalScrollView scrollView = new HorizontalScrollView(this);
        scrollView.setHorizontalScrollBarEnabled(false);
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(16), 0, dp(16), 0);
        scrollView.addView(row, new HorizontalScrollView.LayoutParams(
                HorizontalScrollView.LayoutParams.WRAP_CONTENT,
                HorizontalScrollView.LayoutParams.MATCH_PARENT));
        panel.addView(scrollView, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f));

        int selectedIndex = Math.max(0, Math.min(selectedFeatureIndexes[category], features.length - 1));
        selectedFeatureIndexes[category] = selectedIndex;
        final Feature[] activeFeature = new Feature[]{features[selectedIndex]};
        final boolean[] updating = new boolean[]{false};
        final ArrayList<IconTextButton> buttons = new ArrayList<>();

        seekBar.setMax(100);
        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int value, boolean fromUser) {
                if (updating[0]) {
                    return;
                }
                applyFeatureValue(activeFeature[0], value, valueLabel);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                requestCurrentRender();
            }
        });

        for (int i = 0; i < features.length; i++) {
            final int index = i;
            final Feature feature = features[i];
            IconTextButton button = new IconTextButton(feature.name, feature.icon, false);
            button.setActive(index == selectedIndex);
            button.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    selectedFeatureIndexes[category] = index;
                    activeFeature[0] = feature;
                    for (int j = 0; j < buttons.size(); j++) {
                        buttons.get(j).setActive(j == index);
                    }
                    configureFeatureSeekBar(seekBar, valueLabel, feature, updating);
                }
            });
            LinearLayout.LayoutParams itemParams = new LinearLayout.LayoutParams(dp(64), dp(60));
            if (i > 0) {
                itemParams.leftMargin = dp(16);
            }
            row.addView(button, itemParams);
            buttons.add(button);
        }

        configureFeatureSeekBar(seekBar, valueLabel, activeFeature[0], updating);
        return panel;
    }

    private View makeMakeupGroupPanel() {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setBackgroundColor(0xCC000000);

        TextView title = makeValueLabel(false);
        title.setText("美妆");
        title.setTextSize(20f);
        panel.addView(title, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(60)));

        HorizontalScrollView scrollView = new HorizontalScrollView(this);
        scrollView.setHorizontalScrollBarEnabled(false);
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(16), 0, dp(16), 0);
        scrollView.addView(row, new HorizontalScrollView.LayoutParams(
                HorizontalScrollView.LayoutParams.WRAP_CONTENT,
                HorizontalScrollView.LayoutParams.MATCH_PARENT));
        panel.addView(scrollView, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f));

        for (int i = 0; i < MAKEUP_GROUPS.length; i++) {
            final int index = i;
            MakeupGroup group = MAKEUP_GROUPS[i];
            IconTextButton button = new IconTextButton(group.name, group.icon, false);
            button.setActive(false);
            button.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    selectedMakeupGroup = index;
                    panelContainer.removeAllViews();
                    panelContainer.addView(makeMakeupDetailPanel(MAKEUP_GROUPS[index]), new FrameLayout.LayoutParams(
                            FrameLayout.LayoutParams.MATCH_PARENT,
                            FrameLayout.LayoutParams.MATCH_PARENT));
                }
            });
            LinearLayout.LayoutParams itemParams = new LinearLayout.LayoutParams(dp(64), dp(60));
            if (i > 0) {
                itemParams.leftMargin = dp(16);
            }
            row.addView(button, itemParams);
        }

        return panel;
    }

    private View makeMakeupDetailPanel(final MakeupGroup group) {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(0, 0, 0, dp(4));
        panel.setBackgroundColor(Color.WHITE);

        final TextView valueLabel = makeValueLabel(true);
        panel.addView(valueLabel, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(24)));

        final SeekBar seekBar = new SeekBar(this);
        LinearLayout.LayoutParams seekParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(36));
        seekParams.leftMargin = dp(16);
        seekParams.rightMargin = dp(16);
        panel.addView(seekBar, seekParams);

        LinearLayout itemArea = new LinearLayout(this);
        itemArea.setOrientation(LinearLayout.HORIZONTAL);
        itemArea.setGravity(Gravity.CENTER_VERTICAL);
        panel.addView(itemArea, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f));

        IconTextButton backButton = new IconTextButton(group.name, "makeup_back", true);
        backButton.setActive(false);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                selectedMakeupGroup = CATEGORY_NONE;
                panelContainer.removeAllViews();
                panelContainer.addView(makeMakeupGroupPanel(), new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT));
            }
        });
        itemArea.addView(backButton, new LinearLayout.LayoutParams(dp(60), LinearLayout.LayoutParams.MATCH_PARENT));

        View line = new View(this);
        line.setBackgroundColor(0xFFE0E0E0);
        itemArea.addView(line, new LinearLayout.LayoutParams(dp(1), LinearLayout.LayoutParams.MATCH_PARENT));

        HorizontalScrollView scrollView = new HorizontalScrollView(this);
        scrollView.setHorizontalScrollBarEnabled(false);
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(dp(10), 0, dp(10), 0);
        scrollView.addView(row, new HorizontalScrollView.LayoutParams(
                HorizontalScrollView.LayoutParams.WRAP_CONTENT,
                HorizontalScrollView.LayoutParams.MATCH_PARENT));
        itemArea.addView(scrollView, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f));

        final boolean[] updating = new boolean[]{false};
        seekBar.setMax(100);
        seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int value, boolean fromUser) {
                if (updating[0]) {
                    return;
                }
                applyFeatureValue(new Feature(group.name, group.icon, group.parameter, false), value, valueLabel);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                requestCurrentRender();
            }
        });

        final ArrayList<IconTextButton> optionButtons = new ArrayList<>();
        int currentType = makeupTypeForParameter(group.typeParameter);
        int optionCount = Math.min(group.typeValues.length, Math.min(group.itemIcons.length, group.itemNames.length)) + 1;
        for (int i = 0; i < optionCount; i++) {
            final int typeValue = i == 0 ? 0 : group.typeValues[i - 1];
            String name = i == 0 ? "无" : group.itemNames[i - 1];
            String icon = i == 0 ? "makeup_none" : group.itemIcons[i - 1];
            IconTextButton button = new IconTextButton(name, icon, true);
            button.setActive(typeValue == currentType);
            button.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    setMakeupType(group.typeParameter, typeValue);
                    for (int j = 0; j < optionButtons.size(); j++) {
                        int optionType = j == 0 ? 0 : group.typeValues[j - 1];
                        optionButtons.get(j).setActive(optionType == typeValue);
                    }
                }
            });
            LinearLayout.LayoutParams itemParams = new LinearLayout.LayoutParams(dp(60), LinearLayout.LayoutParams.MATCH_PARENT);
            if (i > 0) {
                itemParams.leftMargin = dp(10);
            }
            row.addView(button, itemParams);
            optionButtons.add(button);
        }

        configureFeatureSeekBar(seekBar, valueLabel, new Feature(group.name, group.icon, group.parameter, false), updating);
        return panel;
    }

    private void configureFeatureSeekBar(SeekBar seekBar, TextView valueLabel, Feature feature, boolean[] updating) {
        int progress = progressForParameter(feature.parameter, feature.signed);
        updating[0] = true;
        seekBar.setProgress(progress);
        updating[0] = false;
        valueLabel.setText(displayValue(progress, feature.signed));
    }

    private void applyFeatureValue(Feature feature, int progress, TextView valueLabel) {
        float actual = feature.signed ? progress - 50f : progress;
        valueLabel.setText(displayValue(progress, feature.signed));
        UyaliBeautyEngine engine = currentEngine();
        if (engine != null) {
            engine.setParameter(feature.parameter, actual);
        }
        updateCameraProcessingMode();
        requestCurrentRender();
    }

    private Feature[] featuresForCategory(int category) {
        if (category == CATEGORY_BEAUTY) {
            return BEAUTY_FEATURES;
        }
        if (category == CATEGORY_RESHAPE) {
            return RESHAPE_FEATURES;
        }
        if (category == CATEGORY_BODY) {
            return BODY_FEATURES;
        }
        return BEAUTY_FEATURES;
    }

    private void setMakeupType(String typeName, int value) {
        UyaliBeautyEngine engine = currentEngine();
        if (engine != null) {
            engine.setMakeupType(typeName, value);
        }
        updateCameraProcessingMode();
        requestCurrentRender();
    }

    private void updateCategoryButtons() {
        if (categoryBar == null) {
            return;
        }
        for (int i = 0; i < categoryBar.getChildCount(); i++) {
            View child = categoryBar.getChildAt(i);
            if (child instanceof Button) {
                ((Button) child).setTextColor(i == selectedCategory ? 0xFFFFD166 : Color.WHITE);
            }
        }
    }

    private void pickImage() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/*");
        startActivityForResult(Intent.createChooser(intent, "图片美颜"), IMAGE_PICK_REQUEST);
    }

    private Bitmap decodePickedBitmap(Uri uri) {
        try {
            int orientation = readExifOrientation(uri);
            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            InputStream boundsStream = getContentResolver().openInputStream(uri);
            if (boundsStream != null) {
                try {
                    BitmapFactory.decodeStream(boundsStream, null, bounds);
                } finally {
                    boundsStream.close();
                }
            }

            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inPreferredConfig = Bitmap.Config.ARGB_8888;
            options.inSampleSize = sampleSizeForMaxEdge(bounds.outWidth, bounds.outHeight, 1440);
            InputStream imageStream = getContentResolver().openInputStream(uri);
            if (imageStream == null) {
                return null;
            }
            try {
                Bitmap bitmap = BitmapFactory.decodeStream(imageStream, null, options);
                return normalizePickedBitmap(bitmap, orientation);
            } finally {
                imageStream.close();
            }
        } catch (Exception error) {
            return null;
        }
    }

    private Bitmap decodeImageFileBitmap(String path) {
        try {
            int orientation = ExifInterface.ORIENTATION_NORMAL;
            try {
                orientation = new ExifInterface(path).getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_NORMAL);
            } catch (Exception ignored) {
                orientation = ExifInterface.ORIENTATION_NORMAL;
            }

            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(path, bounds);

            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inPreferredConfig = Bitmap.Config.ARGB_8888;
            options.inSampleSize = sampleSizeForMaxEdge(bounds.outWidth, bounds.outHeight, 1440);
            Bitmap bitmap = BitmapFactory.decodeFile(path, options);
            return normalizePickedBitmap(bitmap, orientation);
        } catch (Exception error) {
            return null;
        }
    }

    private int readExifOrientation(Uri uri) {
        InputStream stream = null;
        try {
            stream = getContentResolver().openInputStream(uri);
            if (stream == null) {
                return ExifInterface.ORIENTATION_NORMAL;
            }
            ExifInterface exif = new ExifInterface(stream);
            return exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
        } catch (Exception error) {
            return ExifInterface.ORIENTATION_NORMAL;
        } finally {
            if (stream != null) {
                try {
                    stream.close();
                } catch (Exception ignored) {
                }
            }
        }
    }

    private int sampleSizeForMaxEdge(int width, int height, int maxAllowedEdge) {
        int sampleSize = 1;
        int maxEdge = Math.max(width, height);
        if (maxEdge <= 0 || maxAllowedEdge <= 0) {
            return sampleSize;
        }
        while (maxEdge / sampleSize > maxAllowedEdge) {
            sampleSize *= 2;
        }
        return sampleSize;
    }

    private Bitmap normalizePickedBitmap(Bitmap bitmap, int exifOrientation) {
        if (bitmap == null || bitmap.isRecycled()) {
            return null;
        }
        Bitmap rgbaBitmap = bitmap.getConfig() == Bitmap.Config.ARGB_8888
                ? bitmap
                : bitmap.copy(Bitmap.Config.ARGB_8888, false);
        if (rgbaBitmap == null) {
            return null;
        }
        if (rgbaBitmap != bitmap) {
            bitmap.recycle();
        }

        Matrix matrix = matrixForExifOrientation(exifOrientation);
        if (matrix == null || matrix.isIdentity()) {
            return rgbaBitmap;
        }
        try {
            Bitmap oriented = Bitmap.createBitmap(
                    rgbaBitmap,
                    0,
                    0,
                    rgbaBitmap.getWidth(),
                    rgbaBitmap.getHeight(),
                    matrix,
                    true);
            if (oriented != null && oriented != rgbaBitmap) {
                rgbaBitmap.recycle();
                if (oriented.getConfig() == Bitmap.Config.ARGB_8888) {
                    return oriented;
                }
                Bitmap orientedRgba = oriented.copy(Bitmap.Config.ARGB_8888, false);
                oriented.recycle();
                return orientedRgba;
            }
        } catch (Exception ignored) {
        }
        return rgbaBitmap;
    }

    private Matrix matrixForExifOrientation(int orientation) {
        Matrix matrix = new Matrix();
        switch (orientation) {
            case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
                matrix.setScale(-1f, 1f);
                break;
            case ExifInterface.ORIENTATION_ROTATE_180:
                matrix.setRotate(180f);
                break;
            case ExifInterface.ORIENTATION_FLIP_VERTICAL:
                matrix.setRotate(180f);
                matrix.postScale(-1f, 1f);
                break;
            case ExifInterface.ORIENTATION_TRANSPOSE:
                matrix.setRotate(90f);
                matrix.postScale(-1f, 1f);
                break;
            case ExifInterface.ORIENTATION_ROTATE_90:
                matrix.setRotate(90f);
                break;
            case ExifInterface.ORIENTATION_TRANSVERSE:
                matrix.setRotate(-90f);
                matrix.postScale(-1f, 1f);
                break;
            case ExifInterface.ORIENTATION_ROTATE_270:
                matrix.setRotate(-90f);
                break;
            case ExifInterface.ORIENTATION_NORMAL:
            case ExifInterface.ORIENTATION_UNDEFINED:
            default:
                break;
        }
        return matrix;
    }

    private void saveImage() {
        if (screenMode != ScreenMode.IMAGE) {
            return;
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, IMAGE_SAVE_PERMISSION_REQUEST);
            return;
        }
        final Bitmap source = sourceBitmap;
        final UyaliBeautyEngine engine = currentEngine();
        if (source == null || source.isRecycled() || engine == null) {
            Toast.makeText(this, "暂无可保存图片", Toast.LENGTH_SHORT).show();
            return;
        }
        Toast.makeText(this, "正在保存", Toast.LENGTH_SHORT).show();
        new Thread(new Runnable() {
            @Override
            public void run() {
                Bitmap output = engine.processBitmap(source);
                if (output == null) {
                    output = source.copy(Bitmap.Config.ARGB_8888, false);
                }
                final boolean saved = output != null && writeImageToGallery(output);
                if (output != null) {
                    output.recycle();
                }
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(MainActivity.this, saved ? "已保存" : "保存失败", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        }, "UyaliBeautyImageSave").start();
    }

    private boolean writeImageToGallery(Bitmap bitmap) {
        String fileName = "uyali_beauty_" + System.currentTimeMillis() + ".jpg";
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
            values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/UyaliBeauty");
            values.put(MediaStore.Images.Media.IS_PENDING, 1);
            Uri uri = getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                return false;
            }
            boolean saved = false;
            try {
                OutputStream output = getContentResolver().openOutputStream(uri);
                if (output != null) {
                    try {
                        saved = bitmap.compress(Bitmap.CompressFormat.JPEG, 95, output);
                    } finally {
                        output.close();
                    }
                }
                values.clear();
                values.put(MediaStore.Images.Media.IS_PENDING, 0);
                getContentResolver().update(uri, values, null, null);
                if (!saved) {
                    getContentResolver().delete(uri, null, null);
                }
                return saved;
            } catch (Exception error) {
                getContentResolver().delete(uri, null, null);
                return false;
            }
        }

        File dir = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "UyaliBeauty");
        if (!dir.exists() && !dir.mkdirs()) {
            return false;
        }
        File file = new File(dir, fileName);
        boolean saved = false;
        try {
            FileOutputStream output = new FileOutputStream(file);
            try {
                saved = bitmap.compress(Bitmap.CompressFormat.JPEG, 95, output);
            } finally {
                output.close();
            }
            if (!saved) {
                return false;
            }
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DATA, file.getAbsolutePath());
            values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName);
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
            getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            return true;
        } catch (Exception error) {
            return false;
        }
    }

    private void updateDebugText() {
        if (debugText == null || debugText.getVisibility() != View.VISIBLE) {
            return;
        }
        UyaliBeautyEngine engine = currentEngine();
        if (engine == null) {
            debugText.setText("");
            return;
        }
        UyaliBeautyDebugInfo info = engine.debugInfo();
        UyaliBeautyParameters p = engine.parameters();
        debugText.setText(info.renderer +
                "\n" + info.detector +
                "\nfaces sets=" + info.faceSetCount +
                " detected=" + info.detectedFaceCount +
                "\npoints face=" + info.facePointCount +
                " allFace=" + engine.latestAllFaceLandmarkPoints().size() +
                " makeup=" + info.makeupPointCount +
                " body=" + info.bodyPointCount +
                "\nlocal head=" + (p == null ? 0f : p.headReduce) +
                " face=" + (p == null ? 0f : p.faceThin) +
                " body=" + (p == null ? 0f : p.bodySlim) +
                " lip=" + (p == null ? 0f : p.makeupRouge) +
                " lipType=" + (p == null ? 0 : p.makeupRougeType) +
                "\nlicense=" + engine.getLicenseStatus() +
                " trial=" + engine.getLicenseTrialSecondsRemaining() + "s");
    }

    private void updateLandmarkOverlay() {
        if (landmarkOverlay == null) {
            return;
        }
        if (!landmarksVisible) {
            landmarkOverlay.clearPoints();
            return;
        }
        UyaliBeautyEngine engine = currentEngine();
        if (engine == null) {
            landmarkOverlay.clearPoints();
            return;
        }
        landmarkOverlay.setPreviewGeometry(previewSourceWidth, previewSourceHeight, previewMirrored, previewFitCenter);
        landmarkOverlay.setPoints(engine.latestAllFaceLandmarkPoints(),
                engine.latestMakeupLandmarkPoints(),
                engine.latestBodyLandmarkPoints());
    }

    private UyaliBeautyEngine currentEngine() {
        if ((screenMode == ScreenMode.CAMERA || screenMode == ScreenMode.IMAGE) && beautyView != null) {
            return beautyView.engine();
        }
        return null;
    }

    private void requestCurrentRender() {
        if (beautyView != null) {
            beautyView.requestBeautyRender();
        }
    }

    private int progressForParameter(String parameter, boolean signed) {
        float value = parameterValue(parameter);
        int progress = Math.round(signed ? value + 50f : value);
        return Math.max(0, Math.min(100, progress));
    }

    private float parameterValue(String parameter) {
        UyaliBeautyEngine engine = currentEngine();
        UyaliBeautyParameters p = engine == null ? null : engine.parameters();
        if (p == null) {
            return 0f;
        }
        switch (parameter) {
            case "white": return p.white;
            case "skin": return p.skin;
            case "eyeBright": return p.eyeBright;
            case "teethBright": return p.teethBright;
            case "darkCircle": return p.darkCircle;
            case "headReduce": return p.headReduce;
            case "faceThin": return p.faceThin;
            case "faceNarrow": return p.faceNarrow;
            case "faceV": return p.faceV;
            case "faceSmall": return p.faceSmall;
            case "chin": return p.chin;
            case "forehead": return p.forehead;
            case "cheekbone": return p.cheekbone;
            case "eyeBig": return p.eyeBig;
            case "eyeDistance": return p.eyeDistance;
            case "eyeCorner": return p.eyeCorner;
            case "eyelidDown": return p.eyelidDown;
            case "noseThin": return p.noseThin;
            case "noseWing": return p.noseWing;
            case "noseLong": return p.noseLong;
            case "noseRoot": return p.noseRoot;
            case "eyebrowDistance": return p.eyebrowDistance;
            case "eyebrowThin": return p.eyebrowThin;
            case "mouth": return p.mouth;
            case "bodySlim": return p.bodySlim;
            case "waistSlim": return p.waistSlim;
            case "legSlim": return p.legSlim;
            case "shoulderNarrow": return p.shoulderNarrow;
            case "armSlim": return p.armSlim;
            case "calfSlim": return p.calfSlim;
            case "abdomenSlim": return p.abdomenSlim;
            case "legLong": return p.legLong;
            case "bodyHeight": return p.bodyHeight;
            case "legShape": return p.legShape;
            case "neckLength": return p.neckLength;
            case "shoulderShape": return p.shoulderShape;
            case "makeupEyebrow": return p.makeupEyebrow;
            case "makeupEyeshadow": return p.makeupEyeshadow;
            case "makeupPupil": return p.makeupPupil;
            case "makeupBlush": return p.makeupBlush;
            case "makeupRouge": return p.makeupRouge;
            default: return 0f;
        }
    }

    private int makeupTypeForParameter(String typeName) {
        UyaliBeautyEngine engine = currentEngine();
        UyaliBeautyParameters p = engine == null ? null : engine.parameters();
        if (p == null) {
            return 0;
        }
        switch (typeName) {
            case "makeupEyebrowType": return p.makeupEyebrowType;
            case "makeupEyeshadowType": return p.makeupEyeshadowType;
            case "makeupPupilType": return p.makeupPupilType;
            case "makeupBlushType": return p.makeupBlushType;
            case "makeupRougeType": return p.makeupRougeType;
            default: return 0;
        }
    }

    private void releaseCameraSession() {
        if (cameraController != null) {
            cameraController.release();
            cameraController = null;
        }
        analysisBusy.set(false);
        if (beautyView != null) {
            beautyView.onPause();
            beautyView.release();
            beautyView = null;
        }
    }

    private void releaseImageSession() {
        sourceBitmap = null;
    }

    private boolean hasCameraPermission() {
        return checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED;
    }

    private Button makeHomeButton(String title) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(title);
        button.setTextColor(Color.BLACK);
        button.setTextSize(16f);
        button.setBackgroundColor(Color.TRANSPARENT);
        return button;
    }

    private Button makeTopButton(String title) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(title);
        button.setTextColor(0xFF4DA3FF);
        button.setTextSize(15f);
        button.setBackgroundColor(Color.TRANSPARENT);
        return button;
    }

    private Button makeSegmentButton(String title) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(title);
        button.setTextSize(14f);
        button.setPadding(0, 0, 0, 0);
        return button;
    }

    private Button makeCategoryButton(String title) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(title);
        button.setTextColor(Color.WHITE);
        button.setTextSize(15f);
        button.setBackgroundColor(Color.TRANSPARENT);
        return button;
    }

    private TextView makeValueLabel(boolean darkText) {
        TextView text = new TextView(this);
        text.setGravity(Gravity.CENTER);
        text.setTextColor(darkText ? Color.BLACK : Color.WHITE);
        text.setTextSize(15f);
        text.setText("0.0");
        return text;
    }

    private int drawableId(String name) {
        if (name == null || name.length() == 0) {
            return 0;
        }
        return getResources().getIdentifier(name, "drawable", getPackageName());
    }

    private GradientDrawable roundedBackground(int fillColor, int strokeColor, int strokeWidthDp, int radiusDp) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(fillColor);
        drawable.setCornerRadius(dp(radiusDp));
        if (strokeWidthDp > 0) {
            drawable.setStroke(dp(strokeWidthDp), strokeColor);
        }
        return drawable;
    }

    private String displayValue(int progress, boolean signed) {
        return signed ? String.format("%.1f", progress - 50f) : String.format("%.1f", (float) progress);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private static int normalizeDegrees(int degrees) {
        int value = degrees % 360;
        return value < 0 ? value + 360 : value;
    }

    private static final class Feature {
        final String name;
        final String icon;
        final String parameter;
        final boolean signed;

        Feature(String name, String icon, String parameter, boolean signed) {
            this.name = name;
            this.icon = icon;
            this.parameter = parameter;
            this.signed = signed;
        }
    }

    private static final class MakeupGroup {
        final String name;
        final String icon;
        final String parameter;
        final String typeParameter;
        final String[] itemNames;
        final String[] itemIcons;
        final int[] typeValues;

        MakeupGroup(String name,
                    String icon,
                    String parameter,
                    String typeParameter,
                    String[] itemNames,
                    String[] itemIcons,
                    int[] typeValues) {
            this.name = name;
            this.icon = icon;
            this.parameter = parameter;
            this.typeParameter = typeParameter;
            this.itemNames = itemNames;
            this.itemIcons = itemIcons;
            this.typeValues = typeValues;
        }
    }

    private static final class LandmarkOverlayView extends View {
        private final Paint facePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint makeupPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint bodyPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final ArrayList<UyaliBeautyPoint> facePoints = new ArrayList<>();
        private final ArrayList<UyaliBeautyPoint> makeupPoints = new ArrayList<>();
        private final ArrayList<UyaliBeautyPoint> bodyPoints = new ArrayList<>();
        private int sourceWidth;
        private int sourceHeight;
        private boolean mirrored;
        private boolean fitCenter;

        LandmarkOverlayView(Activity activity) {
            super(activity);
            setWillNotDraw(false);
            setClickable(false);
            facePaint.setColor(0xFFFFD54F);
            makeupPaint.setColor(0xFF4FC3F7);
            bodyPaint.setColor(0xFFFF5C8A);
        }

        void setPreviewGeometry(int width, int height, boolean mirrored, boolean fitCenter) {
            sourceWidth = width;
            sourceHeight = height;
            this.mirrored = mirrored;
            this.fitCenter = fitCenter;
            invalidate();
        }

        void setPoints(List<UyaliBeautyPoint> face, List<UyaliBeautyPoint> makeup, List<UyaliBeautyPoint> body) {
            replace(facePoints, face);
            replace(makeupPoints, makeup);
            replace(bodyPoints, body);
            invalidate();
        }

        void clearPoints() {
            if (facePoints.isEmpty() && makeupPoints.isEmpty() && bodyPoints.isEmpty()) {
                return;
            }
            facePoints.clear();
            makeupPoints.clear();
            bodyPoints.clear();
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            drawPoints(canvas, bodyPoints, bodyPaint, 3.2f);
            drawPoints(canvas, makeupPoints, makeupPaint, 2.4f);
            drawPoints(canvas, facePoints, facePaint, 2.8f);
        }

        private void drawPoints(Canvas canvas, List<UyaliBeautyPoint> points, Paint paint, float radiusDp) {
            if (points.isEmpty()) {
                return;
            }
            float radius = radiusDp * getResources().getDisplayMetrics().density;
            for (UyaliBeautyPoint point : points) {
                float[] mapped = mapPoint(point.x, point.y);
                if (mapped == null) {
                    continue;
                }
                canvas.drawCircle(mapped[0], mapped[1], radius, paint);
            }
        }

        private float[] mapPoint(float x, float y) {
            if (!Float.isFinite(x) || !Float.isFinite(y) ||
                    x < -0.15f || x > 1.15f || y < -0.15f || y > 1.15f ||
                    (Math.abs(x) < 0.0001f && Math.abs(y) < 0.0001f)) {
                return null;
            }
            if (mirrored) {
                x = 1.0f - x;
            }

            int viewWidth = getWidth();
            int viewHeight = getHeight();
            if (viewWidth <= 0 || viewHeight <= 0) {
                return null;
            }
            float srcWidth = sourceWidth > 0 ? sourceWidth : viewWidth;
            float srcHeight = sourceHeight > 0 ? sourceHeight : viewHeight;
            float sourceAspect = srcWidth / Math.max(srcHeight, 1.0f);
            float outputAspect = viewWidth / Math.max((float) viewHeight, 1.0f);
            if (fitCenter) {
                float drawWidth = viewWidth;
                float drawHeight = viewHeight;
                float offsetX = 0.0f;
                float offsetY = 0.0f;
                if (sourceAspect > outputAspect) {
                    drawHeight = viewWidth / Math.max(sourceAspect, 0.0001f);
                    offsetY = (viewHeight - drawHeight) * 0.5f;
                } else {
                    drawWidth = viewHeight * sourceAspect;
                    offsetX = (viewWidth - drawWidth) * 0.5f;
                }
                return new float[]{offsetX + x * drawWidth, offsetY + y * drawHeight};
            }
            float scaleX = 1.0f;
            float scaleY = 1.0f;
            float offsetX = 0.0f;
            float offsetY = 0.0f;
            if (sourceAspect > outputAspect) {
                scaleX = outputAspect / sourceAspect;
                offsetX = (1.0f - scaleX) * 0.5f;
            } else {
                scaleY = sourceAspect / outputAspect;
                offsetY = (1.0f - scaleY) * 0.5f;
            }

            float sourceBottomX = x;
            float sourceBottomY = 1.0f - y;
            float screenBottomX = (sourceBottomX - offsetX) / Math.max(scaleX, 0.0001f);
            float screenBottomY = (sourceBottomY - offsetY) / Math.max(scaleY, 0.0001f);
            if (screenBottomX < 0.0f || screenBottomX > 1.0f ||
                    screenBottomY < 0.0f || screenBottomY > 1.0f) {
                return null;
            }
            return new float[]{screenBottomX * viewWidth, (1.0f - screenBottomY) * viewHeight};
        }

        private static void replace(ArrayList<UyaliBeautyPoint> target, List<UyaliBeautyPoint> source) {
            target.clear();
            if (source != null) {
                target.addAll(source);
            }
        }
    }

    private final class IconTextButton extends LinearLayout {
        private final ImageView iconView;
        private final TextView label;
        private final boolean darkText;

        IconTextButton(String title, String iconName, boolean darkText) {
            super(MainActivity.this);
            this.darkText = darkText;
            setOrientation(VERTICAL);
            setGravity(Gravity.CENTER);
            setPadding(dp(3), dp(3), dp(3), dp(3));
            setClickable(true);
            setFocusable(true);

            iconView = new ImageView(MainActivity.this);
            iconView.setScaleType(ImageView.ScaleType.FIT_CENTER);
            int resId = drawableId(iconName);
            if (resId != 0) {
                iconView.setImageResource(resId);
            } else {
                iconView.setVisibility(View.INVISIBLE);
            }
            addView(iconView, new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    0,
                    1f));

            label = new TextView(MainActivity.this);
            label.setGravity(Gravity.CENTER);
            label.setSingleLine(true);
            label.setText(title);
            label.setTextSize(11f);
            addView(label, new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(20)));
        }

        void setActive(boolean active) {
            int fill;
            int stroke;
            int text;
            if (darkText) {
                fill = active ? 0xFFEAF3FF : Color.TRANSPARENT;
                stroke = active ? 0xFF4DA3FF : Color.TRANSPARENT;
                text = active ? 0xFF1473E6 : Color.BLACK;
            } else {
                fill = active ? 0x66000000 : 0x66FFFFFF;
                stroke = Color.TRANSPARENT;
                text = active ? 0xFF4DA3FF : Color.WHITE;
            }
            setBackground(roundedBackground(fill, stroke, active ? 2 : 0, 32));
            label.setTextColor(text);
            iconView.setAlpha(active ? 1f : 0.88f);
        }
    }
}
