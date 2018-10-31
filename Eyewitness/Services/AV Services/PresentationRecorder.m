#import "PresentationRecorder.h"
#import "VideoRecorder.h"
#import "ScreenCaptureService.h"
#import "Presentation.h"
#import "StitchingQueue.h"
#import "LineupReviewWriter.h"

@interface PresentationRecorder ()
@property (nonatomic, weak, readwrite) UIApplication *application;
@property (nonatomic, strong, readwrite) Presentation *presentation;
@property (nonatomic, strong, readwrite) VideoRecorder *videoRecorder;
@property (nonatomic, strong, readwrite) ScreenCaptureService *screenCaptureService;
@property (nonatomic, strong) StitchingQueue *stitchingQueue;

@property (nonatomic, readwrite, getter=isRecording) BOOL recording;
@property (nonatomic) CFTimeInterval startTime;
@property (nonatomic, strong) NSMutableArray *instructionsPlaybackStartAndEndTimes;
@property (nonatomic) CMTimeRange videoPreviewTimeRange;
@end

@implementation PresentationRecorder

- (instancetype)initWithApplication:(UIApplication *)application
                       presentation:(Presentation *)presentation
                      videoRecorder:(VideoRecorder *)videoRecorder
               screenCaptureService:(ScreenCaptureService *)screenCaptureService
                     stitchingQueue:(StitchingQueue *)stitchingQueue
                 lineupReviewWriter:(LineupReviewWriter *)lineupReviewWriter {
    if (self = [super init]) {
        self.application = application;
        self.presentation = presentation;
        self.videoRecorder = videoRecorder;
        self.screenCaptureService = screenCaptureService;
        self.stitchingQueue = stitchingQueue;
        self.instructionsPlaybackStartAndEndTimes = [NSMutableArray array];
        self.videoPreviewTimeRange = kCMTimeRangeInvalid;
        self.lineupReviewWriter = lineupReviewWriter;
    }
    return self;
}

- (void)startRecordingWithStartTime:(CFTimeInterval)startTime {
    [self.videoRecorder startRecordingToOutputURL:self.presentation.temporaryCameraRecordingURL];
    [self.screenCaptureService startCapturingScreenToURL:self.presentation.temporaryScreenCaptureURL];

    self.startTime = startTime;
    self.recording = YES;
}

- (KSPromise *)stopRecording {
    NSLog(@"================> Frame rate %g fps", [self.screenCaptureService actualFrameCaptureRate]);
    UIBackgroundTaskIdentifier taskIdentifier = [self.application beginBackgroundTaskWithName:@"PresentationPostProcessing" expirationHandler:^{}];

    KSDeferred *stopRecordingDeferred = [KSDeferred defer];

    KSPromise *videoPromise = [self.videoRecorder stopRecording];
    KSPromise *screenCapturePromise = [self.screenCaptureService stopCapturing];

    [self.lineupReviewWriter writeLineupReviewForPresentation:self.presentation];

    [[KSPromise when:@[videoPromise, screenCapturePromise]] then:^id(NSArray *values) {
        [self.presentation finalizeWithStitchingQueue:self.stitchingQueue videoPreviewTimeRange:self.videoPreviewTimeRange];
        [self.application endBackgroundTask:taskIdentifier];
        self.recording = NO;
        [stopRecordingDeferred resolveWithValue:nil];
        return nil;
    } error:^id(NSError *error) {
        if (videoPromise.rejected && screenCapturePromise.fulfilled) {
            [self.presentation finalizeWithoutCameraCapture];
        } else if (videoPromise.fulfilled && screenCapturePromise.rejected) {
            [self.presentation finalizeWithoutScreenCapture];
        } else {
            NSError *recordingFailedError = [NSError errorWithDomain:kPresentationRecorderErrorDomain
                                                                code:PresentationRecorderErrorRecordingFailed
                                                            userInfo:@{NSLocalizedFailureReasonErrorKey: @"both video recording and screen capture failed"}];
            [stopRecordingDeferred rejectWithError:recordingFailedError];
        }

        self.recording = NO;
        [self.application endBackgroundTask:taskIdentifier];
        if (!stopRecordingDeferred.promise.rejected) {
            [stopRecordingDeferred resolveWithValue:nil];
        }

        return nil;
    }];
    return stopRecordingDeferred.promise;
}

- (void)recordVideoPreviewEndTime:(CFTimeInterval)endTime {
    CMTime endCMTime = CMTimeMakeWithSeconds(endTime-self.startTime, 600);
    self.videoPreviewTimeRange = CMTimeRangeMake(kCMTimeZero, endCMTime);
}

- (void)recordInstructionsPlaybackStartTime:(CFTimeInterval)startTime {
    [self.instructionsPlaybackStartAndEndTimes addObject:@(startTime)];
}

- (void)recordInstructionsPlaybackEndTime:(CFTimeInterval)endTime {
    [self.instructionsPlaybackStartAndEndTimes addObject:@(endTime)];
}

@end
