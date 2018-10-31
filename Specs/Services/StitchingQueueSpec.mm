#import "StitchingQueue.h"
#import "CedarAsync.h"
#import "Presentation.h"
#import "StitchingQueueObserver.h"
#import "VideoStitcherProvider.h"
#import "PresentationStore.h"
#import "AnalyticsTracker.h"
#import "Lineup.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(StitchingQueueSpec)

describe(@"StitchingQueue", ^{
    __block StitchingQueue *stitchingQueue;
    __block float stitchingProgress = 0.25f;
    __block Presentation *presentation1;
    __block VideoStitcherProvider *videoStitcherProvider;
    __block PresentationStore *presentationStore;
    __block KSDeferred *deferred;
    NSURL *cameraURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestCameraCapture360x480" withExtension:@"mov"];
    NSURL *screenCaptureURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestScreenCapture" withExtension:@"mov"];
    NSURL *outputURL = [NSURL URLWithString:@"file:///dummy/output/url"];
    CMTimeRange videoPreviewTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(1, 30), CMTimeMakeWithSeconds(5, 30));

    beforeEach(^{
        videoStitcherProvider = nice_fake_for([VideoStitcherProvider class]);
        spy_on([AnalyticsTracker sharedInstance]);
        stitchingQueue = [[StitchingQueue alloc] initWithVideoStitcherProvider:videoStitcherProvider];

        deferred = [KSDeferred defer];
        videoStitcherProvider stub_method(@selector(videoStitcher)).and_do_block(^VideoStitcher *{
            __block VideoStitcher *stitcher = nice_fake_for([VideoStitcher class]);
            stitcher stub_method(@selector(progress)).and_do_block(^float{
                return stitchingProgress;
            });
            stitcher stub_method(@selector(stitchCameraCaptureAtURL:withScreenCaptureAtURL:outputURL:videoPreviewTimeRange:excludeCameraVideo:)).and_return(deferred.promise);
            return stitcher;
        });

        presentationStore = nice_fake_for([PresentationStore class]);

        Lineup *lineup = nice_fake_for([Lineup class]);
        lineup stub_method(@selector(isAudioOnly)).and_return(YES);

        presentation1 = nice_fake_for([Presentation class]);
        presentation1 stub_method(@selector(store)).and_return(presentationStore);
        presentation1 stub_method(@selector(temporaryCameraRecordingURL)).and_return(cameraURL);
        presentation1 stub_method(@selector(temporaryScreenCaptureURL)).and_return(screenCaptureURL);
        presentation1 stub_method(@selector(temporaryStitchingURL)).and_return(outputURL);
        presentation1 stub_method(@selector(UUID)).and_return(@"THIS-IS-ONE-UUID-KINDA-FAKE-BUT-YOU-GEt-THe-IDEA");
        presentation1 stub_method(@selector(videoPreviewTimeRange)).and_return(videoPreviewTimeRange);
        presentation1 stub_method(@selector(lineup)).and_return(lineup);
    });

    sharedExamplesFor(@"when stitching completes", ^(NSDictionary *sharedContext) {
        it(@"should remove the stitcher from the queue", ^{
            [stitchingQueue stitcherForPresentation:presentation1] should be_nil;
        });

        it(@"should ask the presentation to attach the temporary stitched video", ^{
            presentation1 should have_received(@selector(attachStitchedVideo));
        });
    });

    sharedExamplesFor(@"when stitching cancels", ^(NSDictionary *sharedContext) {
        it(@"should remove the stitcher from the queue", ^{
            [stitchingQueue stitcherForPresentation:presentation1] should be_nil;
        });
    });

    describe(@"enqueuing a stitcher", ^{
        beforeEach(^{
            [stitchingQueue enqueueStitcherForPresentation:presentation1];
        });

        it(@"should create a new stitcher", ^{
            videoStitcherProvider should have_received(@selector(videoStitcher));
        });

        it(@"should have the stitcher stitch the videos from the presentation", ^{
            [stitchingQueue stitcherForPresentation:presentation1] should have_received(@selector(stitchCameraCaptureAtURL:withScreenCaptureAtURL:outputURL:videoPreviewTimeRange:excludeCameraVideo:)).with(cameraURL, screenCaptureURL, outputURL, videoPreviewTimeRange, YES);
        });

        describe(@"when stitching is complete", ^{
            beforeEach(^{
                [deferred resolveWithValue:outputURL];
            });

            itShouldBehaveLike(@"when stitching completes");

            it(@"should track the stitched presentation", ^{
                in_time([AnalyticsTracker sharedInstance]) should have_received(@selector(trackPresentationVideoStitcherCompletedWithVideoLength:screenCaptureFrameRate:videoRecorderFileSize:screenCaptureFileSize:stitchedVideoFileSize:));
            });
        });

        describe(@"when stitching is cancelled", ^{
            context(@"when background time runs out", ^{
                beforeEach(^{
                    [deferred rejectWithError:[NSError errorWithDomain:kVideoStitcherErrorDomain code:kVideoStitcherErrorBackgroundTimeExpired userInfo:nil]];
                });

                itShouldBehaveLike(@"when stitching cancels");

                it(@"should not track the failure", ^{
                    [AnalyticsTracker sharedInstance] should_not have_received(@selector(trackPresentationVideoStitcherFailureWithError:));
                });
            });

            context(@"when other errors occur", ^{
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:nil];

                beforeEach(^{
                    [deferred rejectWithError:error];
                });

                itShouldBehaveLike(@"when stitching cancels");

                it(@"should track the failure", ^{
                    [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationVideoStitcherFailureWithError:)).with(error);
                });
            });

        });
    });

    describe(@"accessing stitchers", ^{
        __block Presentation *presentation2;

        beforeEach(^{
            presentation2 = nice_fake_for([Presentation class]);
            presentation2 stub_method(@selector(UUID)).and_return(@"THIS-IS-ANOTHER-UUID-NOT-LIKE-THE-OTHER-ONE");

            [stitchingQueue enqueueStitcherForPresentation:presentation1];
            [stitchingQueue enqueueStitcherForPresentation:presentation2];
        });

        it(@"should return unique stitchers for unique presentations", ^{
            [stitchingQueue stitcherForPresentation:presentation1] should_not be_same_instance_as([stitchingQueue stitcherForPresentation:presentation2]);
        });

        it(@"should return the same stitcher for the same presentation", ^{
            [stitchingQueue stitcherForPresentation:presentation1] should be_same_instance_as([stitchingQueue stitcherForPresentation:presentation1]);
        });
    });

    describe(@"when a queue observer is observing the queue", ^{
        __block id<StitchingQueueObserver> observer;

        beforeEach(^{
            observer = nice_fake_for(@protocol(StitchingQueueObserver));
            [stitchingQueue addStitchingObserver:observer];

            [stitchingQueue enqueueStitcherForPresentation:presentation1];
        });

        it(@"should periodically notify the observer of the progress of running stitchers", ^{
            with_timeout(3.0f, ^{
                in_time(observer) should have_received(@selector(stitchingQueue:didUpdateProgress:forPresentationUUID:)).with(stitchingQueue, stitchingProgress, presentation1.UUID);
            });
        });

        describe(@"when a stitcher completes stitching", ^{
            beforeEach(^{
                [deferred resolveWithValue:outputURL];
            });

            itShouldBehaveLike(@"when stitching completes");

            it(@"should notify the queue observer", ^{
                observer should have_received(@selector(stitchingQueue:didCompleteStitchingForPresentationUUID:)).with(stitchingQueue, presentation1.UUID);
            });
        });

        describe(@"when a stitcher cancels stitching", ^{
            beforeEach(^{
                [deferred rejectWithError:[NSError errorWithDomain:@"" code:0 userInfo:nil]];
            });

            itShouldBehaveLike(@"when stitching cancels");

            it(@"should notify the queue observer", ^{
                observer should have_received(@selector(stitchingQueue:didCancelStitchingForPresentationUUID:)).with(stitchingQueue, presentation1.UUID);
            });
        });

        describe(@"when observation stops", ^{
            describe(@"when a stitcher completes stitching", ^{
                beforeEach(^{
                    [stitchingQueue removeStitchingObserver:observer];
                    [deferred resolveWithValue:outputURL];
                });

                it(@"should not notify the queue observer", ^{
                    observer should_not have_received(@selector(stitchingQueue:didCompleteStitchingForPresentationUUID:));
                });
            });
        });
    });
});

SPEC_END
