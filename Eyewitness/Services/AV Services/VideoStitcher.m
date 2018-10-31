#import "VideoStitcher.h"

NSString * const kVideoStitcherErrorDomain = @"org.arnoldfoundation.Eyewitness.VideoStitcherError";
NSInteger const kVideoStitcherErrorBackgroundTimeExpired = -1;

static const BOOL kCropVideoWhenStitching = NO;
static const CGSize kOutputVideoSize = {720.f, 480.f};

static const CGRect kVideoPreviewFrame = { {144.f, 127.f}, {480.f, 640.f} };

@interface VideoStitcher () <AVVideoCompositionValidationHandling>
@property (nonatomic, strong, readwrite) NSURL *outputURL;
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@property (nonatomic, weak) UIApplication *application;
@end

@implementation VideoStitcher

- (instancetype) init {
    @throw [NSException exceptionWithName:@"BOOM" reason:@"BANG" userInfo:@{}];
}

- (instancetype)initWithApplication:(UIApplication *)application {
    if (self = [super init]) {
        self.application = application;
    }
    return self;
}

+ (instancetype)stitcherWithApplication:(UIApplication *)application {
    return [[self alloc] initWithApplication:application];
}


- (KSPromise *)stitchCameraCaptureAtURL:(NSURL *)cameraURL withScreenCaptureAtURL:(NSURL *)screenURL outputURL:(NSURL *)outputURL videoPreviewTimeRange:(CMTimeRange)videoPreviewTimeRange excludeCameraVideo:(BOOL)excludeCameraVideo {
    self.outputURL = outputURL;

    KSDeferred *deferred = [KSDeferred defer];
    AVMutableComposition *composition = [AVMutableComposition composition];

    AVURLAsset *cameraAsset = [AVURLAsset URLAssetWithURL:cameraURL options:nil];
    AVAssetTrack *cameraVideoAssetTrack = [[cameraAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];

    AVURLAsset *screenCaptureAsset = [AVURLAsset URLAssetWithURL:screenURL options:nil];

    NSError *error = nil;

    AVMutableCompositionTrack *cameraVideoTrack = nil;
    if(!excludeCameraVideo) {
        cameraVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        if (![cameraVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, cameraAsset.duration) ofTrack:cameraVideoAssetTrack atTime:kCMTimeZero error:&error]) {
            [deferred rejectWithError:error];
            return deferred.promise;
        }
    }

    AVMutableCompositionTrack *cameraAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    if (cameraAudioTrack && ![cameraAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, cameraAsset.duration) ofTrack:[[cameraAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:&error]) {
        [deferred rejectWithError:error];
        return deferred.promise;
    }

    AVMutableCompositionTrack *screenCaptureTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    if (![screenCaptureTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, screenCaptureAsset.duration) ofTrack:[[screenCaptureAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:&error]) {
        [deferred rejectWithError:error];
        return deferred.promise;
    }

    AVMutableCompositionTrack *videoPreviewTrack = nil;
    if (!excludeCameraVideo && CMTIMERANGE_IS_VALID(videoPreviewTimeRange) && !CMTIMERANGE_IS_EMPTY(videoPreviewTimeRange)) {
        videoPreviewTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        if (![videoPreviewTrack insertTimeRange:videoPreviewTimeRange ofTrack:cameraVideoAssetTrack atTime:videoPreviewTimeRange.start error:&error]) {
            [deferred rejectWithError:error];
            return deferred.promise;
        }
    }

    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:cameraAsset];
    mutableVideoComposition.renderSize = kOutputVideoSize;

    CGFloat screenCaptureToStitchedVideoScale = mutableVideoComposition.renderSize.height / screenCaptureTrack.naturalSize.height;
    CGFloat screenCaptureScale = screenCaptureTrack.naturalSize.width/CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat screenCaptureWidth = (screenCaptureTrack.naturalSize.width*screenCaptureToStitchedVideoScale);
    CGFloat screenCaptureXTranslation = mutableVideoComposition.renderSize.width - screenCaptureWidth;

    CGAffineTransform screenCaptureTransform = CGAffineTransformScale(CGAffineTransformMakeTranslation(screenCaptureXTranslation, 0.0f), screenCaptureToStitchedVideoScale, screenCaptureToStitchedVideoScale);

    CGFloat availableWidthForCamera = mutableVideoComposition.renderSize.width-screenCaptureWidth;

    AVMutableVideoCompositionLayerInstruction *cameraLayerInstruction = nil;

    if(!excludeCameraVideo) {
        CGAffineTransform cameraTransform;

        if (kCropVideoWhenStitching) {
            CGFloat cameraScale = availableWidthForCamera / cameraVideoTrack.naturalSize.height;
            CGFloat verticalShift = -(cameraVideoTrack.naturalSize.width - mutableVideoComposition.renderSize.height/cameraScale)/2;
            cameraTransform = CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), cameraScale, cameraScale), verticalShift, -cameraVideoTrack.naturalSize.height);
        }
        else {
            CGFloat cameraScale = mutableVideoComposition.renderSize.height / cameraVideoTrack.naturalSize.width;
            CGFloat rotatedCameraWidth = cameraVideoTrack.naturalSize.height*cameraScale;
            CGFloat horizontalShift = -((availableWidthForCamera-rotatedCameraWidth)/2)/cameraScale;
            cameraTransform = CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI_2), cameraScale, cameraScale), 0.0f, -cameraVideoTrack.naturalSize.height+horizontalShift);
        }

        cameraLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:cameraVideoTrack];
        [cameraLayerInstruction setTransform:cameraTransform atTime:kCMTimeZero];
    }

    AVMutableVideoCompositionLayerInstruction *screenCaptureLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:screenCaptureTrack];
    [screenCaptureLayerInstruction setTransform:screenCaptureTransform atTime:kCMTimeZero];

    AVMutableVideoCompositionLayerInstruction *videoPreviewLayerInstruction = nil;
    if (videoPreviewTrack) {
        videoPreviewLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoPreviewTrack];
        CGFloat videoPreviewScale = kVideoPreviewFrame.size.width / videoPreviewTrack.naturalSize.height;

        CGFloat videoPreviewOriginallyDisplayedHeight = kVideoPreviewFrame.size.width / videoPreviewTrack.naturalSize.height * videoPreviewTrack.naturalSize.width;

        CGFloat videoPreviewYShift = (kVideoPreviewFrame.size.height - videoPreviewOriginallyDisplayedHeight) / 2;

        CGAffineTransform videoPreviewToScreenCaptureTransform = CGAffineTransformScale(CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -cameraVideoTrack.naturalSize.height-screenCaptureXTranslation),
                                                                                        videoPreviewScale * screenCaptureToStitchedVideoScale * screenCaptureScale,
                                                                                        videoPreviewScale * screenCaptureToStitchedVideoScale * screenCaptureScale);
        CGAffineTransform scaledDownTransform = CGAffineTransformTranslate(videoPreviewToScreenCaptureTransform,
                                                                           (kVideoPreviewFrame.origin.y + videoPreviewYShift) / videoPreviewScale,
                                                                           kVideoPreviewFrame.origin.x / videoPreviewScale);

        [videoPreviewLayerInstruction setTransform:scaledDownTransform atTime:kCMTimeZero];

        [videoPreviewLayerInstruction setOpacity:0.f atTime:kCMTimeZero];
        [videoPreviewLayerInstruction setOpacity:1.f atTime:videoPreviewTimeRange.start];
        [videoPreviewLayerInstruction setOpacity:0.f atTime:CMTimeRangeGetEnd(videoPreviewTimeRange)];
    }

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);

    NSMutableArray *layerInstructions = [@[ screenCaptureLayerInstruction ] mutableCopy];

    if (cameraLayerInstruction) {
        [layerInstructions insertObject:cameraLayerInstruction atIndex:0];
    }

    if (videoPreviewLayerInstruction) {
        [layerInstructions insertObject:videoPreviewLayerInstruction atIndex:0];
    }

    instruction.layerInstructions = layerInstructions;

    mutableVideoComposition.instructions = @[ instruction ];
    mutableVideoComposition.animationTool = [self makeCAToolForVideoPreviewOverlayWithTimeRange:videoPreviewTimeRange screenCaptureTransform:screenCaptureTransform compositionSize:mutableVideoComposition.renderSize];

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.videoComposition = mutableVideoComposition;

    self.exportSession = exportSession;

    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];

    UIBackgroundTaskIdentifier taskIdentifier = [self.application beginBackgroundTaskWithExpirationHandler:^{
        [self.exportSession cancelExport];
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
        [deferred rejectWithError:[NSError errorWithDomain:kVideoStitcherErrorDomain code:kVideoStitcherErrorBackgroundTimeExpired userInfo:@{ NSLocalizedDescriptionKey: @"Ran out of time to finish stitching in the background." }]];
    }];

    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exportSession.error) {
                [deferred rejectWithError:exportSession.error];
            } else {
                [deferred resolveWithValue:outputURL];
            }
            [self.application endBackgroundTask:taskIdentifier];
        });
    }];
    return deferred.promise;
}

