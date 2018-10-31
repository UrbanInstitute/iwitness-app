#import "AnalyticsTracker.h"
#import "Mixpanel.h"

static AnalyticsTracker *__sharedAnalyticsTracker = nil;

@interface AnalyticsTracker ()
@property (nonatomic, strong) Mixpanel *mixpanel;
@end

@implementation AnalyticsTracker

+ (instancetype)sharedInstance {
    if (!__sharedAnalyticsTracker) {
#if TARGET_IPHONE_SIMULATOR
        Mixpanel *mixpanel = nil;
#else
        NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"configuration" withExtension:@"plist"]];
        Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:configuration[@"mixpanelToken"]];
#endif
        __sharedAnalyticsTracker = [[AnalyticsTracker alloc] initWithMixpanel:mixpanel];
    }
    return __sharedAnalyticsTracker;
}

- (instancetype)initWithMixpanel:(Mixpanel *)mixpanel {
    if (self = [super init]) {
        self.mixpanel = mixpanel;
    }
    return self;
}

- (void)trackLineupCreation {
    [self.mixpanel track:@"lineup_created"];
}

- (void)trackPresentationStarted {
    [self.mixpanel track:@"presentation_started"];
}

- (void)trackMicrophoneAccessDenied {
    [self.mixpanel track:@"microphone_access_denied"];
}

- (void)trackPresentationPlaybackWithLength:(NSTimeInterval)presentationLength {
    [self.mixpanel track:@"presentation_playback" properties:@{ @"length": @(presentationLength) }];
}

- (void)trackPresentationCompleted {
    [self.mixpanel track:@"presentation_completed"];
}

- (void)trackPresentationVideoRecorderFailureWithError:(NSError *)error {
    [self.mixpanel track:@"video_recorder_failure" properties:[self errorDictFromError:error]];
}

- (void)trackPresentationScreenCaptureFailureWithError:(NSError *)error {
    [self.mixpanel track:@"screen_capture_failure" properties:[self errorDictFromError:error]];
}

- (void)trackPresentationVideoStitcherFailureWithError:(NSError *)error {
    [self.mixpanel track:@"video_stitcher_failure" properties:[self errorDictFromError:error]];
}

- (void)trackPresentationVideoStitcherCompletedWithVideoLength:(NSTimeInterval)length
                                   screenCaptureFrameRate:(float)frameRate
                                    videoRecorderFileSize:(unsigned long long)videoRecorderFileSize
                                    screenCaptureFileSize:(unsigned long long)screenCaptureFileSize
                                    stitchedVideoFileSize:(unsigned long long)stitchedVideoFileSize {
    [self.mixpanel track:@"presentation_stitching_completed" properties:@{ @"video_length": @(length),
                                                                           @"screen_capture_frame_rate": @(roundf(frameRate*10.0f)/10.0f),
                                                                           @"video_recorder_file_size": @(videoRecorderFileSize),
                                                                           @"screen_capture_file_size": @(screenCaptureFileSize),
                                                                           @"stitched_video_file_size": @(stitchedVideoFileSize) }];
}

#pragma mark - private

- (NSDictionary *)errorDictFromError:(NSError *)error {
    return @{ @"domain": error.domain ?: [NSNull null],
              @"code": @(error.code),
              @"description": [error localizedDescription] ?: [NSNull null],
              @"failure_reason": [error localizedFailureReason] ?: [NSNull null] };
}

@end
