//
//  ImageTools.m
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/3/28.
//

#import "ImageTools.h"

@implementation ImageTools

static OSType inputPixelFormat(void){
    return kCVPixelFormatType_32BGRA;
}

static uint32_t bitmapInfoWithPixelFormatType(OSType inputPixelFormat, bool hasAlpha){
    
    if (inputPixelFormat == kCVPixelFormatType_32BGRA) {
        uint32_t bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedFirst | (uint32_t)kCGBitmapByteOrder32Host;
        if (!hasAlpha) {
            bitmapInfo = (uint32_t)kCGImageAlphaNoneSkipFirst | (uint32_t)kCGBitmapByteOrder32Host;
        }
        return bitmapInfo;
    }else if (inputPixelFormat == kCVPixelFormatType_32ARGB) {
        uint32_t bitmapInfo = (uint32_t)kCGImageAlphaPremultipliedFirst | (uint32_t)kCGBitmapByteOrder32Big;
        return bitmapInfo;
    }else{
        NSLog(@"不支持此格式");
        return 0;
    }
}

// alpha的判断
BOOL CGImageRefContainsAlpha(CGImageRef imageRef) {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

// 此方法能还原真实的图片
- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img {
    CGSize size = img.size;
    CGImageRef image = [img CGImage];
    
    BOOL hasAlpha = CGImageRefContainsAlpha(image);
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferMetalCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLESCompatibilityKey,
                             empty, kCVPixelBufferIOSurfacePropertiesKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, inputPixelFormat(), (__bridge CFDictionaryRef) options, &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    uint32_t bitmapInfo = bitmapInfoWithPixelFormatType(inputPixelFormat(), (bool)hasAlpha);
    
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, CVPixelBufferGetBytesPerRow(pxbuffer), rgbColorSpace, bitmapInfo);
    NSParameterAssert(context);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    return pxbuffer;
}

@end
