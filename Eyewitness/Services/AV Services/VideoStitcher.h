extern NSString * const kVideoStitcherErrorDomain;
extern NSInteger const kVideoStitcherErrorBackgroundTimeExpired;

@interface VideoStitcher : NSObject

@property (nonatomic, strong, readonly) NSURL *outputURL;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) AVAssetExportSessionStatus status;

+ (instancetype)stitcherWithApplication:(UIApplication *)application;
- (instancetype)initWithApplication:(UIApplication *)application;
- (KSPromise *)stitchCameraCaptureAtURL:(NSURL *)cameraURL withScreenCaptureAtURL:(NSURL *)screenURL outputURL:(NSURL *)outputURL videoPreviewTimeRange:(CMTimeRange)videoPreviewTimeRange excludeCameraVideo:(BOOL)excludeCameraVideo;
@end
