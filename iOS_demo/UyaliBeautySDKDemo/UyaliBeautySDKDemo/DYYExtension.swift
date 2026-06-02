//
//  DYYExtension.swift
//  最扫描
//
//  Created by S weet on 2022/6/23.
//

import Foundation
import UIKit

extension UIColor {
    convenience init?(hex:Int) {
        self.init(hexString:String(hex,radix: 16))
    }
    
    convenience init?(hexString:String) {
        var hex = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        if hex.hasPrefix("0x") || hex.hasPrefix(("0X")) {
            hex.removeSubrange((hex.startIndex ..< hex.index(hex.startIndex, offsetBy: 2)))
        }
                
        guard let hexNum = Int(hex, radix: 16) else {
            self.init()
            return nil
        }
        switch hex.count {
        case 3:
            self.init(red: CGFloat(((hexNum & 0xF00) >> 8).duplicate4bits) / 255.0,
                        green: CGFloat(((hexNum & 0x0F0) >> 4).duplicate4bits) / 255.0,
                        blue: CGFloat((hexNum & 0x00F).duplicate4bits) / 255.0,
                        alpha: 1.0)
        case 4:
            self.init(red: CGFloat(((hexNum & 0xF000) >> 12).duplicate4bits) / 255.0,
                        green: CGFloat(((hexNum & 0x0F00) >> 8).duplicate4bits) / 255.0,
                        blue: CGFloat(((hexNum & 0x00F0) >> 4).duplicate4bits) / 255.0,
                        alpha: CGFloat((hexNum & 0x000F).duplicate4bits) / 255.0)
        case 6:
            self.init(red: CGFloat((hexNum & 0xFF0000) >> 16) / 255.0,
                        green: CGFloat((hexNum & 0x00FF00) >> 8) / 255.0,
                        blue: CGFloat((hexNum & 0x0000FF) >> 0) / 255.0,
                        alpha: 1.0)
        case 8:
            self.init(red: CGFloat((hexNum & 0xFF000000) >> 24) / 255.0,
                        green: CGFloat((hexNum & 0x00FF0000) >> 16) / 255.0,
                        blue: CGFloat((hexNum & 0x0000FF00) >> 8) / 255.0,
                        alpha: CGFloat(hexNum & 0x000000FF) / 255.0)
        default:
            self.init()
            return nil
        }
    }
}

extension UIView {

