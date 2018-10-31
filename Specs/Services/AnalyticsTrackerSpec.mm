#import "AnalyticsTracker.h"
#import "VideoRecorder.h"
#import "ScreenCaptureService.h"
#import "VideoStitcher.h"
#import "Mixpanel.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AnalyticsTrackerSpec)

describe(@"AnalyticsTracker", ^{
    __block AnalyticsTracker *tracker;
    __block Mixpanel *mixpanel;

    beforeEach(^{
        mixpanel = fake_for([Mixpanel class]);
        mixpanel stub_method(@selector(track:));
        mixpanel stub_method(@selector(track:properties:));

        tracker = [[AnalyticsTracker alloc] initWithMixpanel:mixpanel];
    });

    it(@"+sharedInstance should return the same instance", ^{
        [AnalyticsTracker sharedInstance] should be_same_instance_as([AnalyticsTracker sharedInstance]);
    });

    describe(@"tracking lineup creation", ^{
        beforeEach(^{
            [tracker trackLineupCreation];
        });

        it(@"should send an event tracking lineup creation", ^{
            mixpanel should have_received(@selector(track:)).with(@"lineup_created");
        });
    });

    describe(@"tracking a presentation having started", ^{
        beforeEach(^{
            [tracker trackPresentationStarted];
        });

        it(@"should send an event tracking presentation starting", ^{
            mixpanel should have_received(@selector(track:)).with(@"presentation_started");
        });
    });

    describe(@"tracking microphone access having been denied", ^{
        beforeEach(^{
            [tracker trackMicrophoneAccessDenied];
        });

        it(@"should send an event tracking the denial of microphone access", ^{
            mixpanel should have_received(@selector(track:)).with(@"microphone_access_denied");
        });
    });

    describe(@"tracking presentation playback", ^{
        beforeEach(^{
            [tracker trackPresentationPlaybackWithLength:60];
        });

        it(@"should send an event tracking the presentation playback", ^{
            mixpanel should have_received(@selector(track:properties:)).with(@"presentation_playback", @{ @"length": @(60) });
        });
    });

    describe(@"tracking a presentation having been completed", ^{
        beforeEach(^{
            [tracker trackPresentationCompleted];
        });

        it(@"should send an event tracking the presentation being completed", ^{
            mixpanel should have_received(@selector(track:)).with(@"presentation_completed");
        });
    });

    describe(@"tracking video recorder failure", ^{
        NSError *error = [NSError errorWithDomain:kVideoRecorderErrorDomain
                                             code:1
                                         userInfo:@{ NSLocalizedDescriptionKey: @"Whoops",
                                                     NSLocalizedFailureReasonErrorKey: @"Insufficient cats" }];

        beforeEach(^{
            [tracker trackPresentationVideoRecorderFailureWithError:error
             ];
        });

        it(@"should send an event tracking the failure", ^{
            mixpanel should have_received(@selector(track:properties:)).with(@"video_recorder_failure", @{ @"domain": @"org.arnoldfoundation.Eyewitness.VideoRecorderError",
                                                                                                           @"code": @(1),
                                                                                                           @"description": @"Whoops",
                                                                                                           @"failure_reason": @"Insufficient cats" });
        });
    });

    describe(@"tracking screen capture failure", ^{
        NSError *error = [NSError errorWithDomain:kScreenCaptureServiceErrorDomain
                                             code:2
                                         userInfo:@{ NSLocalizedDescriptionKey: @"Uh Oh",
                                                     NSLocalizedFailureReasonErrorKey: @"The screen got away" }];

        beforeEach(^{
            [tracker trackPresentationScreenCaptureFailureWithError:error];
        });

        it(@"should send an event tracking the failure", ^{
            mixpanel should have_received(@selector(track:properties:)).with(@"screen_capture_failure", @{ @"domain": @"org.arnoldfoundation.Eyewitness.ScreenCaptureServiceError",
                                                                                                           @"code": @(2),
                                                                                                           @"description": @"Uh Oh",
                                                                                                           @"failure_reason": @"The screen got away" });
        });
    });

    describe(@"tracking video stitcher failure", ^{
        NSError *error = [NSError errorWithDomain:kVideoStitcherErrorDomain
                                             code:3
                                         userInfo:@{ NSLocalizedDescriptionKey: @"Better luck next time",
                                                     NSLocalizedFailureReasonErrorKey: @"Needle&Thread not found" }];

        beforeEach(^{
            [tracker trackPresentationVideoStitcherFailureWithError:error];
        });

        it(@"should send an event tracking the failure", ^{
            mixpanel should have_received(@selector(track:properties:)).with(@"video_stitcher_failure", @{ @"domain": @"org.arnoldfoundation.Eyewitness.VideoStitcherError",
                                                                                                           @"code": @(3),
                                                                                                           @"description": @"Better luck next time",
                                                                                                           @"failure_reason": @"Needle&Thread not found" });
        });
    });

    describe(@"tracking presentation video stitching completion", ^{
        beforeEach(^{
            [tracker trackPresentationVideoStitcherCompletedWithVideoLength:60 screenCaptureFrameRate:12.3456789 videoRecorderFileSize:12345 screenCaptureFileSize:23456 stitchedVideoFileSize:123456];
        });

        it(@"should send an event tracking the stitching being completed", ^{
            mixpanel should have_received(@selector(track:properties:)).with(@"presentation_stitching_completed", @{ @"video_length": @(60),
                                                                                                                     @"screen_capture_frame_rate": @(12.3f),
                                                                                                                     @"video_recorder_file_size": @(12345),
                                                                                                                     @"screen_capture_file_size": @(23456),
                                                                                                                     @"stitched_video_file_size": @(123456) });
        });
    });
});

SPEC_END
