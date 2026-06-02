//
//  BeautyFilterController.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/2/16.
//

import UIKit
import UyaliBeautySDK
import Accelerate.vImage

public let kScreenWidth = UIScreen.main.bounds.width
public let kScreenHeight = UIScreen.main.bounds.height
public let kstatusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height

public func kIsIpnoneX() -> Bool {
    if (Int)((kScreenHeight/kScreenWidth)*100) == 216 {
        return true
    }
    else {
        return false
    }
}

class BeautyFilterController: UIViewController,PFCameraDelegate,FaceReshapeDelegate,FaceBeautyDelegate,FaceMakeupDelegate {
    
    private var camera: PFCamera!
    private var openGLView: PFOpenGLView!
    private var contourDebugView: BodyContourDebugView!
    
    private var beautyFilterView : UIView!
    private var reshapeView : FaceReshapeView!
    private var bodyView : FaceReshapeView!
    private var beautyView: FaceBeautyView!
    private var makeupView: FaceMakeupView!
    
    private let filter = UyaliBeautyEngine()
    private lazy var previewCropContext = CIContext(options: [CIContextOption.cacheIntermediates: false])
    
    private var isFront = true
    private let cameraPreviewRatio: CGFloat = 9.0 / 16.0
    private var lastContourDebugUpdateTime: CFTimeInterval = 0
    private var isFaceLandmarkDebugEnabled = false
    private var currentShow = 0 {
        didSet {
            if oldValue == 0 {
                showFilterPanel(currentShow)
            } else if oldValue == currentShow {//当选择了当前展示的滤镜集合时，只需要弹回即可
                hideFilterPanel(currentShow)
                currentShow = 0
            } else if oldValue != currentShow {//当选择了和当前展示的滤镜集合不同的滤镜集合时，弹回展示的滤镜集合并弹出选择的滤镜集合
                showFilterPanel(currentShow)
                hideFilterPanel(oldValue)
            }
            
        }
    }

    private func panelView(for tag: Int) -> UIView? {
        if tag == 1000 {
            return beautyView
        } else if tag == 1001 {
            return reshapeView
        } else if tag == 1002 {
            return bodyView
        } else if tag == 1003 {
            return makeupView
        }
        return nil
    }

    private func showFilterPanel(_ tag: Int) {
        guard let panel = panelView(for: tag) else { return }
        panel.isHidden = false
        UIView.animate(withDuration: 0.15) {
            panel.frame = CGRect(x: 0, y: panel.frame.origin.y-panel.frame.height, width: panel.frame.width, height: panel.frame.height)
            panel.alpha = 1
        }
    }