- (float)progress {
    return self.exportSession.progress;
}

- (AVAssetExportSessionStatus)status {
    return self.exportSession.status;
}

#pragma mark - private

- (AVVideoCompositionCoreAnimationTool *)makeCAToolForVideoPreviewOverlayWithTimeRange:(CMTimeRange)videoPreviewTimeRange screenCaptureTransform:(CGAffineTransform)screenCaptureTransform compositionSize:(CGSize)compositionSize {
    CALayer *videoPreviewOverlayLayer = [CALayer layer];
    videoPreviewOverlayLayer.contents = (id)[UIImage imageNamed:@"video-preview-overlay"].CGImage;
    videoPreviewOverlayLayer.anchorPoint = CGPointZero;
    CGFloat screenScale = UIScreen.mainScreen.scale;

    videoPreviewOverlayLayer.frame = CGRectMake(0.f, 0.f, kVideoPreviewFrame.size.width * screenScale, kVideoPreviewFrame.size.height * screenScale);

    CGFloat flippedYPositionOfVideoPreview = CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(kVideoPreviewFrame) - CGRectGetMinY(kVideoPreviewFrame);
    videoPreviewOverlayLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransformTranslate(screenCaptureTransform, CGRectGetMinX(kVideoPreviewFrame) * screenScale, flippedYPositionOfVideoPreview * screenScale));
    videoPreviewOverlayLayer.beginTime = CMTimeGetSeconds(videoPreviewTimeRange.start);
    videoPreviewOverlayLayer.duration = CMTimeGetSeconds(videoPreviewTimeRange.duration);

    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];

    parentLayer.frame = videoLayer.frame = CGRectMake(0.f, 0.f, compositionSize.width, compositionSize.height);

    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:videoPreviewOverlayLayer];

    return [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

@end
