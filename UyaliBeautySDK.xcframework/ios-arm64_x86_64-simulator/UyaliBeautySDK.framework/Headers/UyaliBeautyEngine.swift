//
//  UyaliBeautyEngine.swift
//  美颜测试
//
//  Created by S weet on 2023/2/15.
//

import UIKit
import CoreMedia
import GLKit
import VideoToolbox

/// UyaliBeauty SDK 主入口。
/// Main entry point of the UyaliBeauty SDK.
public class UyaliBeautyEngine: NSObject {
    private let licenseController = UyaliBeautyLicenseController()

    /// 美颜处理器。
    /// Internal beauty processor.
    private var processor = BeautyProcessor()

    /// 当前 License 状态。
    /// Current license status.
    @objc public var licenseStatus: UyaliBeautyLicenseStatus {
        return licenseController.result.status
    }

    /// 当前 License 状态说明。
    /// Human-readable message for the current license status.
    @objc public var licenseMessage: String {
        return licenseController.result.message
    }

    /// 本次会话剩余试用秒数。
    /// Remaining trial seconds for the current session.
    @objc public var licenseTrialSecondsRemaining: TimeInterval {
        return licenseController.trialSecondsRemaining()
    }

    /// 当前渲染是否需要显示试用水印。
    /// Whether the current rendering should display a trial watermark.
    @objc public var licenseRequiresWatermark: Bool {
        return licenseController.requiresWatermark()
    }

    /// 使用 License 字符串激活 SDK。
    /// Activates the SDK with a license string.
    @objc public func activateLicense(_ licenseString: String) -> UyaliBeautyLicenseResult {
        return licenseController.activate(licenseString: licenseString)
    }

    /// 从本地文件加载并激活 License。
    /// Loads and activates a license from a local file.
    @objc public func loadLicense(at fileURL: URL) -> UyaliBeautyLicenseResult {
        return licenseController.loadLicense(at: fileURL)
    }

    /// 查询当前 License 是否允许使用指定功能。
    /// Returns whether the current license allows the specified feature.
    @objc public func canUseFeature(_ feature: UyaliBeautyFeature) -> Bool {
        return licenseController.canUse(feature)
    }
    
    /// 是否启用人体轮廓调试输出。
    /// Enables body contour debug output.
    @objc public var bodyContourDebugEnabled: Bool = false {
        didSet {
            processor.bodyContourDebugEnabled = bodyContourDebugEnabled
        }
    }

    /// 静态图片处理时是否复用上一帧人体姿态结果。
    /// Reuses the previous body pose result when processing static images.
    @objc public var staticImageBodyPoseReuseEnabled: Bool = false {
        didSet {
            processor.staticImageBodyPoseReuseEnabled = staticImageBodyPoseReuseEnabled
        }
    }

    /// 是否启用人脸轮廓调试输出。
    /// Enables face contour debug output.
    @objc public var faceContourDebugEnabled: Bool = false {
        didSet {
            processor.faceContourDebugEnabled = faceContourDebugEnabled
        }
    }
    
    /// 最近一次检测到的人脸轮廓点。
    /// Face contour points from the latest detection.
    @objc public var latestFaceContourPoints: [NSValue] {
        return processor.latestFaceContourPoints
    }

    /// 最近一次检测到的人脸关键点。
    /// Face landmark points from the latest detection.
    @objc public var latestFaceLandmarkPoints: [NSValue] {
        return processor.latestFaceLandmarkPoints
    }

    /// 最近一次检测到的人脸关键点标签。
    /// Face landmark labels from the latest detection.
    @objc public var latestFaceLandmarkLabels: [NSNumber] {
        return processor.latestFaceLandmarkLabels
    }
    
    /// 最近一次检测到的人脸轮廓标签。
    /// Face contour labels from the latest detection.
    @objc public var latestFaceContourLabels: [NSNumber] {
        return processor.latestFaceContourLabels
    }
    
    /// 最近一次人脸轮廓调试信息。
    /// Face contour debug information from the latest detection.
    @objc public var latestFaceContourDebugInfo: String {
        return processor.latestFaceContourDebugInfo
    }
    
    /// 最近一次检测到的人体轮廓点。
    /// Body contour points from the latest detection.
    @objc public var latestBodyContourPoints: [NSValue] {
        return processor.latestBodyContourPoints
    }
    
