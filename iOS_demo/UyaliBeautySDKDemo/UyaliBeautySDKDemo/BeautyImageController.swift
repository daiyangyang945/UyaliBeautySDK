//
//  BeautyImageController.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/3/27.
//

import UIKit
import UyaliBeautySDK
import Photos

extension UyaliBeautyEngine {
    var debugFaceLandmarkPoints: [NSValue] {
        guard responds(to: NSSelectorFromString("latestFaceLandmarkPoints")) else { return [] }
        return value(forKey: "latestFaceLandmarkPoints") as? [NSValue] ?? []
    }

    var debugFaceLandmarkLabels: [NSNumber] {
        guard responds(to: NSSelectorFromString("latestFaceLandmarkLabels")) else { return [] }
        return value(forKey: "latestFaceLandmarkLabels") as? [NSNumber] ?? []
    }
}

final class BodyContourDebugView: UIView {
    
    var facePoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var faceLabels: [Int] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var faceLandmarkPoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var faceLandmarkLabels: [Int] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var showsFaceLandmarks = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var faceDebugInfo: String = "face: idle" {
        didSet {
            setNeedsDisplay()
        }
    }
    var showsBodyDebug = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var points: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var posePoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var partPoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var partLabels: [Int] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    var debugInfo: String = "pose: idle" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.systemGreen,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        ("face contour: \(facePoints.count)" as NSString).draw(at: CGPoint(x: 8, y: 8), withAttributes: countAttributes)
        (faceDebugInfo as NSString).draw(at: CGPoint(x: 8, y: 26), withAttributes: countAttributes)
        if showsFaceLandmarks {
            ("face landmarks: \(faceLandmarkPoints.count)" as NSString).draw(at: CGPoint(x: 8, y: 44), withAttributes: countAttributes)
            drawFaceContour(drawLabels: false)
            drawFaceLandmarks()
        } else {
            drawFaceContour()
        }
        
        guard showsBodyDebug else { return }
        
        let bodyInfoOffset: CGFloat = showsFaceLandmarks ? 62 : 44
        ("body contour: \(points.count)" as NSString).draw(at: CGPoint(x: 8, y: bodyInfoOffset), withAttributes: countAttributes)
        let debugLines = debugInfo.components(separatedBy: " | ")
        for (index, line) in debugLines.enumerated() {
            (line as NSString).draw(at: CGPoint(x: 8, y: bodyInfoOffset + 18 + CGFloat(index) * 18),
                                    withAttributes: countAttributes)
        }
        let bodyDetailOffset = bodyInfoOffset + 18 + CGFloat(max(debugLines.count, 1)) * 18
        ("pose: \(posePoints.count) valid: \(validBodyPosePointCount())" as NSString).draw(at: CGPoint(x: 8, y: bodyDetailOffset), withAttributes: countAttributes)
        ("parts: \(partPoints.count)" as NSString).draw(at: CGPoint(x: 8, y: bodyDetailOffset + 18), withAttributes: countAttributes)
        