    private func hideFilterPanel(_ tag: Int) {
        guard let panel = panelView(for: tag) else { return }
        UIView.animate(withDuration: 0.15) { [self] in
            panel.frame = CGRect(x: 0, y: beautyFilterView.frame.origin.y, width: panel.frame.width, height: panel.frame.height)
            panel.alpha = 0
        } completion: { _ in
            panel.isHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var bottomHeight = 0.0
        if kIsIpnoneX() {
            bottomHeight = 34.0
        }
        camera = PFCamera()
        camera.delegate = self
        
        let previewWidth = kScreenWidth
        let previewHeight = previewWidth / cameraPreviewRatio
        openGLView = PFOpenGLView(frame: CGRect(x: 0, y: kScreenHeight/2-previewHeight/2, width: previewWidth, height: previewHeight), context: EAGLContext(api: .openGLES3)!)
        view.addSubview(openGLView)
        contourDebugView = BodyContourDebugView(frame: openGLView.frame)
        contourDebugView.isHidden = true
        view.addSubview(contourDebugView)
        filter.faceContourDebugEnabled = false
        filter.bodyContourDebugEnabled = false
        camera.startCapture()
        
        let closeButton = UIButton(frame: CGRect(x: 8, y: 60, width: 50, height: 50))
        view.addSubview(closeButton)
        closeButton .setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        
        let change = UIButton(frame: CGRect(x: kScreenWidth-58, y: 60, width: 50, height: 50))
        view.addSubview(change)
        change.setTitle("切换", for: .normal)
        change.setTitleColor(.systemBlue, for: .normal)
        change.addTarget(self, action: #selector(changeAction), for: .touchUpInside)

        beautyFilterView = UIView(frame: CGRect(x: 0, y: kScreenHeight-50.0-bottomHeight, width: kScreenWidth, height: 50.0+bottomHeight))
        view.addSubview(beautyFilterView)
        beautyFilterView.backgroundColor = .black.withAlphaComponent(0.4)
        
        let items = ["美颜","美型","美体","美妆"]
        for i in 0..<items.count {
            let button = UIButton(frame: CGRect(x: kScreenWidth/CGFloat(items.count)*CGFloat(i), y: 0, width: kScreenWidth/CGFloat(items.count), height: 50.0))
            beautyFilterView.addSubview(button)
            button.setTitle(items[i], for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: #selector(itemButtonAction(button:)), for: .touchUpInside)
            button.tag = 1000+i
        }
        
        //Reshape View
        reshapeView = FaceReshapeView(frame: CGRect(x: 0, y: beautyFilterView.frame.origin.y, width: kScreenWidth, height: 130.0))
        view.addSubview(reshapeView)
        reshapeView.alpha = 0
        reshapeView.isHidden = true
        reshapeView.delegate = self
        
        //Body Reshape View
        bodyView = FaceReshapeView(frame: reshapeView.frame, mode: .body)
        view.addSubview(bodyView)
        bodyView.alpha = 0
        bodyView.isHidden = true
        bodyView.delegate = self
        
        //Beauty View
        beautyView = FaceBeautyView(frame: reshapeView.frame)
        view.addSubview(beautyView)
        beautyView.alpha = 0
        beautyView.isHidden = true
        beautyView.delegate = self
        
        makeupView = FaceMakeupView(frame: reshapeView.frame)
        view.addSubview(makeupView)
        makeupView.alpha = 0
        makeupView.isHidden = true
        makeupView.delegate = self
        
        let line = UIView(frame: CGRect(x: 0, y: kScreenHeight-50.0-bottomHeight, width: kScreenWidth, height: 1.0))
        view.addSubview(line)
        line.backgroundColor = .white
    }
    
    //MARK: Camera Delegate
    func didOutputVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {
        guard let sampleBuffer = sampleBuffer,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let openGLView = openGLView else {
            return
        }
        
        
        resizePixelBuffer(pixelBuffer: pixelBuffer, ratio: cameraPreviewRatio)
        
        filter.process(pixelBuffer: pixelBuffer)
        
        openGLView.display(pixelBuffer)
        updateContourDebugOverlayIfNeeded()
    }

    private func updateContourDebugOverlayIfNeeded(force: Bool = false) {
        let now = CACurrentMediaTime()
        guard force || now - lastContourDebugUpdateTime > 0.2 else { return }
        lastContourDebugUpdateTime = now

        let facePoints = filter.latestFaceContourPoints.map { $0.cgPointValue }
        let faceLabels = filter.latestFaceContourLabels.map { $0.intValue }
        let faceLandmarkPoints = filter.debugFaceLandmarkPoints.map { $0.cgPointValue }
        let faceLandmarkLabels = filter.debugFaceLandmarkLabels.map { $0.intValue }
        let faceDebugInfo = filter.latestFaceContourDebugInfo
        let bodyPoints = filter.latestBodyContourPoints.map { $0.cgPointValue }
        let partPoints = filter.latestBodyPartContourPoints.map { $0.cgPointValue }
        let partLabels = filter.latestBodyPartContourLabels.map { $0.intValue }
        let posePoints = filter.latestBodyLandmarkPoints.map { $0.cgPointValue }
        let bodyDebugInfo = filter.latestBodyContourDebugInfo
        DispatchQueue.main.async { [weak self] in
            self?.contourDebugView.facePoints = facePoints
            self?.contourDebugView.faceLabels = faceLabels
            self?.contourDebugView.faceLandmarkPoints = faceLandmarkPoints
            self?.contourDebugView.faceLandmarkLabels = faceLandmarkLabels
            self?.contourDebugView.faceDebugInfo = faceDebugInfo
            self?.contourDebugView.points = bodyPoints
            self?.contourDebugView.partPoints = partPoints
            self?.contourDebugView.partLabels = partLabels
            self?.contourDebugView.posePoints = posePoints
            self?.contourDebugView.debugInfo = bodyDebugInfo
        }
    }
    
    //MARK: Reshape Delegate
    //在切换滤镜时，将当前滤镜的参数赋值给Slider
    func changeReshapeType(type: Int) {
        let targetView = type >= 119 ? bodyView! : reshapeView!
        if type == 100 {//小头 参数范围：0 - 100
            targetView.slider.value = filter.headReduce_delta
        } else if type == 101 {//瘦脸 参数范围：0 - 100
            targetView.slider.value = filter.faceThin_delta
        } else if type == 102 {//窄脸 参数范围：0 - 100
            targetView.slider.value = filter.faceNarrow_delta
        } else if type == 103 {//V脸 参数范围：0 - 100
            targetView.slider.value = filter.faceV_delta
        } else if type == 104 {//小脸 参数范围：0 - 100
            targetView.slider.value = filter.faceSmall_delta
        } else if type == 105 {//下巴 参数范围：-50 - 50
            targetView.slider.value = filter.chin_delta
        } else if type == 106 {//额头 参数范围：-50 - 50
            targetView.slider.value = filter.forehead_delta
        } else if type == 107 {//颧骨 参数范围：-50 - 50
            targetView.slider.value = filter.cheekbone_delta
        } else if type == 108 {//大眼 参数范围：0 - 100
            targetView.slider.value = filter.eyeBig_delta
        } else if type == 109 {//眼距 参数范围：-50 - 50
            targetView.slider.value = filter.eyeDistance_delta
        } else if type == 110 {//眼角 参数范围：0 - 100
            targetView.slider.value = filter.eyeCorner_delta
        } else if type == 111 {//下眼睑 0 - 100
            targetView.slider.value = filter.eyelidDown_delta
        } else if type == 112 {//瘦鼻 参数范围：0 - 100
            targetView.slider.value = filter.noseThin_delta
        } else if type == 113 {//鼻翼 参数范围：0 - 100
            targetView.slider.value = filter.noseWing_delta
        } else if type == 114 {//长鼻 参数范围：-50 - 50
            targetView.slider.value = filter.noseLong_delta
        } else if type == 115 {//鼻子山根 参数范围：0 - 100
            targetView.slider.value = filter.noseRoot_delta
        } else if type == 116 {//眉间距 参数范围：-50 - 50
            targetView.slider.value = filter.eyebrowDistance_delta
        } else if type == 117 {//眉粗细 参数范围：-50 - 50
            targetView.slider.value = filter.eyebrowThin_delta
        } else if type == 118 {//嘴型 参数范围：-50 - 50
            targetView.slider.value = filter.mouth_delta
        } else if type == 119 {//瘦身 参数范围：0 - 100
            targetView.slider.value = filter.bodySlim_delta
        } else if type == 120 {//瘦腰 参数范围：0 - 100
            targetView.slider.value = filter.waistSlim_delta
        } else if type == 121 {//瘦腿 参数范围：0 - 100
            targetView.slider.value = filter.legSlim_delta
        } else if type == 122 {//窄肩 参数范围：0 - 100
            targetView.slider.value = filter.shoulderNarrow_delta
        } else if type == 123 {//瘦手臂 参数范围：0 - 100
            targetView.slider.value = filter.armSlim_delta
        } else if type == 125 {//小腿修饰 参数范围：0 - 100
            targetView.slider.value = filter.calfSlim_delta
        } else if type == 126 {//收腹 参数范围：0 - 100
            targetView.slider.value = filter.abdomenSlim_delta
        } else if type == 129 {//长腿 参数范围：0 - 100
            targetView.slider.value = filter.legLong_delta
        } else if type == 130 {//增高 参数范围：0 - 100
            targetView.slider.value = filter.bodyHeight_delta
        } else if type == 131 {//腿型 参数范围：0 - 100
            targetView.slider.value = filter.legShape_delta
        } else if type == 132 {//天鹅颈 参数范围：0 - 100
            targetView.slider.value = filter.neckLength_delta
        } else if type == 133 {//直角肩 参数范围：0 - 100
            targetView.slider.value = filter.shoulderShape_delta
        }
        targetView.valueLabel.text = String(format: "%.1f", targetView.slider.value)
    }
    
    func getReshapeDeltaValue(value: Float, type: Int) {
        if type == 100 {//小头 参数范围：0 - 100
            filter.headReduce_delta = value
        } else if type == 101 {//瘦脸 参数范围：0 - 100
            filter.faceThin_delta = value
        } else if type == 102 {//窄脸 参数范围：0 - 100
            filter.faceNarrow_delta = value
        } else if type == 103 {//V脸 参数范围：0 - 100
            filter.faceV_delta = value
        } else if type == 104 {//小脸 参数范围：0 - 100
            filter.faceSmall_delta = value
        } else if type == 105 {//下巴 参数范围：-50 - 50
            filter.chin_delta = value
        } else if type == 106 {//额头 参数范围：-50 - 50
            filter.forehead_delta = value
        } else if type == 107 {//颧骨 参数范围：-50 - 50
            filter.cheekbone_delta = value
        } else if type == 108 {//大眼 参数范围：0 - 100
            filter.eyeBig_delta = value
        } else if type == 109 {//眼距 参数范围：-50 - 50
            filter.eyeDistance_delta = value
        } else if type == 110 {//眼角 参数范围：0 - 100
            filter.eyeCorner_delta = value
        } else if type == 111 {//下眼睑 0 - 100
            filter.eyelidDown_delta = value
        } else if type == 112 {//瘦鼻 参数范围：0 - 100
            filter.noseThin_delta = value
        } else if type == 113 {//鼻翼 参数范围：0 - 100
            filter.noseWing_delta = value
        } else if type == 114 {//长鼻 参数范围：-50 - 50
            filter.noseLong_delta = value
        } else if type == 115 {//鼻子山根 参数范围：0 - 100
            filter.noseRoot_delta = value
        } else if type == 116 {//眉间距 参数范围：-50 - 50
            filter.eyebrowDistance_delta = value
        } else if type == 117 {//眉粗细 参数范围：-50 - 50
            filter.eyebrowThin_delta = value
        } else if type == 118 {//嘴型 参数范围：-50 - 50
            filter.mouth_delta = value
        } else if type == 119 {//瘦身 参数范围：0 - 100
            filter.bodySlim_delta = value
        } else if type == 120 {//瘦腰 参数范围：0 - 100
            filter.waistSlim_delta = value
        } else if type == 121 {//瘦腿 参数范围：0 - 100
            filter.legSlim_delta = value
        } else if type == 122 {//窄肩 参数范围：0 - 100
            filter.shoulderNarrow_delta = value
        } else if type == 123 {//瘦手臂 参数范围：0 - 100
            filter.armSlim_delta = value
        } else if type == 125 {//小腿修饰 参数范围：0 - 100
            filter.calfSlim_delta = value
        } else if type == 126 {//收腹 参数范围：0 - 100
            filter.abdomenSlim_delta = value
        } else if type == 129 {//长腿 参数范围：0 - 100
            filter.legLong_delta = value
        } else if type == 130 {//增高 参数范围：0 - 100
            filter.bodyHeight_delta = value
        } else if type == 131 {//腿型 参数范围：0 - 100
            filter.legShape_delta = value
        } else if type == 132 {//天鹅颈 参数范围：0 - 100
            filter.neckLength_delta = value
        } else if type == 133 {//直角肩 参数范围：0 - 100
            filter.shoulderShape_delta = value
        }
    }
    
    //MARK: Beauty Delegate
    func changeBeautyType(type: Int) {
        if type == 100 {//美白 参数范围：0 - 100
            beautyView.slider.value = filter.white_delta
        } else if type == 101 {//磨皮 参数范围 0 - 100
            beautyView.slider.value = filter.skin_delta
        } else if type == 102 {//亮眼 参数范围 0 - 100
            beautyView.slider.value = filter.eyeBright_delta
        } else if type == 103 {//白牙 参数范围 0 - 100
            beautyView.slider.value = filter.teethBright_delta
        } else if type == 104 {//黑眼圈 参数范围 0 - 100
            beautyView.slider.value = filter.darkCircle_delta
        }
        beautyView.valueLabel.text = String(format: "%.1f", beautyView.slider.value)
    }
    
    func getBeautyDeltaValue(value: Float, type: Int) {
        if type == 100 {//美白 参数范围：0 - 100
            filter.white_delta = value
        } else if type == 101 {//磨皮 参数范围 0 - 100
            filter.skin_delta = value
        } else if type == 102 {//亮眼 参数范围 0 - 100
            filter.eyeBright_delta = value
        } else if type == 103 {//白牙 参数范围 0 - 100
            filter.teethBright_delta = value
        } else if type == 104 {//黑眼圈 参数范围 0 - 100
            filter.darkCircle_delta = value
        }
    }
    
    //MARK: Makeup Delegate
    func changeMakeupType(type: Int) {
        var makeupString = ""
        if type == 0 {//眉毛 参数范围 0 - 100
            if eyebrowType.contains(filter.makeup_eyebrow_type) {
                let index = eyebrowType.firstIndex(of: filter.makeup_eyebrow_type)!
                makeupString = eyebrowString[index]
            }
            makeupView.value = filter.makeup_eyebrow_delta
        } else if type == 1 {//眼影 参数范围 0 - 100
            if eyeshadowType.contains(filter.makeup_eyeshadow_type) {
                let index = eyeshadowType.firstIndex(of: filter.makeup_eyeshadow_type)!
                makeupString = eyeshadowString[index]
            }
            makeupView.value = filter.makeup_eyeshadow_delta
        } else if type == 2 {//美瞳 参数范围 0 - 100
            if pupilType.contains(filter.makeup_pupil_type) {
                let index = pupilType.firstIndex(of: filter.makeup_pupil_type)!
                makeupString = pupilString[index]
            }
            makeupView.value = filter.makeup_pupil_delta
        } else if type == 3 {//腮红 参数范围 0 - 100
            if blushType.contains(filter.makeup_blush_type) {
                let index = blushType.firstIndex(of: filter.makeup_blush_type)!
                makeupString = blushString[index]
            }
            makeupView.value = filter.makeup_blush_delta
        } else if type == 4 {//口红 参数范围 0 - 100
            if rougeType.contains(filter.makeup_rouge_type) {
                let index = rougeType.firstIndex(of: filter.makeup_rouge_type)!
                makeupString = rougeString[index]
            }
            makeupView.value = filter.makeup_rouge_delta
        }
        makeupView.makeupString = makeupString
    }
    
    func getMakeupDeltaValue(value: Float, makeupType: Int, makeupString: String) {
        if makeupType == 0 {//眉毛 参数范围：0 - 100
            filter.makeup_eyebrow_delta = value
            filter.makeup_eyebrow_type = changeEyebrowStringToMakeupType(name: makeupString)
        } else if makeupType == 1 {//眼妆 参数范围：0 - 100
            filter.makeup_eyeshadow_delta = value
            filter.makeup_eyeshadow_type = changeEyeshadowStringToMakeupType(name: makeupString)
        } else if makeupType == 2 {//美瞳 参数范围：0 - 100
            filter.makeup_pupil_delta = value
            filter.makeup_pupil_type = changePupilStringToMakeupType(name: makeupString)
        } else if makeupType == 3 {//腮红 参数范围：0 - 100
            filter.makeup_blush_delta = value
            filter.makeup_blush_type = changeBlushStringToMakeupType(name: makeupString)
        } else if makeupType == 4 {//口红 参数范围：0 - 100
            filter.makeup_rouge_delta = value
            filter.makeup_rouge_type = changeRougeStringToMakeupType(name: makeupString)
        }
    }
    
    //MARK: Action
    @objc func closeAction() {
        dismiss(animated: true)
    }
    
    @objc func changeAction() {
        isFront = !isFront
        camera.changeInputDeviceisFront(isFront)
    }

    @objc func itemButtonAction(button:UIButton) {
        currentShow = button.tag
    }
    
    //MARK: Private Method
    ///将字符串(图片名)转换为对应的美妆眉毛Type
    private func changeEyebrowStringToMakeupType(name: String) -> MakeupEyebrowType {
        
        if eyebrowString.contains(name) {
            let index = eyebrowString.firstIndex(of: name)!
            return eyebrowType[index]
        }
        return .eyebrow_none
    }
    ///将字符串(图片名)转换为对应的美妆眼妆Type
    private func changeEyeshadowStringToMakeupType(name: String) -> MakeupEyeshadowType {
        if eyeshadowString.contains(name) {
            let index = eyeshadowString.firstIndex(of: name)!
            return eyeshadowType[index]
        }
        return .eyeshadow_none
    }
    ///将字符串(图片名)转换为对应的美妆美瞳Type
    private func changePupilStringToMakeupType(name: String) -> MakeupPupilType {
        if pupilString.contains(name) {
            let index = pupilString.firstIndex(of: name)!
            return pupilType[index]
        }
        return .pupil_none
    }
    ///将字符串(图片名)转换为对应的美妆腮红Type
    private func changeBlushStringToMakeupType(name: String) -> MakeupBlushType {
        if blushString.contains(name) {
            let index = blushString.firstIndex(of: name)!
            return blushType[index]
        }
        return .blush_none
    }
    ///将字符串(图片名)转换为对应的美妆口红Type
    private func changeRougeStringToMakeupType(name: String) -> MakeupRougeType {
        if rougeString.contains(name) {
            let index = rougeString.firstIndex(of: name)!
            return rougeType[index]
        }
        return .rouge_none
    }

    ///将美妆眉毛Type转换为对应的字符串(图片名)
    private func changeMakeupTypeToEyebrowString(makeupType: MakeupEyebrowType) -> String {
        if eyebrowType.contains(makeupType) {
            let index = eyebrowType.firstIndex(of: makeupType)!
            return eyebrowString[index]
        }
        return ""
    }
    ///将美妆眼妆Type转换为对应的字符串(图片名)
    private func changeMakeupTypeToEyeshadowString(makeupType: MakeupEyeshadowType) -> String {
        if eyeshadowType.contains(makeupType) {
            let index = eyeshadowType.firstIndex(of: makeupType)!
            return eyeshadowString[index]
        }
        return ""
    }
    ///将美妆美瞳Type转换为对应的字符串(图片名)
    private func changeMakeupTypeToPupilString(makeupType: MakeupPupilType) -> String {
        if pupilType.contains(makeupType) {
            let index = pupilType.firstIndex(of: makeupType)!
            return pupilString[index]
        }
        return ""
    }
    ///将美妆腮红Type转换为对应的字符串(图片名)
    private func changeMakeupTypeToBlushString(makeupType: MakeupBlushType) -> String {
        if blushType.contains(makeupType) {
            let index = blushType.firstIndex(of: makeupType)!
            return blushString[index]
        }
        return ""
    }
    ///将美妆口红Type转换为对应的字符串(图片名)
    private func changeMakeupTypeToRougeString(makeupType: MakeupRougeType) -> String {
        if rougeType.contains(makeupType) {
            let index = rougeType.firstIndex(of: makeupType)!
            return rougeString[index]
        }
        return ""
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}



extension BeautyFilterController {
    private func cropPixelBuffer(from pixelBuffer: CVPixelBuffer, size: CGSize ) -> CVPixelBuffer? {

        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(pixelBuffer)

        assert(pixelBufferType == kCVPixelFormatType_32BGRA)

        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let imageChannels = 4

        let thumbnailSize = min(imageWidth, imageHeight)
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        var originX = 0
        var originY = 0

        if imageWidth > imageHeight {
          originX = (imageWidth - imageHeight) / 2
        }
        else {
          originY = (imageHeight - imageWidth) / 2
        }

        // Finds the biggest square in the pixel buffer and advances rows based on it.
        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)?.advanced(by: originY * inputImageRowBytes + originX * imageChannels) else {
          return nil
        }

        // Gets vImage Buffer from input image
        var inputVImageBuffer = vImage_Buffer(data: inputBaseAddress, height: UInt(thumbnailSize), width: UInt(thumbnailSize), rowBytes: inputImageRowBytes)

        let thumbnailRowBytes = Int(size.width) * imageChannels
        guard  let thumbnailBytes = malloc(Int(size.height) * thumbnailRowBytes) else {
          return nil
        }

        // Allocates a vImage buffer for thumbnail image.
        var thumbnailVImageBuffer = vImage_Buffer(data: thumbnailBytes, height: UInt(size.height), width: UInt(size.width), rowBytes: thumbnailRowBytes)

        // Performs the scale operation on input image buffer and stores it in thumbnail image buffer.
        let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &thumbnailVImageBuffer, nil, vImage_Flags(0))

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        guard scaleError == kvImageNoError else {
          return nil
        }

        let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in

          if let pointer = pointer {
            free(UnsafeMutableRawPointer(mutating: pointer))
          }
        }

        var thumbnailPixelBuffer: CVPixelBuffer?
        
//        let keys = [kCVPixelBufferOpenGLESCompatibilityKey, kCVPixelBufferIOSurfacePropertiesKey]
        
        let outputSettings =
            [kCVPixelBufferOpenGLESCompatibilityKey: true,
               kCVPixelBufferIOSurfacePropertiesKey:NSDictionary()] as [CFString : Any]

        // Converts the thumbnail vImage buffer to CVPixelBuffer
        let conversionStatus = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, thumbnailBytes, thumbnailRowBytes, releaseCallBack, nil, outputSettings as CFDictionary, &thumbnailPixelBuffer)

        guard conversionStatus == kCVReturnSuccess else {

          free(thumbnailBytes)
          return nil
        }

        return thumbnailPixelBuffer
      }
    
    
    private func resizePixelBuffer(pixelBuffer: CVPixelBuffer, ratio: CGFloat) {
        let pixelWidth = CVPixelBufferGetWidth(pixelBuffer)
        let pixelHeight = CVPixelBufferGetHeight(pixelBuffer)
        guard pixelWidth > 0, pixelHeight > 0, ratio > 0 else { return }

        let currentRatio = CGFloat(pixelWidth) / CGFloat(pixelHeight)
        guard abs(currentRatio - ratio) > 0.01 else { return }

        var ciImage = CIImage(cvImageBuffer: pixelBuffer)
        
        var width = ciImage.extent.width
        var height = ciImage.extent.width / ratio
        if height > ciImage.extent.height {
            height = ciImage.extent.height
            width = height * ratio
        }
        ciImage = ciImage.cropped(to: CGRect(x: ciImage.extent.width/2-width/2, y: ciImage.extent.height/2-height/2, width: width, height: height))
        
        previewCropContext.render(ciImage, to: pixelBuffer)
    }
}
