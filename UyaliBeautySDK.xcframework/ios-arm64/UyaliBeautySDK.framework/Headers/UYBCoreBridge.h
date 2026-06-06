#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UYBLandmarkProfile) {
    UYBLandmarkProfileFace = 0,
    UYBLandmarkProfileSmallMask = 1,
    UYBLandmarkProfileReshape = 2,
    UYBLandmarkProfileMakeup = 3,
};

typedef NS_ENUM(NSInteger, UYBMakeupFloatDataKind) {
    UYBMakeupFloatDataKindFaceModelTextureVertices = 0,
    UYBMakeupFloatDataKindEyeMaskTextureVertices = 1,
    UYBMakeupFloatDataKindTeethMaskTextureVertices = 2,
    UYBMakeupFloatDataKindPupilTextureVertices = 3,
    UYBMakeupFloatDataKindLipMaskTextureVertices = 4,
};

typedef NS_ENUM(NSInteger, UYBMakeupIndexDataKind) {
    UYBMakeupIndexDataKindEyebrowModel = 0,
    UYBMakeupIndexDataKindEyeModel = 1,
    UYBMakeupIndexDataKindBlushModel = 2,
    UYBMakeupIndexDataKindLipModel = 3,
    UYBMakeupIndexDataKindEyeMask = 4,
    UYBMakeupIndexDataKindTeethMask = 5,
    UYBMakeupIndexDataKindPupil = 6,
    UYBMakeupIndexDataKindLipMask = 7,
};

@interface UYBBodyContourResult : NSObject

@property (nonatomic, copy, readonly) NSArray<NSValue *> *points;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *labels;

- (instancetype)initWithPoints:(NSArray<NSValue *> *)points
                        labels:(NSArray<NSNumber *> *)labels NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface UYBMeshResult : NSObject

@property (nonatomic, copy, readonly) NSArray<NSNumber *> *positions;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *textureCoordinates;

- (instancetype)initWithPositions:(NSArray<NSNumber *> *)positions
               textureCoordinates:(NSArray<NSNumber *> *)textureCoordinates NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface UYBDarkCircleGeometryResult : NSObject

@property (nonatomic, copy, readonly) NSArray<UYBMeshResult *> *strips;
@property (nonatomic, assign, readonly) float referenceYOffset;

- (instancetype)initWithStrips:(NSArray<UYBMeshResult *> *)strips
              referenceYOffset:(float)referenceYOffset NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface UYBLandmarkStabilizer : NSObject

- (instancetype)initWithProfile:(UYBLandmarkProfile)profile
                 holdFrameCount:(NSInteger)holdFrameCount
         unstableHoldFrameCount:(NSInteger)unstableHoldFrameCount
                    clampOutput:(BOOL)clampOutput
              holdUnstableJumps:(BOOL)holdUnstableJumps
                  minPointCount:(NSInteger)minPointCount NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSArray<NSValue *> *)stabilizeLandmarks:(NSArray<NSValue *> *)landmarks;
- (NSArray<NSValue *> *)currentLandmarks;
- (void)reset;
- (BOOL)hasStableLandmarks;

@end

@interface UYBMultiFaceLandmarkStabilizer : NSObject

- (instancetype)initWithProfile:(UYBLandmarkProfile)profile
                 holdFrameCount:(NSInteger)holdFrameCount
         unstableHoldFrameCount:(NSInteger)unstableHoldFrameCount
                    clampOutput:(BOOL)clampOutput
              holdUnstableJumps:(BOOL)holdUnstableJumps
                  minPointCount:(NSInteger)minPointCount NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSArray<NSArray<NSValue *> *> *)stabilizeLandmarkSets:(NSArray<NSArray<NSValue *> *> *)landmarkSets;
- (NSArray<NSArray<NSValue *> *> *)currentLandmarkSets;
- (void)reset;
- (BOOL)hasStableLandmarks;

@end

@interface UYBBodyLandmarkStabilizer : NSObject

- (NSArray<NSValue *> *)stabilizeLandmarks:(NSArray<NSValue *> *)landmarks
                            holdFrameCount:(NSInteger)holdFrameCount
    NS_SWIFT_NAME(stabilize(_:holdFrameCount:));
- (NSArray<NSValue *> *)currentLandmarks;
- (void)reset;
- (BOOL)hasStableLandmarks;

@end

@interface UYBReshapeControlStabilizer : NSObject

- (NSArray<NSValue *> *)stabilizePoints:(NSArray<NSValue *> *)points
    NS_SWIFT_NAME(stabilize(_:));
- (void)reset;

@end

@interface UYBEffectFader : NSObject

- (instancetype)initWithAttackStep:(float)attackStep
                       releaseStep:(float)releaseStep NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (float)updateWithObservedLandmarks:(BOOL)observedLandmarks
                      hasObservation:(BOOL)hasObservation
    NS_SWIFT_NAME(update(observedLandmarks:hasObservation:));
- (void)reset;
- (float)alpha;