        let mappedPoints = points.map {
            CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height)
        }
        
        if let first = mappedPoints.first {
            let path = UIBezierPath()
            path.move(to: first)
            mappedPoints.dropFirst().forEach { path.addLine(to: $0) }
            path.close()
            UIColor.systemYellow.withAlphaComponent(0.9).setStroke()
            path.lineWidth = 1.0
            path.stroke()
        }
        
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 8, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        
        for (index, point) in mappedPoints.enumerated() {
            let pointRect = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)
            UIColor.systemRed.setFill()
            UIBezierPath(ovalIn: pointRect).fill()
            
            let label = "\(index)" as NSString
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelX = point.x + labelSize.width + 6 > bounds.width ? point.x - labelSize.width - 6 : point.x + 5
            let labelY = min(max(point.y - labelSize.height * 0.5, 0), bounds.height - labelSize.height)
            label.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttributes)
        }
        drawPartContours()
        drawPosePoints(with: labelAttributes)

    }

    private func drawFaceContour(drawLabels: Bool = true) {
        let mappedPoints = facePoints.map {
            CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height)
        }

        if let first = mappedPoints.first {
            let path = UIBezierPath()
            path.move(to: first)
            mappedPoints.dropFirst().forEach { path.addLine(to: $0) }
            UIColor.systemGreen.withAlphaComponent(0.95).setStroke()
            path.lineWidth = 2.0
            path.stroke()
        }

        guard drawLabels else { return }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]

        for (index, point) in mappedPoints.enumerated() {
            guard point.x.isFinite, point.y.isFinite else { continue }
            let radius: CGFloat = 3.5
            UIColor.systemYellow.setFill()
            UIBezierPath(ovalIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)).fill()

            let text = faceLabels.indices.contains(index) ? "\(faceLabels[index])" : "\(index)"
            let label = text as NSString
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelX = point.x + labelSize.width + 8 > bounds.width ? point.x - labelSize.width - 8 : point.x + radius + 3
            let labelY = min(max(point.y - labelSize.height * 0.5, 0), bounds.height - labelSize.height)
            label.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttributes)
        }
    }

    private func drawFaceLandmarks() {
        let mappedPoints = faceLandmarkPoints.map {
            CGPoint(x: $0.x * bounds.width, y: $0.y * bounds.height)
        }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 7, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]

        for (index, point) in mappedPoints.enumerated() {
            guard point.x.isFinite, point.y.isFinite else { continue }
            let radius: CGFloat = 1.8
            UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 0.95).setFill()
            UIBezierPath(ovalIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)).fill()

            let text = faceLandmarkLabels.indices.contains(index) ? "\(faceLandmarkLabels[index])" : "\(index)"
            let label = text as NSString
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelX = point.x + labelSize.width + 5 > bounds.width ? point.x - labelSize.width - 5 : point.x + radius + 2
            let labelY = min(max(point.y - labelSize.height * 0.5, 0), bounds.height - labelSize.height)
            label.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttributes)
        }
    }

    private func drawPartContours() {
        guard !partPoints.isEmpty, partPoints.count == partLabels.count else { return }

        var index = 0
        while index < partPoints.count {
            let label = partLabels[index]
            var segment: [CGPoint] = []
            while index < partPoints.count, partLabels[index] == label {
                let point = partPoints[index]
                segment.append(CGPoint(x: point.x * bounds.width, y: point.y * bounds.height))
                index += 1
            }

            guard let first = segment.first else { continue }
            let path = UIBezierPath()
            path.move(to: first)
            segment.dropFirst().forEach { path.addLine(to: $0) }
            if segment.count > 2 && !isEdgeContourLabel(label) {
                path.close()
            }
            color(forHumanParsingLabel: label).withAlphaComponent(0.9).setStroke()
            path.lineWidth = isEdgeContourLabel(label) ? 2.2 : 1.5
            path.stroke()
            color(forHumanParsingLabel: label).withAlphaComponent(0.9).setFill()
            for point in segment {
                let radius: CGFloat = isEdgeContourLabel(label) ? 2.6 : 1.8
                UIBezierPath(ovalIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)).fill()
            }

            let labelText = "\(humanParsingName(for: label)) \(baseHumanParsingLabel(label))" as NSString
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .bold),
                .foregroundColor: color(forHumanParsingLabel: label),
                .strokeColor: UIColor.black,
                .strokeWidth: -3.0
            ]
            labelText.draw(at: CGPoint(x: min(max(first.x + 4, 0), bounds.width - 70),
                                        y: min(max(first.y - 10, 0), bounds.height - 12)),
                           withAttributes: labelAttributes)
        }
    }

    private func color(forHumanParsingLabel label: Int) -> UIColor {
        switch baseHumanParsingLabel(label) {
        case 4:
            return .systemOrange
        case 5, 6, 7:
            return .systemRed
        case 9, 10:
            return .systemPurple
        case 11:
            return .systemYellow
        case 12, 13:
            return UIColor(red: 0.25, green: 0.70, blue: 1.0, alpha: 1.0)
        case 14, 15:
            return UIColor(red: 0.0, green: 0.78, blue: 0.64, alpha: 1.0)
        default:
            return .white
        }
    }

    private func humanParsingName(for label: Int) -> String {
        let prefix = isEdgeContourLabel(label) ? "edge " : ""
        switch baseHumanParsingLabel(label) {
        case 4: return "\(prefix)upper"
        case 5: return "\(prefix)skirt"
        case 6: return "\(prefix)pants"
        case 7: return "\(prefix)dress"
        case 9: return "\(prefix)L shoe"
        case 10: return "\(prefix)R shoe"
        case 11: return "\(prefix)face"
        case 12: return "\(prefix)L leg"
        case 13: return "\(prefix)R leg"
        case 14: return "\(prefix)L arm"
        case 15: return "\(prefix)R arm"
        default: return "\(prefix)part"
        }
    }

    private func isEdgeContourLabel(_ label: Int) -> Bool {
        return label >= 100
    }

    private func baseHumanParsingLabel(_ label: Int) -> Int {
        return isEdgeContourLabel(label) ? label - 100 : label
    }

    private func drawPosePoints(with labelAttributes: [NSAttributedString.Key: Any]) {
        guard !posePoints.isEmpty else { return }

        let semanticLabels: [Int: String] = [
            15: "L wrist",
            16: "R wrist",
            17: "L pinky",
            18: "R pinky",
            19: "L index",
            20: "R index",
            21: "L thumb",
            22: "R thumb",
            27: "L ankle",
            28: "R ankle",
            29: "L heel",
            30: "R heel",
            31: "L toe",
            32: "R toe"
        ]

        for (index, normalizedPoint) in posePoints.enumerated() {
            guard isValidNormalizedDebugPoint(normalizedPoint) else { continue }
            let point = CGPoint(x: normalizedPoint.x * bounds.width,
                                y: normalizedPoint.y * bounds.height)
            guard point.x.isFinite, point.y.isFinite else { continue }
            let isHandOrFoot = semanticLabels[index] != nil
            let radius: CGFloat = isHandOrFoot ? 4.5 : 2.5
            let pointRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
            let fillColor: UIColor
            if (15...22).contains(index) {
                fillColor = UIColor(red: 0.0, green: 0.78, blue: 0.95, alpha: 1.0)
            } else if (27...32).contains(index) {
                fillColor = .systemPurple
            } else {
                fillColor = .systemBlue
            }
            fillColor.setFill()
            UIBezierPath(ovalIn: pointRect).fill()

            let labelText = semanticLabels[index].map { "\($0) \(index)" } ?? "\(index)"
            let label = labelText as NSString
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelX = point.x + labelSize.width + 8 > bounds.width ? point.x - labelSize.width - 8 : point.x + radius + 3
            let labelY = min(max(point.y - labelSize.height * 0.5, 0), bounds.height - labelSize.height)
            label.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttributes)
        }
    }

    private func isValidNormalizedDebugPoint(_ point: CGPoint) -> Bool {
        return point.x.isFinite &&
            point.y.isFinite &&
            point.x > -0.05 &&
            point.x < 1.05 &&
            point.y > -0.05 &&
            point.y < 1.05 &&
            !(abs(point.x) < 0.0001 && abs(point.y) < 0.0001)
    }

    private func validBodyPosePointCount() -> Int {
        return posePoints.reduce(0) { count, point in
            guard isValidNormalizedDebugPoint(point) else {
                return count
            }
            return count + 1
        }
    }
}

