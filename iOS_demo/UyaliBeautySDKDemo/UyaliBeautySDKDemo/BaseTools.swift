//
//  BaseTools.swift
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/3/28.
//

import Foundation

private func inputPixelFormat() -> OSType {
    return kCVPixelFormatType_32BGRA
}

private func bitmapInfoWithPixelFormatType(inputPixelFormat: OSType, hasAlpha: Bool) -> UInt32 {
    if inputPixelFormat == kCVPixelFormatType_32BGRA {
        var bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        if !hasAlpha {
            bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        }
        return bitmapInfo
    } else if inputPixelFormat == kCVPixelFormatType_32ARGB {
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        return bitmapInfo
    } else {
        print("not support the format")
        return 0
    }
}

private func CGImageContainsAlpha(cgImage: CGImage?) -> Bool {
    if cgImage == nil {
        return false
    }
    let alphaInfo = cgImage!.alphaInfo
    let hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
    return hasAlpha
}
///UIImage转CVPixelBuffer
public func convertUIImageToCVPixelBuffer(image: UIImage) -> CVPixelBuffer? {
    
    let cgImage = image.cgImage
    
    let hasAlpha = CGImageContainsAlpha(cgImage: cgImage)
    
    var keyCallBacks = kCFTypeDictionaryKeyCallBacks
    var valueCallBacks = kCFTypeDictionaryValueCallBacks
    let empty = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, &keyCallBacks, &valueCallBacks)
    
    let options = [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferIOSurfacePropertiesKey: empty!] as CFDictionary
    
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), inputPixelFormat(), options, &pixelBuffer)
    
    if status == kCVReturnSuccess && pixelBuffer != nil {
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pixelBuffer!)
        if pxdata != nil {
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            
            let bitmapInfo = bitmapInfoWithPixelFormatType(inputPixelFormat: inputPixelFormat(), hasAlpha: hasAlpha)
            let context = CGContext(data: pxdata,
                                    width: Int(image.size.width),
                                    height: Int(image.size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                    space: rgbColorSpace,
                                    bitmapInfo: bitmapInfo)
            if context != nil {
                context!.draw(cgImage!, in: CGRect(x: 0, y: 0, width: cgImage!.width, height: cgImage!.height))
                CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            }
        }
    }
    
    return pixelBuffer
}

///UIImage转CVPixelBuffer
public func getPixelBufferFromUIImage(image:UIImage) -> CVPixelBuffer? {
//    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    var pixelBuffer : CVPixelBuffer?
    let options = [
        kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
    ] as CFDictionary
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32BGRA, options, &pixelBuffer)

    guard (status == kCVReturnSuccess) else {
        return nil
    }

    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

    let videoRecContext = CGContext(data: pixelData,
                                width: Int(image.size.width),
                                height: Int(image.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    let attachments = [
        kCVImageBufferColorPrimariesKey: kCVImageBufferColorPrimaries_ITU_R_709_2,
        kCVImageBufferTransferFunctionKey: kCVImageBufferTransferFunction_ITU_R_709_2,
        kCVImageBufferYCbCrMatrixKey: kCVImageBufferYCbCrMatrix_ITU_R_601_4,
    ] as CFDictionary
    CVBufferSetAttachments(pixelBuffer!, attachments, CVAttachmentMode.shouldPropagate)
    
    videoRecContext?.translateBy(x: 0, y: image.size.height)
    videoRecContext?.scaleBy(x: 1.0, y: -1.0)

    UIGraphicsPushContext(videoRecContext!)
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
}

///CVPixelBuffer转UIImage
public func getUIImageFromCVPixelBuffer(pixelBuffer: CVPixelBuffer) -> UIImage? {
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
        let imageRef = context.makeImage() else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return nil
    }
    let newImage = UIImage(cgImage: imageRef)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    return newImage
}

public func convertUIImageToCIImage(image: UIImage) -> CIImage {
    var ciImage = image.ciImage
    if ciImage == nil {
        let data = image.pngData()!
        ciImage = CIImage(data: data)
    }
    return ciImage!
}

public func convertCIImageToCVPixelBuffer(ciImage: CIImage) -> CVPixelBuffer? {
    
    var keyCallBacks = kCFTypeDictionaryKeyCallBacks
    var valueCallBacks = kCFTypeDictionaryValueCallBacks
    let empty = CFDictionaryCreate(kCFAllocatorDefault, nil, nil, 0, &keyCallBacks, &valueCallBacks)
    
    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferIOSurfacePropertiesKey: empty!] as CFDictionary
    var pixelBuffer : CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(ciImage.extent.width), Int(ciImage.extent.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
    guard (status == kCVReturnSuccess) else {
        return nil
    }

    return pixelBuffer
}