    /// 最近一次检测到的人体分部轮廓点。
    /// Body-part contour points from the latest detection.
    @objc public var latestBodyPartContourPoints: [NSValue] {
        return processor.latestBodyPartContourPoints
    }
    
    /// 最近一次检测到的人体分部轮廓标签。
    /// Body-part contour labels from the latest detection.
    @objc public var latestBodyPartContourLabels: [NSNumber] {
        return processor.latestBodyPartContourLabels
    }
    
    /// 最近一次检测到的人体关键点。
    /// Body landmark points from the latest detection.
    @objc public var latestBodyLandmarkPoints: [NSValue] {
        return processor.latestBodyLandmarkPoints
    }
    
    /// 最近一次人体轮廓调试信息。
    /// Body contour debug information from the latest detection.
    @objc public var latestBodyContourDebugInfo: String {
        return processor.latestBodyContourDebugInfo
    }
    
    // MARK: - 美型参数 / Face Reshape Parameters
    /// 小头，参数范围：0.0 - 100.0。
    /// Head reduction amount. Range: 0.0 - 100.0.
    @objc public var headReduce_delta: Float = 0.0 {
        didSet {
            processor.headReduce_delta = headReduce_delta
        }
    }
    
    /// 瘦脸，参数范围：0.0 - 100.0。
    /// Face slimming amount. Range: 0.0 - 100.0.
    @objc public var faceThin_delta: Float = 0.0 {
        didSet {
            processor.faceThin_delta = faceThin_delta
        }
    }
    
    /// 窄脸，参数范围：0.0 - 100.0。
    /// Face narrowing amount. Range: 0.0 - 100.0.
    @objc public var faceNarrow_delta: Float = 0.0 {
        didSet {
            processor.faceNarrow_delta = faceNarrow_delta
        }
    }
    
    /// V脸，参数范围：0.0 - 100.0。
    /// V-line face amount. Range: 0.0 - 100.0.
    @objc public var faceV_delta: Float = 0.0 {
        didSet {
            processor.faceV_delta = faceV_delta
        }
    }
    
    /// 小脸，参数范围：0.0 - 100.0。
    /// Small face amount. Range: 0.0 - 100.0.
    @objc public var faceSmall_delta: Float = 0.0 {
        didSet {
            processor.faceSmall_delta = faceSmall_delta
        }
    }
    
    /// 下巴，参数范围：-50.0 - 50.0。
    /// Chin adjustment amount. Range: -50.0 - 50.0.
    @objc public var chin_delta: Float = 0.0 {
        didSet {
            processor.chin_delta = chin_delta
        }
    }
    
    /// 额头，参数范围：-50.0 - 50.0。
    /// Forehead adjustment amount. Range: -50.0 - 50.0.
    @objc public var forehead_delta: Float = 0.0 {
        didSet {
            processor.forehead_delta = forehead_delta
        }
    }
    
    /// 颧骨，参数范围：-50.0 - 50.0。
    /// Cheekbone adjustment amount. Range: -50.0 - 50.0.
    @objc public var cheekbone_delta: Float = 0.0 {
        didSet {
            processor.cheekbone_delta = cheekbone_delta
        }
    }
    
    /// 大眼，参数范围：0.0 - 100.0。
    /// Eye enlargement amount. Range: 0.0 - 100.0.
    @objc public var eyeBig_delta: Float = 0.0 {
        didSet {
            processor.eyeBig_delta = eyeBig_delta
        }
    }
    
    /// 眼距，参数范围：-50.0 - 50.0。
    /// Eye distance adjustment amount. Range: -50.0 - 50.0.
    @objc public var eyeDistance_delta: Float = 0.0 {
        didSet {
            processor.eyeDistance_delta = eyeDistance_delta
        }
    }
    
    /// 内眼角，参数范围：0.0 - 100.0。
    /// Inner eye-corner adjustment amount. Range: 0.0 - 100.0.
    @objc public var eyeCorner_delta: Float = 0.0 {
        didSet {
            processor.eyeCorner_delta = eyeCorner_delta
        }
    }
    
    /// 眼睑下至，参数范围：0.0 - 100.0。
    /// Lower eyelid adjustment amount. Range: 0.0 - 100.0.
    @objc public var eyelidDown_delta: Float = 0.0 {
        didSet {
            processor.eyelidDown_delta = eyelidDown_delta
        }
    }
    