class BeautyImageController: UIViewController,FaceReshapeDelegate,FaceBeautyDelegate,FaceMakeupDelegate {
    
    var image: UIImage!
    
    private let imageTools = ImageTools()
    
    private var originPixelBuffer: CVPixelBuffer!
    private var pixelBuffer: CVPixelBuffer!
    private var ciImage: CIImage!
    
    private var imageView: UIImageView!
    private var openGLView: OpenGLPreviewView!
    private var contourDebugView: BodyContourDebugView!
    
    private var beautyFilterView : UIView!
    private var reshapeView : FaceReshapeView!
    private var bodyView : FaceReshapeView!
    private var beautyView: FaceBeautyView!
    private var makeupView: FaceMakeupView!
    
    private let filter = UyaliBeautyEngine()
    
    private let imageRenderQueue = DispatchQueue(label: "com.uyali.demo.image.render")
    private let imageRenderContext = CIContext()
    private let imageRenderStateLock = NSLock()
    private var imageRenderInFlight = false
    private var imageRenderPending = false
    private var imageRenderStopped = false
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
    
    deinit {
        stopTimer()
        print("释放了")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var bottomHeight = 0.0
        if kIsIpnoneX() {
            bottomHeight = 34.0
        }
        
        var imageWidth = view.bounds.width
        var imageHeight = view.bounds.width/image.size.width*image.size.height
        if imageHeight > view.bounds.height {
            imageHeight = view.bounds.height
            imageWidth = view.bounds.height/image.size.height*image.size.width
        }
        
        openGLView = OpenGLPreviewView(frame: CGRect(x: (view.bounds.width-imageWidth)/2.0, y: (view.bounds.height-imageHeight)/2.0, width: imageWidth, height: imageHeight))
        view.addSubview(openGLView)
        
        imageView = UIImageView(frame: view.bounds)
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        
        contourDebugView = BodyContourDebugView(frame: openGLView.frame)
        contourDebugView.isHidden = true
        view.addSubview(contourDebugView)
        filter.faceContourDebugEnabled = false
        filter.bodyContourDebugEnabled = true
        filter.staticImageBodyPoseReuseEnabled = true
        
        let closeButton = UIButton(frame: CGRect(x: 8, y: 60, width: 50, height: 50))
        view.addSubview(closeButton)
        closeButton .setTitle("关闭", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        
        let saveButton = UIButton(frame: CGRect(x: view.bounds.width-58, y: 60, width: 50, height: 50))
        view.addSubview(saveButton)
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(.systemBlue, for: .normal)
        saveButton.addTarget(self, action: #selector(saveAction), for: .touchUpInside)

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
        
        originPixelBuffer = convertUIImageToCVPixelBuffer(image: image)
        pixelBuffer = convertUIImageToCVPixelBuffer(image: image)
        ciImage = convertUIImageToCIImage(image: image)
        openGLView.display(pixelBuffer: pixelBuffer)
        startToProcessImage()
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
        requestImageRender()
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
        requestImageRender()
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
        requestImageRender()
    }
    
    //MARK: Action
    @objc func closeAction() {
        dismiss(animated: true)
    }
    
    @objc func saveAction() {
        
        let image = getUIImageFromCVPixelBuffer(pixelBuffer: pixelBuffer)!
        
        PHPhotoLibrary.requestAuthorization {[weak self] status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { finished, error in
                    DispatchQueue.main.async {
                        if error != nil {
                            let alert = UIAlertController(title: "提示", message: error!.localizedDescription, preferredStyle: .alert)
                            let OK = UIAlertAction(title: "知道了", style: .default)
                            alert.addAction(OK)
                            self?.present(alert, animated: true)
                        }
                        if finished {
                            let alert = UIAlertController(title: "提示", message: "已保存至相册", preferredStyle: .alert)
                            let OK = UIAlertAction(title: "知道了", style: .default)
                            alert.addAction(OK)
                            self?.present(alert, animated: true)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "提示", message: "相册权限未设置", preferredStyle: .alert)
                    let cancel = UIAlertAction(title: "取消", style: .cancel)
                    let set = UIAlertAction(title: "去开启", style: .destructive) { action in
                        if let url = URL.init(string: UIApplication.openSettingsURLString) {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }
                    }
                    alert.addAction(cancel)
                    alert.addAction(set)
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    @objc func itemButtonAction(button:UIButton) {
        currentShow = button.tag
    }
    
    //MARK: Private Method
    private func startToProcessImage() {
        requestImageRender(delay: .milliseconds(0))
    }

    private func requestImageRender(delay: DispatchTimeInterval = .milliseconds(0)) {
        imageRenderStateLock.lock()
        guard !imageRenderStopped else {
            imageRenderStateLock.unlock()
            return
        }
        if imageRenderInFlight {
            imageRenderPending = true
            imageRenderStateLock.unlock()
            return
        }
        imageRenderInFlight = true
        imageRenderStateLock.unlock()

        imageRenderQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            autoreleasepool {
                self.imageRenderContext.render(self.ciImage!, to: self.pixelBuffer!)
                self.filter.process(pixelBuffer: self.pixelBuffer!)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard !self.isImageRenderStopped() else {
                    self.finishImageRender()
                    return
                }
                self.openGLView.display(pixelBuffer: self.pixelBuffer!)
                self.updateContourDebugOverlayIfNeeded(force: true)
                self.finishImageRender()
            }
        }
    }

    private func isImageRenderStopped() -> Bool {
        imageRenderStateLock.lock()
        let stopped = imageRenderStopped
        imageRenderStateLock.unlock()
        return stopped
    }

    private func finishImageRender() {
        imageRenderStateLock.lock()
        let shouldRenderAgain = imageRenderPending && !imageRenderStopped
        imageRenderPending = false
        imageRenderInFlight = false
        imageRenderStateLock.unlock()
        if shouldRenderAgain {
            requestImageRender(delay: .milliseconds(0))
        }
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
        let points = filter.latestBodyContourPoints.map { $0.cgPointValue }
        let partPoints = filter.latestBodyPartContourPoints.map { $0.cgPointValue }
        let partLabels = filter.latestBodyPartContourLabels.map { $0.intValue }
        let posePoints = filter.latestBodyLandmarkPoints.map { $0.cgPointValue }
        let debugInfo = filter.latestBodyContourDebugInfo
        DispatchQueue.main.async { [weak self] in
            self?.contourDebugView.facePoints = facePoints
            self?.contourDebugView.faceLabels = faceLabels
            self?.contourDebugView.faceLandmarkPoints = faceLandmarkPoints
            self?.contourDebugView.faceLandmarkLabels = faceLandmarkLabels
            self?.contourDebugView.faceDebugInfo = faceDebugInfo
            self?.contourDebugView.points = points
            self?.contourDebugView.partPoints = partPoints
            self?.contourDebugView.partLabels = partLabels
            self?.contourDebugView.posePoints = posePoints
            self?.contourDebugView.debugInfo = debugInfo
        }
    }

    private func stopTimer() {
        imageRenderStateLock.lock()
        imageRenderStopped = true
        imageRenderPending = false
        imageRenderStateLock.unlock()
    }
    
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
