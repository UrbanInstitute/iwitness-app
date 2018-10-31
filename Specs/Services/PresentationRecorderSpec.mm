#import "PresentationRecorder.h"
#import "VideoRecorder.h"
#import "ScreenCaptureService.h"
#import "VideoStitcher.h"
#import "NSFileManager+CommonDirectories.h"
#import "Presentation.h"
#import "StitchingQueue.h"
#import "LineupReviewWriter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PresentationRecorderSpec)

describe(@"PresentationRecorder", ^{
    __block PresentationRecorder *recorder;
    __block KSDeferred *cameraDeferred;
    __block KSDeferred *screenCaptureDeferred;
    __block KSDeferred *stitchingDeferred;
    __block NSURL *cameraOutputURL;
    __block NSURL *screenCaptureOutputURL;
    __block VideoStitcher *videoStitcher;
    __block StitchingQueue *stitchingQueue;
    __block UIApplication *application;
    __block Presentation *presentation;
    __block LineupReviewWriter *lineupReviewWriter;
    UIBackgroundTaskIdentifier taskIdentifier = 42;

    beforeEach(^{
        application = fake_for([UIApplication class]);
        application stub_method(@selector(endBackgroundTask:));
        application stub_method(@selector(beginBackgroundTaskWithName:expirationHandler:)).and_return(taskIdentifier);

        cameraDeferred = [KSDeferred defer];
        VideoRecorder *videoRecorder = nice_fake_for([VideoRecorder class]);
        videoRecorder stub_method(@selector(stopRecording)).and_return(cameraDeferred.promise);

        screenCaptureDeferred = [KSDeferred defer];
        ScreenCaptureService *screenCaptureService = nice_fake_for([ScreenCaptureService class]);
        screenCaptureService stub_method(@selector(stopCapturing)).and_return(screenCaptureDeferred.promise);

        stitchingDeferred = [KSDeferred defer];
        videoStitcher = nice_fake_for([VideoStitcher class]);
        stitchingQueue = nice_fake_for([StitchingQueue class]);
        presentation = nice_fake_for([Presentation class]);

        lineupReviewWriter = fake_for([LineupReviewWriter class]);
        lineupReviewWriter stub_method(@selector(writeLineupReviewForPresentation:));

        recorder = [[PresentationRecorder alloc] initWithApplication:application
                                                        presentation:presentation
                                                       videoRecorder:videoRecorder
                                                screenCaptureService:screenCaptureService
                                                      stitchingQueue:stitchingQueue
                                                  lineupReviewWriter:lineupReviewWriter];

        NSURL *arbitraryBasePath= [[NSFileManager defaultManager] URLForDocumentDirectory];
        cameraOutputURL = [arbitraryBasePath URLByAppendingPathComponent:@"test_video.mov"];
        screenCaptureOutputURL = [arbitraryBasePath URLByAppendingPathComponent:@"test_screen_capture.mov"];

        presentation stub_method(@selector(temporaryCameraRecordingURL)).and_return(cameraOutputURL);
        presentation stub_method(@selector(temporaryScreenCaptureURL)).and_return(screenCaptureOutputURL);
    });

    describe(@"starting recording", ^{
        beforeEach(^{
            [recorder startRecordingWithStartTime:CACurrentMediaTime()];
        });

        it(@"should tell the video recorder to start recording to the temporary camera recording URL", ^{
            recorder.videoRecorder should have_received(@selector(startRecordingToOutputURL:)).with(cameraOutputURL);
        });

        it(@"should tell the screen capture service to start capturing to the temporary screen capture URL", ^{
            recorder.screenCaptureService should have_received(@selector(startCapturingScreenToURL:)).with(screenCaptureOutputURL);
        });

        it(@"should report that recording is in progress", ^{
            recorder.recording should be_truthy;
        });
    });

    describe(@"stopping recording", ^{
        __block KSPromise *stopRecordingPromise;

        beforeEach(^{
            [recorder startRecordingWithStartTime:CACurrentMediaTime()];
            stopRecordingPromise = [recorder stopRecording];
        });

        it(@"should stop the recording", ^{
            recorder.videoRecorder should have_received(@selector(stopRecording));
            recorder.screenCaptureService should have_received(@selector(stopCapturing));
        });

        it(@"should write the lineup review to the presentation's temporary lineup review URL", ^{
            lineupReviewWriter should have_received(@selector(writeLineupReviewForPresentation:)).with(presentation);
        });

        it(@"should begin a background task", ^{
            application should have_received(@selector(beginBackgroundTaskWithName:expirationHandler:)).with(@"PresentationPostProcessing", Arguments::anything);
        });

        describe(@"when the recorder and capture service are finished", ^{
            beforeEach(^{
                [@"VIDEO_DATA" writeToURL:cameraOutputURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
                recorder.videoRecorder stub_method(@selector(outputURL)).and_return(cameraOutputURL);

                [@"SCREEN_CAPTURE_DATA" writeToURL:screenCaptureOutputURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
                recorder.screenCaptureService stub_method(@selector(outputURL)).and_return(screenCaptureOutputURL);
            });

            describe(@"when the recorder and capture service complete successfully", ^{

                beforeEach(^{
                    [cameraDeferred resolveWithValue:cameraOutputURL];
                    [screenCaptureDeferred resolveWithValue:screenCaptureOutputURL];
                });

                it(@"should resolve the promise", ^{
                    stopRecordingPromise.fulfilled should be_truthy;
                });

                it(@"should kick off the video stitching on the presentation", ^{
                    presentation should have_received(@selector(finalizeWithStitchingQueue:videoPreviewTimeRange:)).with(stitchingQueue, Arguments::anything);
                });

                it(@"should finish the background task", ^{
                    application should have_received(@selector(endBackgroundTask:)).with(taskIdentifier);
                });

                it(@"should report that recording is not in progress", ^{
                    recorder.recording should be_falsy;
                });
            });

            describe(@"recording/capture failure", ^{
                NSError *videoRecorderError = [NSError errorWithDomain:kVideoRecorderErrorDomain
                                                                  code:0
                                                              userInfo:nil];
                NSError *screenCaptureServiceError = [NSError errorWithDomain:@""
                                                                         code:0
                                                                     userInfo:nil];

                describe(@"when the recorder and capture service both fail", ^{
                    beforeEach(^{
                        [cameraDeferred rejectWithError:videoRecorderError];
                        [screenCaptureDeferred rejectWithError:screenCaptureServiceError];
                    });

                    it(@"should reject the promise with an error", ^{
                        stopRecordingPromise.error.domain should equal(kPresentationRecorderErrorDomain);
                        stopRecordingPromise.error.code should equal(PresentationRecorderErrorRecordingFailed);
                    });

                    it(@"should return an error for the recording", ^{
                        stopRecordingPromise.rejected should be_truthy;
                        stopRecordingPromise.error.code should equal(PresentationRecorderErrorRecordingFailed);
                    });

                    it(@"should finish the background task", ^{
                        application should have_received(@selector(endBackgroundTask:)).with(taskIdentifier);
                    });

                    it(@"should report that recording is not in progress", ^{
                        recorder.recording should be_falsy;
                    });
                });

                describe(@"when the recorder fails and the capture service succeeds", ^{
                    beforeEach(^{
                        [cameraDeferred rejectWithError:videoRecorderError];
                        [screenCaptureDeferred resolveWithValue:screenCaptureOutputURL];
                    });

                    it(@"should resolve the promise", ^{
                        stopRecordingPromise.fulfilled should be_truthy;
                    });

                    it(@"should finalize the presentation without capture capture", ^{
                        presentation should have_received(@selector(finalizeWithoutCameraCapture));
                    });

                    it(@"should finish the background task", ^{
                        application should have_received(@selector(endBackgroundTask:)).with(taskIdentifier);
                    });

                    it(@"should report that recording is not in progress", ^{
                        recorder.recording should be_falsy;
                    });
                });

                describe(@"when the recorder succeeds and the capture service fails", ^{
                    beforeEach(^{
                        [cameraDeferred resolveWithValue:cameraOutputURL];
                        [screenCaptureDeferred rejectWithError:screenCaptureServiceError];
                    });

                    it(@"should resolve the promise", ^{
                        stopRecordingPromise.fulfilled should be_truthy;
                    });

                    it(@"should finalize the presentation without screen capture", ^{
                        presentation should have_received(@selector(finalizeWithoutScreenCapture));
                    });

                    it(@"should finish the background task", ^{
                        application should have_received(@selector(endBackgroundTask:)).with(taskIdentifier);
                    });

                    it(@"should report that recording is not in progress", ^{
                        recorder.recording should be_falsy;
                    });
                });
            });
        });
    });

    describe(@"recording video preview start and end times", ^{
        beforeEach(^{
            [recorder startRecordingWithStartTime:10];
            [recorder recordVideoPreviewEndTime:30];
            [recorder stopRecording];

            [cameraDeferred resolveWithValue:cameraOutputURL];
            [screenCaptureDeferred resolveWithValue:screenCaptureOutputURL];
        });

        it(@"should provide time ranges corresponding to the start/end times relative to the recording start time", ^{
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(20, 600));
            presentation should have_received(@selector(finalizeWithStitchingQueue:videoPreviewTimeRange:)).with(Arguments::anything, timeRange);
        });
    });

});

SPEC_END