    /// 瘦鼻，参数范围：0.0 - 100.0。
    /// Nose slimming amount. Range: 0.0 - 100.0.
    @objc public var noseThin_delta: Float = 0.0 {
        didSet {
            processor.noseThin_delta = noseThin_delta
        }
    }
    
    /// 鼻翼，参数范围：0.0 - 100.0。
    /// Nose wing adjustment amount. Range: 0.0 - 100.0.
    @objc public var noseWing_delta: Float = 0.0 {
        didSet {
            processor.noseWing_delta = noseWing_delta
        }
    }
    
    /// 长鼻，参数范围：-50.0 - 50.0。
    /// Nose length adjustment amount. Range: -50.0 - 50.0.
    @objc public var noseLong_delta: Float = 0.0 {
        didSet {
            processor.noseLong_delta = noseLong_delta
        }
    }
    
    /// 山根，参数范围：0.0 - 100.0。
    /// Nose bridge/root adjustment amount. Range: 0.0 - 100.0.
    @objc public var noseRoot_delta: Float = 0.0 {
        didSet {
            processor.noseRoot_delta = noseRoot_delta
        }
    }
    
    /// 眉间距，参数范围：-50.0 - 50.0。
    /// Eyebrow distance adjustment amount. Range: -50.0 - 50.0.
    @objc public var eyebrowDistance_delta: Float = 0.0 {
        didSet {
            processor.eyebrowDistance_delta = eyebrowDistance_delta
        }
    }
    
    /// 眉粗细，参数范围：-50.0 - 50.0。
    /// Eyebrow thickness adjustment amount. Range: -50.0 - 50.0.
    @objc public var eyebrowThin_delta: Float = 0.0 {
        didSet {
            processor.eyebrowThin_delta = eyebrowThin_delta
        }
    }
    
    /// 嘴型，参数范围：-50.0 - 50.0。
    /// Mouth shape adjustment amount. Range: -50.0 - 50.0.
    @objc public var mouth_delta: Float = 0.0 {
        didSet {
            processor.mouth_delta = mouth_delta
        }
    }

    // MARK: - 美体参数 / Body Reshape Parameters
    /// 瘦身，参数范围：0.0 - 100.0。
    /// Body slimming amount. Range: 0.0 - 100.0.
    @objc public var bodySlim_delta: Float = 0.0 {
        didSet {
            processor.bodySlim_delta = bodySlim_delta
        }
    }

    /// 瘦腰，参数范围：0.0 - 100.0。
    /// Waist slimming amount. Range: 0.0 - 100.0.
    @objc public var waistSlim_delta: Float = 0.0 {
        didSet {
            processor.waistSlim_delta = waistSlim_delta
        }
    }

    /// 瘦腿，参数范围：0.0 - 100.0。
    /// Leg slimming amount. Range: 0.0 - 100.0.
    @objc public var legSlim_delta: Float = 0.0 {
        didSet {
            processor.legSlim_delta = legSlim_delta
        }
    }

    /// 窄肩，参数范围：0.0 - 100.0。
    /// Shoulder narrowing amount. Range: 0.0 - 100.0.
    @objc public var shoulderNarrow_delta: Float = 0.0 {
        didSet {
            processor.shoulderNarrow_delta = shoulderNarrow_delta
        }
    }

    /// 瘦手臂，参数范围：0.0 - 100.0。
    /// Arm slimming amount. Range: 0.0 - 100.0.
    @objc public var armSlim_delta: Float = 0.0 {
        didSet {
            processor.armSlim_delta = armSlim_delta
        }
    }

    /// 小腿修饰，参数范围：0.0 - 100.0。
    /// Calf refinement amount. Range: 0.0 - 100.0.
    @objc public var calfSlim_delta: Float = 0.0 {
        didSet {
            processor.calfSlim_delta = calfSlim_delta
        }
    }

    /// 收腹，参数范围：0.0 - 100.0。
    /// Abdomen slimming amount. Range: 0.0 - 100.0.
    @objc public var abdomenSlim_delta: Float = 0.0 {
        didSet {
            processor.abdomenSlim_delta = abdomenSlim_delta
        }
    }

    /// 长腿，参数范围：0.0 - 100.0。
    /// Leg lengthening amount. Range: 0.0 - 100.0.
    @objc public var legLong_delta: Float = 0.0 {
        didSet {
            processor.legLong_delta = legLong_delta
        }
    }