@end

@interface UYBTeethVisibilityStabilizer : NSObject

- (float)updateWithLandmarks:(NSArray<NSValue *> *)landmarks
                   faceIndex:(NSInteger)faceIndex
    NS_SWIFT_NAME(update(landmarks:faceIndex:));
- (void)reset;
- (void)resetFaceAtIndex:(NSInteger)faceIndex
    NS_SWIFT_NAME(reset(faceIndex:));

@end

@interface UYBDarkCircleGeometryStabilizer : NSObject

- (UYBDarkCircleGeometryResult *)stabilizeStrips:(NSArray<UYBMeshResult *> *)strips
                                referenceYOffset:(float)referenceYOffset
                                       faceIndex:(NSInteger)faceIndex
    NS_SWIFT_NAME(stabilize(strips:referenceYOffset:faceIndex:));
- (void)reset;
- (void)resetFaceAtIndex:(NSInteger)faceIndex
    NS_SWIFT_NAME(reset(faceIndex:));

@end

@interface UYBCoreBridge : NSObject

+ (NSArray<NSValue *> *)compensatedLowerFaceContourFromLandmarks:(NSArray<NSValue *> *)landmarks
                                                           count:(NSInteger)count
                                                       fixedStep:(BOOL)fixedStep
    NS_SWIFT_NAME(compensatedLowerFaceContour(from:count:fixedStep:));

+ (NSArray<NSValue *> *)faceModelPointsFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(faceModelPoints(from:));

+ (NSArray<NSValue *> *)reshapeControlPointsFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(reshapeControlPoints(from:));

+ (NSArray<NSNumber *> *)eyeVerticesFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(eyeVertices(from:));

+ (NSArray<NSNumber *> *)teethVerticesFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(teethVertices(from:));

+ (NSArray<NSNumber *> *)commonMakeupVerticesFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(commonMakeupVertices(from:));

+ (NSArray<NSNumber *> *)lipVerticesFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(lipVertices(from:));

+ (NSArray<NSNumber *> *)pupilVerticesFromLandmarks:(NSArray<NSValue *> *)landmarks
                                              width:(NSInteger)width
                                             height:(NSInteger)height
    NS_SWIFT_NAME(pupilVertices(from:width:height:));

+ (NSArray<NSValue *> *)bodyCoreContourFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(bodyCoreContour(from:));

+ (UYBBodyContourResult *)bodyPartContoursFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(bodyPartContours(from:));

+ (NSArray<NSNumber *> *)scaleIntensities:(NSArray<NSNumber *> *)values
                                     alpha:(float)alpha
    NS_SWIFT_NAME(scaleIntensities(_:alpha:));

+ (float)normalizePercent:(float)value
    NS_SWIFT_NAME(normalizePercent(_:));

+ (float)normalizeSignedHalfPercent:(float)value
    NS_SWIFT_NAME(normalizeSignedHalfPercent(_:));

+ (float)normalizeDarkCirclePercent:(float)value
    NS_SWIFT_NAME(normalizeDarkCirclePercent(_:));

+ (float)makeupStrengthForType:(NSInteger)type
                     intensity:(float)intensity
    NS_SWIFT_NAME(makeupStrength(type:intensity:));

+ (NSArray<NSNumber *> *)makeupFloatData:(UYBMakeupFloatDataKind)kind
    NS_SWIFT_NAME(makeupFloatData(_:));

+ (NSArray<NSNumber *> *)makeupIndexData:(UYBMakeupIndexDataKind)kind
    NS_SWIFT_NAME(makeupIndexData(_:));

+ (NSArray<NSNumber *> *)eyeshadowTextureVerticesForImageName:(NSString *)imageName
    NS_SWIFT_NAME(eyeshadowTextureVertices(forImageName:));

+ (NSInteger)reshapeMaxFaceCount;
+ (NSInteger)reshapePointCountPerFace;
+ (NSInteger)reshapeFaceIntensityCount;
+ (NSInteger)reshapeBodyIntensityCount;
+ (NSInteger)reshapeBodyLandmarkCount;
+ (NSInteger)reshapeMaxBodyContourCount;
+ (float)reshapeWorkingWidth;
+ (float)reshapeMaxWorkingHeight;

+ (BOOL)isPlausibleFaceLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(isPlausibleFaceLandmarks(_:));

+ (BOOL)isPlausibleMakeupLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(isPlausibleMakeupLandmarks(_:));

+ (UYBMeshResult *)faceBlendMeshFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(faceBlendMesh(from:));

+ (NSArray<UYBMeshResult *> *)darkCircleStripsFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(darkCircleStrips(from:));

+ (float)darkCircleReferenceYOffsetFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(darkCircleReferenceYOffset(from:));

+ (float)teethVisibilityScaleFromLandmarks:(NSArray<NSValue *> *)landmarks
    NS_SWIFT_NAME(teethVisibilityScale(from:));

@end

NS_ASSUME_NONNULL_END
