//
//  ImageTools.h
//  UyaliBeautySDKDemo
//
//  Created by S weet on 2023/3/28.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageTools : NSObject

- (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img;

@end

NS_ASSUME_NONNULL_END