    @discardableResult
    func addGradient(colors: [UIColor],
                     point: (CGPoint, CGPoint) = (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)),
                     locations: [NSNumber] = [0, 1],
                     frame: CGRect = CGRect.zero,
                     radius: CGFloat = 0,
                     at: UInt32 = 0) -> CAGradientLayer {
        let bgLayer1 = CAGradientLayer()
        bgLayer1.colors = colors.map { $0.cgColor }
        bgLayer1.locations = locations
        if frame == .zero {
            bgLayer1.frame = self.bounds
        } else {
            bgLayer1.frame = frame
        }
        bgLayer1.startPoint = point.0
        bgLayer1.endPoint = point.1
        bgLayer1.cornerRadius = radius
        self.layer.insertSublayer(bgLayer1, at: at)
        return bgLayer1
    }

    func addGradient(start: CGPoint = CGPoint(x: 0.5, y: 0),
                     end: CGPoint = CGPoint(x: 0.5, y: 1),
                     colors: [UIColor],
                     locations: [NSNumber] = [0, 1],
                     frame: CGRect = CGRect.zero,
                     radius: CGFloat = 0,
                     at: UInt32 = 0) {
        let bgLayer1 = CAGradientLayer()
        bgLayer1.colors = colors.map { $0.cgColor }
        bgLayer1.locations = locations
        bgLayer1.frame = frame
        bgLayer1.startPoint = start
        bgLayer1.endPoint = end
        bgLayer1.cornerRadius = radius
        self.layer.insertSublayer(bgLayer1, at: at)
    }

    func addGradient(start_color:String,end_color : String,frame : CGRect?=nil,cornerRadius : CGFloat?=0, at: UInt32 = 0){
        var bounds : CGRect = self.bounds
        if let frame = frame {
            bounds = frame
        }
        let bgLayer1 = CAGradientLayer()
        bgLayer1.colors = [UIColor(hexString: start_color)!.cgColor, UIColor(hexString: end_color)!.cgColor]
        bgLayer1.locations = [0, 1]
        bgLayer1.frame = bounds
        bgLayer1.startPoint = CGPoint(x: 0, y: 0.61)
        bgLayer1.endPoint = CGPoint(x: 0.61, y: 0.61)
        bgLayer1.cornerRadius = cornerRadius ?? 0
        self.layer.insertSublayer(bgLayer1, at: at)
    }

    func addGradient(start_color:String,
                     end_color : String,
                     frame : CGRect?=nil,
                     borader: CGFloat = 0,
                     boraderColor: UIColor = .clear,
                     at: UInt32 = 0,
                     corners: UIRectCorner?,
                     radius: CGFloat = 0) {
        var bounds : CGRect = self.bounds
        if let frame = frame {
            bounds = frame
        }
        let bgLayer1 = CAGradientLayer()
        bgLayer1.colors = [UIColor(hexString: start_color)!.cgColor, UIColor(hexString: end_color)!.cgColor]
        bgLayer1.locations = [0, 1]
        bgLayer1.frame = bounds
        bgLayer1.startPoint = CGPoint(x: 0, y: 0.61)
        bgLayer1.endPoint = CGPoint(x: 0.61, y: 0.61)
        bgLayer1.borderColor = boraderColor.cgColor
        bgLayer1.borderWidth = borader
        if corners != nil {
            let cornerPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners!, cornerRadii: CGSize(width: radius, height: radius))
            let radiusLayer = CAShapeLayer()
            radiusLayer.frame = bounds
            radiusLayer.path = cornerPath.cgPath
            bgLayer1.mask = radiusLayer
        }
        self.layer.insertSublayer(bgLayer1, at: at)
    }

    func addGradient(startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
                     start_color:String,
                     endPoint: CGPoint = CGPoint(x: 1, y: 0.5),
                     end_color : String,
                     frame : CGRect? = nil,
                     cornerRadius : CGFloat?=0){
        var bounds : CGRect = self.bounds
        if let frame = frame {
            bounds = frame
        }
        let bgLayer1 = CAGradientLayer()
        bgLayer1.frame = bounds
        bgLayer1.startPoint = startPoint
        bgLayer1.endPoint = endPoint
        bgLayer1.colors = [UIColor(hexString: start_color)!.cgColor, UIColor(hexString: end_color)!.cgColor]
        bgLayer1.locations = [0, 1]
        bgLayer1.cornerRadius = cornerRadius ?? 0
        self.layer.addSublayer(bgLayer1)
    }

    func addVerticalGradient(start_color:String,end_color : String,frame : CGRect?=nil,cornerRadius : CGFloat?=0){
        var bounds : CGRect = self.bounds
        if let frame = frame {
            bounds = frame
        }
        let bgLayer1 = CAGradientLayer()
        bgLayer1.colors = [UIColor(hexString: start_color)!.cgColor, UIColor(hexString: end_color)!.cgColor]
        bgLayer1.locations = [0, 1]
        bgLayer1.frame = bounds
        bgLayer1.startPoint = CGPoint(x: 0.5, y: 0)
        bgLayer1.endPoint = CGPoint(x: 1, y: 1)
        bgLayer1.cornerRadius = cornerRadius ?? 0
        self.layer.insertSublayer(bgLayer1, at: 0)
    }

    //将当前视图转为UIImage
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

private extension Int {
    var duplicate4bits: Int {
        return self << 4 + self
    }
}
