//
//  FaceBeautyView.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/2/16.
//

import UIKit

@objc protocol FaceBeautyDelegate: AnyObject {
    func changeBeautyType(type: Int)
    func getBeautyDeltaValue(value:Float, type:Int)
}

class FaceBeautyView: UIView {
    
    weak var delegate: FaceBeautyDelegate!

    var slider: UISlider!
    var valueLabel: UILabel!
    
    private let beautyItems: [[String: String]] = [
        ["image": "beauty_skin_white", "name": "美白"],
        ["image": "beauty_skin_abrade", "name": "磨皮"],
        ["image": "beauty_bright_eye", "name": "亮眼"],
        ["image": "beauty_bright_teeth", "name": "白牙"],
        ["image": "beauty_skin_abrade", "name": "黑眼圈"]
    ]
    
    private var currentTag: Int = 100 {
        didSet {
            if currentTag != oldValue {
                let newBtn = viewWithTag(currentTag) as! UyaliButton
                let oldBtn = viewWithTag(oldValue) as! UyaliButton
                
                newBtn.isSelected = true
                oldBtn.isSelected = false
                
                if currentTag == 100 {//美白 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 101 {//磨皮 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 102 {//亮眼 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 103 {//白牙 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                } else if currentTag == 104 {//黑眼圈 done 0 - 100
                    slider.minimumValue = 0
                    slider.maximumValue = 100
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        scroll.contentSize = CGSize(width: buttonMargin+(buttonWidth+buttonMargin)*CGFloat(beautyItems.count), height: scroll.frame.height)
        
        for i in 0..<beautyItems.count {
            let item = beautyItems[i]
            let button = UyaliButton(frame: CGRect(x: buttonMargin+(buttonMargin+buttonWidth)*CGFloat(i), y: 0, width: buttonWidth, height: buttonHeight))
            scroll.addSubview(button)
            button.setTitle(item["name"], for: .normal)
            button.setImage(UIImage(named: item["image"]!), for: .normal)
            button.addTarget(self, action: #selector(beautyButtonAction(button:)), for: .touchUpInside)
            button.tag = 100+i
            if i == 0 {
                button.isSelected = true
                currentTag = 100
                
                slider.minimumValue = 0
                slider.maximumValue = 100
            }
            button.layer.cornerRadius = buttonWidth/2
        }
    }
    
    //MARK: Action
    @objc func beautyButtonAction(button: UyaliButton) {
        currentTag = button.tag
        if delegate != nil {
            delegate.changeBeautyType(type: button.tag)
        }
    }
    
    @objc func sliderValueChanged(currentSlider: UISlider) {
        valueLabel.text = String(format: "%.1f", currentSlider.value)
        if delegate != nil {
            delegate.getBeautyDeltaValue(value: slider.value, type: currentTag)
        }
    }
}
