//
//  FaceLandmarks.h
//  美颜测试
//
//  Created by S weet on 2023/1/3.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceLandmarks : NSObject

@property (nonatomic, assign)BOOL showLandmarks;
@property (nonatomic, strong)UIView *renderView;

@property (atomic, copy)NSArray<NSValue *> *landmarks;
@property (atomic, copy)NSArray<NSArray<NSValue *> *> *allLandmarks;
@property (atomic, copy)NSArray<NSValue *> *youtuLandmarks;
@property (nonatomic, copy, readonly)NSString *debugInfo;

- (void)getFaceLandmarks:(CVPixelBufferRef)pixelBuffer;
- (NSArray<NSValue *> *)getFaceLandmarksSynchronously:(CVPixelBufferRef)pixelBuffer;
- (NSArray<NSArray<NSValue *> *> *)getFaceLandmarkSetsSynchronously:(CVPixelBufferRef)pixelBuffer;
- (NSArray<NSValue *> *)getYoutuFaceLandmarksSynchronously:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