    /// 增高，参数范围：0.0 - 100.0。
    /// Height enhancement amount. Range: 0.0 - 100.0.
    @objc public var bodyHeight_delta: Float = 0.0 {
        didSet {
            processor.bodyHeight_delta = bodyHeight_delta
        }
    }

    /// 腿型矫正，参数范围：0.0 - 100.0。
    /// Leg shape correction amount. Range: 0.0 - 100.0.
    @objc public var legShape_delta: Float = 0.0 {
        didSet {
            processor.legShape_delta = legShape_delta
        }
    }

    /// 天鹅颈，参数范围：0.0 - 100.0。
    /// Neck lengthening amount. Range: 0.0 - 100.0.
    @objc public var neckLength_delta: Float = 0.0 {
        didSet {
            processor.neckLength_delta = neckLength_delta
        }
    }

    /// 直角肩，参数范围：0.0 - 100.0。
    /// Shoulder shaping amount. Range: 0.0 - 100.0.
    @objc public var shoulderShape_delta: Float = 0.0 {
        didSet {
            processor.shoulderShape_delta = shoulderShape_delta
        }
    }
    
    // MARK: - 美颜参数 / Beauty Parameters
    /// 美白，参数范围：0.0 - 100.0。
    /// Skin whitening amount. Range: 0.0 - 100.0.
    @objc public var white_delta: Float = 0.0 {
        didSet {
            processor.white_delta = white_delta
        }
    }
    
    /// 磨皮，参数范围：0.0 - 100.0。
    /// Skin smoothing amount. Range: 0.0 - 100.0.
    @objc public var skin_delta: Float = 0.0 {
        didSet {
            processor.skin_delta = skin_delta
        }
    }
    
    /// 亮眼，参数范围：0.0 - 100.0。
    /// Eye brightening amount. Range: 0.0 - 100.0.
    @objc public var eyeBright_delta: Float = 0.0 {
        didSet {
            processor.eyeBright_delta = eyeBright_delta
        }
    }
    
    /// 白牙，参数范围：0.0 - 100.0。
    /// Teeth whitening amount. Range: 0.0 - 100.0.
    @objc public var teethBright_delta: Float = 0.0 {
        didSet {
            processor.teethBright_delta = teethBright_delta
        }
    }

    /// 去黑眼圈，参数范围：0.0 - 100.0。
    /// Dark-circle reduction amount. Range: 0.0 - 100.0.
    @objc public var darkCircle_delta: Float = 0.0 {
        didSet {
            processor.darkCircle_delta = darkCircle_delta
        }
    }

    /// 法令纹功能已移除，保留参数仅用于兼容旧调用。
    /// Nasolabial fold removal has been removed; this parameter is kept only for backward compatibility.
    @objc public var nasolabialFold_delta: Float = 0.0 {
        didSet {
            processor.nasolabialFold_delta = nasolabialFold_delta
        }
    }
    
    // MARK: - 美妆参数 / Makeup Parameters
    /// 眉毛强度，参数范围：0.0 - 100.0。
    /// Eyebrow makeup intensity. Range: 0.0 - 100.0.
    @objc public var makeup_eyebrow_delta: Float = 0.0 {
        didSet {
            processor.makeup_eyebrow_delta = makeup_eyebrow_delta
        }
    }
    /// 眉毛类型。
    /// Eyebrow makeup type.
    @objc public var makeup_eyebrow_type: MakeupEyebrowType = .eyebrow_none {
        didSet {
            processor.makeup_eyebrow_type = makeup_eyebrow_type
        }
    }
    
    /// 眼妆强度，参数范围：0.0 - 100.0。
    /// Eyeshadow makeup intensity. Range: 0.0 - 100.0.
    @objc public var makeup_eyeshadow_delta: Float = 0.0 {
        didSet {
            processor.makeup_eyeshadow_delta = makeup_eyeshadow_delta
        }
    }
    /// 眼妆类型。
    /// Eyeshadow makeup type.
    @objc public var makeup_eyeshadow_type: MakeupEyeshadowType = .eyeshadow_none {
        didSet {
            processor.makeup_eyeshadow_type = makeup_eyeshadow_type
        }
    }
    
