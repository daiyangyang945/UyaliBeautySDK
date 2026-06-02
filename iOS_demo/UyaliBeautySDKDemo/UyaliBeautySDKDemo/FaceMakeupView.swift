//
//  FaceMakeupView.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/3/19.
//

import UIKit

@objc protocol FaceMakeupDelegate: AnyObject {
    func changeMakeupType(type: Int)
    func getMakeupDeltaValue(value:Float, makeupType:Int, makeupString: String)
}

class FaceMakeupView: UIView, MakeupItemViewDelegate {

    weak var delegate: FaceMakeupDelegate!
    
    var makeupString = "" {
        didSet {
            if makeupItemView != nil {
                if makeupString.count > 0 {
                    var index = 0
                    if makeupItemView.type == 0 {//眉毛
                        if eyebrowString.contains(makeupString) {
                            index = eyebrowString.firstIndex(of: makeupString)!
                        }
                    } else if makeupItemView.type == 1 {//眼妆
                        if eyeshadowString.contains(makeupString) {
                            index = eyeshadowString.firstIndex(of: makeupString)!
                        }
                    } else if makeupItemView.type == 2 {//美瞳
                        if pupilString.contains(makeupString) {
                            index = pupilString.firstIndex(of: makeupString)!
                        }
                    } else if makeupItemView.type == 3 {//腮红
                        if blushString.contains(makeupString) {
                            index = blushString.firstIndex(of: makeupString)!
                        }
                    } else if makeupItemView.type == 4 {//口红
                        if rougeString.contains(makeupString) {
                            index = rougeString.firstIndex(of: makeupString)!
                        }
                    }
                    makeupItemView.currentTag = (makeupItemView.type+1)*1000+index
                }
            }
        }
    }
    var value: Float = 0.0 {
        didSet {
            if makeupItemView != nil {
                makeupItemView.slider.value = value
                makeupItemView.valueLabel.text = String(format: "%.1f", value)
            }
        }
    }

    private let makeupItems: [[String: String]] = [
        ["image": "makeup_eyebrow", "name": "眉毛"],
        ["image": "makeup_eyeshadow", "name": "眼妆"],
        ["image": "makeup_pupil", "name": "美瞳"],
        ["image": "makeup_blush", "name": "腮红"],
        ["image": "makeup_lip", "name": "口红"]
    ]
    
    private var makeupItemView: MakeupItemView!
    
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
        
        let makeupLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 60))
        addSubview(makeupLabel)
        makeupLabel.textAlignment = .center
        makeupLabel.textColor = .white
        makeupLabel.font = .systemFont(ofSize: 20, weight: .medium)
        makeupLabel.text = "美妆"
        
        let scroll = UIScrollView(frame: CGRect(x: 0, y: 60, width: bounds.width, height: bounds.height-70))
        addSubview(scroll)
        
        let buttonWidth = scroll.bounds.height
        let buttonHeight = scroll.bounds.height
        let buttonMargin = 16.0
        
        scroll.contentSize = CGSize(width: buttonMargin+(buttonWidth+buttonMargin)*CGFloat(makeupItems.count), height: scroll.frame.height)
        
        for i in 0..<makeupItems.count {
            let item = makeupItems[i]
            let button = UyaliButton(frame: CGRect(x: buttonMargin+(buttonMargin+buttonWidth)*CGFloat(i), y: 0, width: buttonWidth, height: buttonHeight))
            scroll.addSubview(button)
            button.setTitle(item["name"], for: .normal)
            button.setImage(UIImage(named: item["image"]!), for: .normal)
            button.addTarget(self, action: #selector(makeupButtonAction(button:)), for: .touchUpInside)
            button.tag = 100+i
            button.layer.cornerRadius = buttonWidth/2
        }
        
        makeupItemView = MakeupItemView(frame: CGRect(x: frame.width, y: 0, width: frame.width, height: frame.height))
        addSubview(makeupItemView)
        makeupItemView.delegate = self
    }
    
    //MARK: Makeup Item View Delegate
    func getMakeupDeltaValueAndType(value: Float, makeupType: Int, makeupString: String) {
        if delegate != nil {
            delegate.getMakeupDeltaValue(value: value, makeupType: makeupType, makeupString: makeupString)
        }
    }
    
    //MARK: Action
    @objc func makeupButtonAction(button: UyaliButton) {
        makeupItemView.type = button.tag - 100
        makeupItemView.showMakeupItemsView()
        if delegate != nil {
            delegate.changeMakeupType(type: makeupItemView.type)
        }
    }
}





