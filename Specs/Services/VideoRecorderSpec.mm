#import "VideoRecorder.h"
#import "NSFileManager+CommonDirectories.h"
#import "AnalyticsTracker.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface VideoRecorder (Specs) <AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@end

SPEC_BEGIN(VideoRecorderSpec)

describe(@"VideoRecorder", ^{
    __block VideoRecorder *recorder;
    __block AVCaptureSession *captureSession;
    __block NSURL *outputFileURL;

    beforeEach(^{
        captureSession = nice_fake_for([AVCaptureSession class]);
        spy_on([AnalyticsTracker sharedInstance]);
        outputFileURL = [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"my_movie.mov"];

        recorder = [[VideoRecorder alloc] initWithCaptureSession:captureSession];
        recorder.movieFileOutput = nice_fake_for([AVCaptureMovieFileOutput class]);
        recorder.movieFileOutput stub_method(@selector(connections)).and_return(@[@"a connection"]);

        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:NULL];
        [[@"File contents" dataUsingEncoding:NSASCIIStringEncoding] writeToURL:outputFileURL atomically:NO];

        [recorder startRecordingToOutputURL:outputFileURL];
    });

    it(@"should require a file URL", ^{
        ^{
            NSURL *invalidFileURL = [NSURL URLWithString:@"http://google.com"];
            [[[VideoRecorder alloc] initWithCaptureSession:captureSession] startRecordingToOutputURL:invalidFileURL];
        } should raise_exception;
    });

    describe(@"starting recording", ^{
        it(@"should add a movie file output to the capture session", ^{
            captureSession should have_received(@selector(addOutput:)).with(recorder.movieFileOutput);
        });

        it(@"should remove any file already existing at the output file URL", ^{
            [[NSFileManager defaultManager] fileExistsAtPath:[outputFileURL path]] should_not be_truthy;
        });

        it(@"should start recording to the file specified by the file url", ^{
            recorder.movieFileOutput should have_received(@selector(startRecordingToOutputFileURL:recordingDelegate:)).with(outputFileURL, recorder);
        });

        it(@"should report recording as having started", ^{
            recorder.recording should be_truthy;
        });
    });

    describe(@"stopping recording", ^{
        __block KSPromise *promise;
        __block NSError *error;

        context(@"success", ^{
            beforeEach(^{
                recorder.movieFileOutput stub_method(@selector(isRecording)).and_return(YES);
                promise = [recorder stopRecording];
                [recorder captureOutput:recorder.movieFileOutput didFinishRecordingToOutputFileAtURL:outputFileURL fromConnections:nil error:nil];
            });

            it(@"should stop recording video", ^{
                recorder.movieFileOutput should have_received(@selector(stopRecording));
            });

            it(@"should attach the video url to the promise", ^{
                promise.value should equal(outputFileURL);
            });

            it(@"should release the camera", ^{
                recorder.captureSession should be_nil;
            });
        });

        context(@"failure while stopping recording", ^{
            beforeEach(^{
                recorder.movieFileOutput stub_method(@selector(isRecording)).and_return(YES);
                promise = [recorder stopRecording];

                error = [NSError errorWithDomain:AVFoundationErrorDomain code:9999 userInfo:nil];
                [recorder captureOutput:recorder.movieFileOutput didFinishRecordingToOutputFileAtURL:outputFileURL fromConnections:nil error:error];
            });

            it(@"should stop recording video", ^{
                recorder.movieFileOutput should have_received(@selector(stopRecording));
            });

            it(@"should reject the promise with an error", ^{
                promise.error should equal(error);
            });

            it(@"should release the camera", ^{
                recorder.captureSession should be_nil;
            });

            it(@"should track the failure", ^{
                [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationVideoRecorderFailureWithError:)).with(error);
            });
        });

        context(@"failure before stopping recording", ^{
            beforeEach(^{
                recorder.movieFileOutput stub_method(@selector(isRecording)).and_return(NO);

                error = [NSError errorWithDomain:AVFoundationErrorDomain code:9999 userInfo:nil];
                [recorder captureOutput:recorder.movieFileOutput didFinishRecordingToOutputFileAtURL:outputFileURL fromConnections:nil error:error];

                promise = [recorder stopRecording];
            });

            it(@"should reject the promise with an error", ^{
                promise.error should equal(error);
            });

            it(@"should track the failure", ^{
                [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationVideoRecorderFailureWithError:)).with(error);
            });
        });
    });
});

SPEC_END