    /// 美瞳强度，参数范围：0.0 - 100.0。
    /// Colored contact lens intensity. Range: 0.0 - 100.0.
    @objc public var makeup_pupil_delta: Float = 0.0 {
        didSet {
            processor.makeup_pupil_delta = makeup_pupil_delta
        }
    }
    /// 美瞳类型。
    /// Colored contact lens type.
    @objc public var makeup_pupil_type: MakeupPupilType = .pupil_none {
        didSet {
            processor.makeup_pupil_type = makeup_pupil_type
        }
    }
    
    /// 腮红强度，参数范围：0.0 - 100.0。
    /// Blush makeup intensity. Range: 0.0 - 100.0.
    @objc public var makeup_blush_delta: Float = 0.0 {
        didSet {
            processor.makeup_blush_delta = makeup_blush_delta
        }
    }
    /// 腮红类型。
    /// Blush makeup type.
    @objc public var makeup_blush_type: MakeupBlushType = .blush_none {
        didSet {
            processor.makeup_blush_type = makeup_blush_type
        }
    }
    
    /// 口红强度，参数范围：0.0 - 100.0。
    /// Lipstick makeup intensity. Range: 0.0 - 100.0.
    @objc public var makeup_rouge_delta: Float = 0.0 {
        didSet {
            processor.makeup_rouge_delta = makeup_rouge_delta
        }
    }
    /// 口红类型。
    /// Lipstick makeup type.
    @objc public var makeup_rouge_type: MakeupRougeType = .rouge_none {
        didSet {
            processor.makeup_rouge_type = makeup_rouge_type
        }
    }
    
    /// 创建 UyaliBeauty 引擎实例。
    /// Creates a UyaliBeauty engine instance.
    @objc public override init() {
        super.init()
        processor.licenseController = licenseController
    }
    
    // MARK: - CVPixelBuffer 处理 / CVPixelBuffer Processing
    /// 直接在传入的 CVPixelBuffer 上处理图像，当前仅支持 RGBA 格式。
    /// Processes the input CVPixelBuffer in place. Currently supports RGBA format only.
    @objc public func process(pixelBuffer:CVPixelBuffer) {
        processor.filter(pixelBuffer: pixelBuffer)
    }
    
    /// 处理传入的 CVPixelBuffer 并返回输出图像。
    /// Processes the input CVPixelBuffer and returns the output pixel buffer.
    @objc public func processWithOutput(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        return processor.filterWithOutput(pixelBuffer: pixelBuffer)
    }
    
    // MARK: - 重置 / Reset
    /// 重置所有滤镜参数。
    /// Resets all filter parameters.
    @objc public func resetAllFilters() {
        //美型参数
        headReduce_delta = 0.0
        faceThin_delta = 0.0
        faceNarrow_delta = 0.0
        faceV_delta = 0.0
        faceSmall_delta = 0.0
        chin_delta = 0.0
        forehead_delta = 0.0
        cheekbone_delta = 0.0
        eyeBig_delta = 0.0
        eyeDistance_delta = 0.0
        eyeCorner_delta = 0.0
        eyelidDown_delta = 0.0
        noseThin_delta = 0.0
        noseWing_delta = 0.0
        noseLong_delta = 0.0
        noseRoot_delta = 0.0
        eyebrowDistance_delta = 0.0
        eyebrowThin_delta = 0.0
        mouth_delta = 0.0
        //美体参数
        bodySlim_delta = 0.0
        waistSlim_delta = 0.0
        legSlim_delta = 0.0
        shoulderNarrow_delta = 0.0
        armSlim_delta = 0.0
        calfSlim_delta = 0.0
        abdomenSlim_delta = 0.0
        legLong_delta = 0.0
        bodyHeight_delta = 0.0
        legShape_delta = 0.0
        neckLength_delta = 0.0
        shoulderShape_delta = 0.0
        //美颜参数
        white_delta = 0.0
        skin_delta = 0.0
        eyeBright_delta = 0.0
        teethBright_delta = 0.0
        darkCircle_delta = 0.0
        nasolabialFold_delta = 0.0
        //美妆参数
        makeup_eyebrow_delta = 0.0
        makeup_eyebrow_type = .eyebrow_none
        makeup_eyeshadow_delta = 0.0
        makeup_eyeshadow_type = .eyeshadow_none
        makeup_pupil_delta = 0.0
        makeup_pupil_type = .pupil_none
        makeup_blush_delta = 0.0
        makeup_blush_type = .blush_none
        makeup_rouge_delta = 0.0
        makeup_rouge_type = .rouge_none
    }
}
