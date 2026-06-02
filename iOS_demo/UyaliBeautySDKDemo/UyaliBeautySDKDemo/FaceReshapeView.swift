//
//  FaceReshapeView.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/1/28.
//

import UIKit

@objc protocol FaceReshapeDelegate: NSObjectProtocol {
    func changeReshapeType(type: Int)
    func getReshapeDeltaValue(value:Float, type:Int)
}

enum FaceReshapeMode {
    case face
    case body
}

class FaceReshapeView: UIView {
    
    weak var delegate: FaceReshapeDelegate!
    
    var slider: UISlider!
    var valueLabel: UILabel!
    
    private let mode: FaceReshapeMode
    
    private var reshapeItems: [[String: String]] {
        return mode == .body ? bodyItems : faceItems
    }
    
    private let faceItems: [[String: String]] = [
        ["image": "beauty_shape_head_reduce", "name": "小头"],
        ["image": "beauty_shape_face_thin", "name": "瘦脸"],
        ["image": "beauty_shape_face_narrow", "name": "窄脸"],
        ["image": "beauty_shape_face_v", "name": "V脸"],
        ["image": "beauty_shape_face_small", "name": "小脸"],
        ["image": "beauty_shape_chin", "name": "下巴"],
        ["image": "beauty_shape_forehead", "name": "额头"],
        ["image": "beauty_shape_cheekbone", "name": "颧骨"],
        ["image": "beauty_shape_eye_big", "name": "大眼"],
        ["image": "beauty_shape_eye_distance", "name": "眼距"],
        ["image": "beauty_shape_eye_corner", "name": "开眼角"],
        ["image": "beauty_shape_eyelid_down", "name": "眼睑下至"],
        ["image": "beauty_shape_nose_thin", "name": "瘦鼻"],
        ["image": "beauty_shape_nose_wing", "name": "鼻翼"],
        ["image": "beauty_shape_nose_long", "name": "长鼻"],
        ["image": "beauty_shape_nose_root", "name": "山根"],
        ["image": "beauty_shape_eyebrow_distance", "name": "眉间距"],
        ["image": "beauty_shape_eyebrow_thin", "name": "眉粗细"],
        ["image": "beauty_shape_mouth", "name": "嘴型"]
    ]
    
    private let bodyItems: [[String: String]] = [
        ["image": "beauty_shape_body_slim", "name": "瘦身", "tag": "119"],
        ["image": "beauty_shape_body_slim", "name": "瘦腰", "tag": "120"],
        ["image": "beauty_shape_leg_slim", "name": "瘦腿", "tag": "121"],
        ["image": "beauty_shape_body_slim", "name": "窄肩", "tag": "122"],
        ["image": "beauty_shape_body_slim", "name": "瘦臂", "tag": "123"],
        ["image": "beauty_shape_leg_slim", "name": "小腿", "tag": "125"],
        ["image": "beauty_shape_body_slim", "name": "收腹", "tag": "126"],
        ["image": "beauty_shape_leg_long", "name": "长腿", "tag": "129"],
        ["image": "beauty_shape_leg_long", "name": "增高", "tag": "130"],
        ["image": "beauty_shape_leg_slim", "name": "腿型", "tag": "131"],
        ["image": "beauty_shape_body_slim", "name": "天鹅颈", "tag": "132"],
        ["image": "beauty_shape_body_slim", "name": "直角肩", "tag": "133"]
    ]
    