@objc protocol MakeupItemViewDelegate: AnyObject {
    func getMakeupDeltaValueAndType(value: Float, makeupType: Int, makeupString: String)
}

class MakeupItemView: UIView {
    
    //0:眉毛， 1:眼妆， 2:美瞳， 3:腮红， 4:口红
    var type = 0 {
        didSet {
            scroll.subviews.forEach({$0.removeFromSuperview()})
            if type == 0 {//眉毛
                backButton.name = "眉毛"
                commonItems = eyebrowItems
            } else if type == 1 {//眼妆
                backButton.name = "眼妆"
                commonItems = eyeshadowItems
            } else if type == 2 {//美瞳
                backButton.name = "美瞳"
                commonItems = pupilItems
            } else if type == 3 {//腮红
                backButton.name = "腮红"
                commonItems = blushItems
            } else if type == 4 {//口红
                backButton.name = "口红"
                commonItems = lipItems
            }
            let width = 60.0
            let margin = 10.0
            
            let noneButton = MakeupButton(frame: CGRect(x: margin, y: 0, width: width, height: scroll.bounds.height))
            scroll.addSubview(noneButton)
            noneButton.imageName = "makeup_none"
            noneButton.name = "无"
            noneButton.imgBg = .clear
            noneButton.addTarget(self, action: #selector(noneButtonAction), for: .touchUpInside)
            
            for i in 0..<commonItems.count {
                let dic = commonItems[i]
                let button = MakeupButton(frame: CGRect(x: 70.0+margin+(width+margin)*CGFloat(i), y: 0, width: width, height: scroll.bounds.height))
                scroll.addSubview(button)
                button.imageName = dic["image"]!
                button.name = dic["name"]!
                button.tag = (type+1)*1000+i
                button.addTarget(self, action: #selector(makeupButtonAction(button:)), for: .touchUpInside)
                if type == 2 {
                    button.imgBg = .clear
                }
            }
            
            scroll.contentSize = CGSize(width: margin+CGFloat(commonItems.count+1)*(margin+width), height: scroll.bounds.height)
        }
    }
    
    var slider: UISlider!
    var valueLabel: UILabel!
    
    weak var delegate: MakeupItemViewDelegate!
    
    private var commonItems = [[String:String]]()
    
    private let eyebrowItems = [
        ["image":"eyebrow_biaozhun","name":"标准眉"],
        ["image":"eyebrow_cupin","name":"蹙颦眉"],
        ["image":"eyebrow_juanyan","name":"罥烟眉"],
        ["image":"eyebrow_liuxing","name":"流星眉"],
        ["image":"eyebrow_liuye","name":"柳叶眉"],
        ["image":"eyebrow_qiubo","name":"秋波眉"],
        ["image":"eyebrow_wanyue","name":"弯月眉"],
        ["image":"eyebrow_xinyue","name":"新月眉"],
        ["image":"eyebrow_yesheng","name":"野生眉"],
        ["image":"eyebrow_yuanshan","name":"远山眉"]
    ]
    
    private let eyeshadowItems = [
        ["image":"eyeshadow_dadise","name":"大地色"],
        ["image":"eyeshadow_fuguse","name":"复古色"],
        ["image":"eyeshadow_fangtangfen","name":"方糖粉"],
        ["image":"eyeshadow_huoliju","name":"活力橘"],
        ["image":"eyeshadow_jinzongse","name":"金棕色"],
        ["image":"eyeshadow_pengkezong","name":"朋克棕"],
        ["image":"eyeshadow_tianchengse","name":"甜橙色"],
        ["image":"eyeshadow_xingguangfen","name":"星光粉"],
        ["image":"eyeshadow_yanfense","name":"烟粉色"],
        ["image":"eyeshadow_yeqiangweise","name":"野蔷薇色"],
        ["image":"eyeshadow_yuanqicheng","name":"元气橙"]
    ]
    
    private let pupilItems = [
        ["image":"pupil_jiaopianzong","name":"胶片棕"],
        ["image":"pupil_mitangzong","name":"蜜糖棕"],
        ["image":"pupil_xingyelan","name":"星夜蓝"],
        ["image":"pupil_jizhouhei","name":"极昼黑"],
        ["image":"pupil_wuraohui","name":"勿扰灰"],
        ["image":"pupil_chunrifen","name":"春日粉"],
        ["image":"pupil_tianchalv","name":"甜茶绿"],
        ["image":"pupil_siyecaolv","name":"四叶草绿"],
        ["image":"pupil_kuangyelan","name":"旷野蓝"],
        ["image":"pupil_qiangweifenhui","name":"蔷薇粉灰"],
        ["image":"pupil_haifenglan","name":"海风蓝"]
    ]
    
    private let blushItems = [
        //无辜
        ["image":"blush_wugu_naixingse","name":"奶杏色"],
        ["image":"blush_wugu_naijuse","name":"奶橘色"],
        ["image":"blush_wugu_mitaoju","name":"蜜桃橘"],
        ["image":"blush_wugu_yanxunmeigui","name":"烟熏玫瑰"],
        ["image":"blush_wugu_niunaicaomei","name":"牛奶草莓"],
        //茶艺
        ["image":"blush_chayi_naixingse","name":"奶杏色"],
        ["image":"blush_chayi_naijuse","name":"奶橘色"],
        ["image":"blush_chayi_mitaoju","name":"蜜桃橘"],
        ["image":"blush_chayi_yanxunmeigui","name":"烟熏玫瑰"],
        ["image":"blush_chayi_niunaicaomei","name":"牛奶草莓"],
        //初恋
        ["image":"blush_chulian_naixingse","name":"奶杏色"],
        ["image":"blush_chulian_naijuse","name":"奶橘色"],
        ["image":"blush_chulian_mitaoju","name":"蜜桃橘"],
        ["image":"blush_chulian_yanxunmeigui","name":"烟熏玫瑰"],
        ["image":"blush_chulian_niunaicaomei","name":"牛奶草莓"],
        //纯情
        ["image":"blush_chunqing_naixingse","name":"奶杏色"],
        ["image":"blush_chunqing_naijuse","name":"奶橘色"],
        ["image":"blush_chunqing_mitaoju","name":"蜜桃橘"],
        ["image":"blush_chunqing_yanxunmeigui","name":"烟熏玫瑰"],
        ["image":"blush_chunqing_niunaicaomei","name":"牛奶草莓"],
        //奇迹
        ["image":"blush_qiji_naixingse","name":"奶杏色"],
        ["image":"blush_qiji_naijuse","name":"奶橘色"],
        ["image":"blush_qiji_mitaoju","name":"蜜桃橘"],
        ["image":"blush_qiji_yanxunmeigui","name":"烟熏玫瑰"],
        ["image":"blush_qiji_niunaicaomei","name":"牛奶草莓"],
        //少女
        ["image":"blush_shaonv_naixingse","name":"奶杏色"],
        ["image":"blush_shaonv_naijuse","name":"奶橘色"],
        ["image":"blush_shaonv_mitaoju","name":"蜜桃橘"],
        ["image":"blush_shaonv_yanxunmeigui","name":"烟熏玫瑰"],
        ["image":"blush_shaonv_niunaicaomei","name":"牛奶草莓"]
    ]
    
    private let lipItems = [
        ["image":"lip_meizise","name":"梅子色"],
        ["image":"lip_doushafen","name":"豆沙粉"],
        ["image":"lip_fuguse","name":"复古色"],
        ["image":"lip_guimeihong","name":"鬼魅红"],
        ["image":"lip_jiangguose","name":"浆果色"],
        ["image":"lip_nanguase","name":"南瓜色"],
        ["image":"lip_shiliuhong","name":"石榴红"],
        ["image":"lip_mitaose","name":"蜜桃色"],
        ["image":"lip_shanhuse","name":"珊瑚色"],
        ["image":"lip_xingguanghong","name":"星光红"],
        ["image":"lip_anyezi","name":"暗夜紫"],
        ["image":"lip_shaonvfen","name":"少女粉"]
    ]
    
    private let scroll = UIScrollView()
    private var backButton: MakeupButton!
    
    var currentTag = 0 {
        didSet {
            if currentTag == oldValue {
                return
            }
            if currentTag == 0 {//当选择了none时
                let button = viewWithTag(oldValue) as! MakeupButton
                button.isSelected = false
            } else if oldValue == 0 {//当从none选择了美妆类型时
                let button = viewWithTag(currentTag) as! MakeupButton
                button.isSelected = true
            } else {//切换美妆类型时
                let button1 = viewWithTag(oldValue) as! MakeupButton
                let button2 = viewWithTag(currentTag) as! MakeupButton
                button1.isSelected = false
                button2.isSelected = true
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
    
    func setupView() {
        self.backgroundColor = .white
        
        slider = UISlider(frame: CGRect(x: 16, y: 24, width: bounds.width-32, height: 30))
        addSubview(slider)
        slider.addTarget(self, action: #selector(sliderValueChanged(currentSlider: )), for: .valueChanged)
        slider.minimumValue = 0
        slider.maximumValue = 100
        
        valueLabel = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: slider.frame.origin.y))
        addSubview(valueLabel)
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
        valueLabel.textColor = .black
        valueLabel.textAlignment = .center
        valueLabel.text = "0.0"
        
        backButton = MakeupButton(frame: CGRect(x: 0, y: 60, width: 60, height: bounds.height-70))
        addSubview(backButton)
        backButton.imageName = "makeup_back"
        backButton.name = "眉毛"
        backButton.imgBg = .clear
        backButton.addTarget(self, action: #selector(hideMakeupItemsView), for: .touchUpInside)
        
        scroll.frame = CGRect(x: 60, y: 60, width: bounds.width-60, height: bounds.height-70)
        addSubview(scroll)
        
        let line = UIView(frame: CGRect(x: 59, y: 60, width: 1, height: scroll.frame.height-5))
        addSubview(line)
        line.backgroundColor = .systemGray3
    }
    
    @objc func sliderValueChanged(currentSlider: UISlider) {
        valueLabel.text = String(format: "%.1f", currentSlider.value)
        if delegate != nil {
            var makeupString = ""
            if currentTag != 0 {
                let dic = commonItems[currentTag%1000]
                makeupString = dic["image"]!
            }
            delegate.getMakeupDeltaValueAndType(value: slider.value, makeupType: type, makeupString: makeupString)
        }
    }
    
    //MARK: Action
    //展示
    func showMakeupItemsView() {
        UIView.animate(withDuration: 0.15) {[self] in
            frame = CGRect(x: frame.origin.x - frame.width, y: frame.origin.y, width: frame.width, height: frame.height)
            scroll.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    //隐藏
    @objc private func hideMakeupItemsView() {
        currentTag = 0
        UIView.animate(withDuration: 0.15) {[self] in
            frame = CGRect(x: frame.origin.x+frame.width, y: frame.origin.y, width: frame.width, height: frame.height)
        }
    }
    
    @objc func noneButtonAction() {
        currentTag = 0
        if delegate != nil {
            delegate.getMakeupDeltaValueAndType(value: slider.value, makeupType: type, makeupString: "")
        }
    }
    
    @objc func makeupButtonAction(button: MakeupButton) {
        currentTag = button.tag
        if delegate != nil {
            let dic = commonItems[button.tag%1000]
            delegate.getMakeupDeltaValueAndType(value: slider.value, makeupType: type, makeupString: dic["image"]!)
        }
    }
}








class MakeupButton: UIButton {
    
    var imageName = "" {
        didSet {
            imgV.image = UIImage(named: imageName)
        }
    }
    
    var name = "" {
        didSet {
            label.text = name
        }
    }
    
    var imgBg: UIColor = UIColor(hex: 0xffefee)! {
        didSet {
            imgV.backgroundColor = imgBg
        }
    }
    
    private let imgV = UIImageView()
    private let label = UILabel()
    
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
                imgV.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                imgV.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
        
    func setupView() {
        
        imgV.frame = CGRect(x: (bounds.width-40.0)/2.0, y: 0, width: 40, height: 40)
        addSubview(imgV)
        imgV.layer.borderWidth = 2
        imgV.layer.cornerRadius = 20
        imgV.layer.borderColor = UIColor.clear.cgColor
        imgV.backgroundColor = UIColor(hex: 0xffefee)
        imgV.layer.masksToBounds = true
        
        label.frame = CGRect(x: 0, y: 40, width: bounds.width, height: bounds.height-40)
        addSubview(label)
        label.textColor = .black
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
    }
}
