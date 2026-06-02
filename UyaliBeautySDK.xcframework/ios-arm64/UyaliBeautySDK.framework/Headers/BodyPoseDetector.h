//
//  BodyPoseDetector.h
//  UyaliBeautySDK
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^BodyPoseCompletion)(NSArray<NSValue *> *landmarks);

@interface BodyPoseDetector : NSObject

@property (atomic, copy, readonly) NSArray<NSValue *> *landmarks;
@property (nonatomic, copy, readonly) NSString *debugInfo;

- (BOOL)loadNeuralNetworkModel;
- (void)getBodyLandmarks:(CVPixelBufferRef)pixelBuffer;
- (void)getBodyLandmarks:(CVPixelBufferRef)pixelBuffer completion:(nullable BodyPoseCompletion)completion;
- (NSArray<NSValue *> *)getBodyLandmarksSynchronously:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