    private var currentTag: Int = 100 {
        didSet {
            if currentTag != oldValue {
                let newBtn = viewWithTag(currentTag) as! UyaliButton
                let oldBtn = viewWithTag(oldValue) as! UyaliButton
                
                newBtn.isSelected = true
                oldBtn.isSelected = false
                
                if currentTag == 100 {//小头 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 101 {//瘦脸 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 102 {//窄脸 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 103 {//V脸 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 104 {//小脸 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 105 {//下巴 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 106 {//额头 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 107 {//颧骨 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 108 {//大眼 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 109 {//眼距 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 110 {//眼角 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 111 {//下眼睑 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 112 {//瘦鼻 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 113 {//鼻翼 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 114 {//长鼻 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 115 {//鼻子山根 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 116 {//眉间距 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 117 {//眉粗细 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag == 118 {//嘴型 done -50 - 50
                    slider.minimumValue = -50
                    slider.maximumValue = 50
                } else if currentTag >= 119 && currentTag <= 133 {//美体 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                }
            }
        }
    }

    init(frame: CGRect, mode: FaceReshapeMode = .face) {
        self.mode = mode
        self.currentTag = mode == .body ? 119 : 100
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        self.mode = .face
        super.init(coder: coder)
        setupView()
    }
    
    //MARK: UI
    func setupView() {
        self.backgroundColor = .black.withAlphaComponent(0.4)
        
        slider = UISlider(frame: CGRect(x: 16, y: 24, width: bounds.width-32, height: 30))
        addSubview(slider)
        slider.addTarget(self, action: #selector(sliderValueChanged(currentSlider: )), for: .valueChanged)
        
        valueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: slider.frame.origin.y))
        addSubview(valueLabel)
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        valueLabel.text = "0.0"
        
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 60, width: bounds.width, height: bounds.height-70))
        addSubview(scroll)
        
        let buttonWidth = scroll.bounds.height
        let buttonHeight = scroll.bounds.height
        let buttonMargin = 16.0
        
        scroll.contentSize = CGSize(width: buttonMargin+(buttonWidth+buttonMargin)*CGFloat(reshapeItems.count), height: scroll.frame.height)
        
        for i in 0..<reshapeItems.count {
            let item = reshapeItems[i]
            let button = UyaliButton(frame: CGRect(x: buttonMargin+(buttonMargin+buttonWidth)*CGFloat(i), y: 0, width: buttonWidth, height: buttonHeight))
            scroll.addSubview(button)
            button.setTitle(item["name"], for: .normal)
            button.setImage(UIImage(named: item["image"]!), for: .normal)
            button.addTarget(self, action: #selector(reshapeButtonAction(button:)), for: .touchUpInside)
            let tag = Int(item["tag"] ?? "") ?? 100+i
            button.tag = tag
            if i == 0 {
                button.isSelected = true
                currentTag = tag
                
                slider.minimumValue = 0
                slider.maximumValue = 100
            }
            button.layer.cornerRadius = buttonWidth/2
        }
    }
    
    //MARK: Action
    @objc func reshapeButtonAction(button: UyaliButton) {
        currentTag = button.tag
        if delegate != nil {
            delegate.changeReshapeType(type: button.tag)
        }
    }
    
    @objc func sliderValueChanged(currentSlider: UISlider) {
        valueLabel.text = String(format: "%.1f", currentSlider.value)
        if delegate != nil {
            delegate.getReshapeDeltaValue(value: slider.value, type: currentTag)
        }
    }
}


class UyaliButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
            
        setupView()
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                self.backgroundColor = .black.withAlphaComponent(0.4)
                self.imageView?.tintColor = .systemBlue
            } else {
                self.backgroundColor = .white.withAlphaComponent(0.4)
                self.imageView?.tintColor = .white
            }
        }
    }
        
    func setupView() {
        self.backgroundColor = .white.withAlphaComponent(0.4)
        self.titleLabel?.textAlignment = .center
        self.imageView?.contentMode = .scaleAspectFit
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        self.imageView?.tintColor = .white
        
        self.setTitleColor(.white, for: .normal)
        self.setTitleColor(.systemBlue, for: .selected)
    }
        
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleX = 0
        let titleY = contentRect.size.height * 0.5
        let titleW = contentRect.size.width
        let titleH = contentRect.size.height - titleY
        return CGRect(x: CGFloat(titleX), y: titleY, width: titleW, height: titleH)
    }
        
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageW = contentRect.width
        let imageH = contentRect.size.height * 0.5
        return CGRect(x: 0, y: 5, width: imageW, height: imageH)
    }
}
