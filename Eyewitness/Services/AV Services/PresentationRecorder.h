@class Presentation, VideoRecorder, ScreenCaptureService, StitchingQueue, LineupReviewWriter;

static NSString *kPresentationRecorderErrorDomain = @"org.arnoldfoundation.Eyewitness.PresentationRecorderError";

typedef NS_ENUM(NSUInteger, PresentationRecorderError) {
    PresentationRecorderErrorRecordingFailed = 0,
    PresentationRecorderErrorStitchingFailed
};

@interface PresentationRecorder : NSObject

@property (nonatomic, readonly, getter=isRecording) BOOL recording;

@property (nonatomic, strong, readonly) Presentation *presentation;
@property (nonatomic, strong, readonly) VideoRecorder *videoRecorder;
@property (nonatomic, strong, readonly) ScreenCaptureService *screenCaptureService;
@property(nonatomic, strong) LineupReviewWriter *lineupReviewWriter;

- (instancetype)initWithApplication:(UIApplication *)application
                       presentation:(Presentation *)presentation
                      videoRecorder:(VideoRecorder *)videoRecorder
               screenCaptureService:(ScreenCaptureService *)screenCaptureService
                     stitchingQueue:(StitchingQueue *)stitchingQueue
                 lineupReviewWriter:(LineupReviewWriter *)lineupReviewWriter;

- (void)startRecordingWithStartTime:(CFTimeInterval)startTime;
- (KSPromise *)stopRecording;

- (void)recordVideoPreviewEndTime:(CFTimeInterval)startTime;
- (void)recordInstructionsPlaybackStartTime:(CFTimeInterval)startTime;
- (void)recordInstructionsPlaybackEndTime:(CFTimeInterval)endTime;

@end
