#import "VideoStitcher.h"
#import "CedarAsync.h"
#import "NSFileManager+CommonDirectories.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface VideoStitcher (Spec)
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@end

SPEC_BEGIN(VideoStitcherSpec)

describe(@"VideoStitcher", ^{
    __block VideoStitcher *stitcher;
    __block NSURL *outputURL;
    __block KSPromise *promise;
    __block UIApplication *application;
    __block void(^expirationHandler)();
    UIBackgroundTaskIdentifier taskIdentifier = 42;

    NSURL *cameraURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestCameraCapture360x480" withExtension:@"mov"];
    NSURL *screenURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestScreenCapture" withExtension:@"mov"];

    beforeEach(^{
        expirationHandler = nil;
        application = fake_for([UIApplication class]);
        application stub_method(@selector(endBackgroundTask:));
        application stub_method(@selector(beginBackgroundTaskWithExpirationHandler:)).and_do_block(^UIBackgroundTaskIdentifier(void(^expirationHandlerBlock)()) {
            expirationHandler = expirationHandlerBlock;
            return taskIdentifier;
        });

        stitcher = [VideoStitcher stitcherWithApplication:application];

        outputURL = [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"StitchedTest.mov"];
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:NULL];
    });

    sharedExamplesFor(@"stitching successfully", ^(NSDictionary *sharedContext) {
        it(@"should have started a background task", ^{
            application should have_received(@selector(beginBackgroundTaskWithExpirationHandler:));
        });

        describe(@"when the background task time expires", ^{
            beforeEach(^{
                in_time(stitcher.progress) should be_greater_than(0);
                expirationHandler();
            });

            it(@"should remove the unfinished output file", ^{
                [[NSFileManager defaultManager] fileExistsAtPath:[outputURL path]] should be_falsy;
            });

            it(@"should reject the promise indicating that stitching could not be completed", ^{
                promise.rejected should be_truthy;
            });
        });

        describe(@"when it has finished writing", ^{
            beforeEach(^{
                with_timeout(4.f, ^{
                    in_time(promise.fulfilled) should be_truthy;
                });
            });

            it(@"should have written a valid movie file", ^{
                AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:outputURL options:nil];
                CMTimeGetSeconds(movieAsset.duration) should be_greater_than(0);
            });

            it(@"should attach the output URL to the promise", ^{
                promise.value should equal(outputURL);
            });

            it(@"should end the background task", ^{
                application should have_received(@selector(endBackgroundTask:)).with(taskIdentifier);
            });
        });
    });

    describe(@"when given two valid videos to stitch", ^{
        beforeEach(^{
            promise = [stitcher stitchCameraCaptureAtURL:cameraURL withScreenCaptureAtURL:screenURL outputURL:outputURL videoPreviewTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.9, 30)) excludeCameraVideo:NO];
        });

        itShouldBehaveLike(@"stitching successfully");
    });

    describe(@"when a file already exists at the outputURL", ^{
        NSString *someString = @"BAR";

        beforeEach(^{
            [someString writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
            [stitcher stitchCameraCaptureAtURL:cameraURL withScreenCaptureAtURL:screenURL outputURL:outputURL videoPreviewTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.5, 30)) excludeCameraVideo:NO];
        });

        it(@"should overwrite it", ^{
            [NSData dataWithContentsOfURL:outputURL] should_not equal([someString dataUsingEncoding:NSUTF8StringEncoding]);
        });
    });

    sharedExamplesFor(@"one of the inputs is invalid", ^(NSDictionary *sharedContext) {
        it(@"should reject the promise with the error", ^{
            promise.rejected should be_truthy;
            promise.error should_not be_nil;
        });
    });

    describe(@"when the camera input is invalid", ^{
        NSURL *bogusInputURL = [NSURL fileURLWithPath:@"/../This/Is/Not/A/Movie/File"];

        beforeEach(^{
            promise = [stitcher stitchCameraCaptureAtURL:bogusInputURL withScreenCaptureAtURL:screenURL outputURL:outputURL videoPreviewTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.5, 30)) excludeCameraVideo:NO];
        });

        itShouldBehaveLike(@"one of the inputs is invalid");
    });

    describe(@"when the screen capture input is invalid", ^{
        NSURL *bogusInputURL = [NSURL fileURLWithPath:@"/../This/Is/Not/A/Movie/File"];

        beforeEach(^{
            promise = [stitcher stitchCameraCaptureAtURL:cameraURL withScreenCaptureAtURL:bogusInputURL outputURL:outputURL videoPreviewTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.5, 30)) excludeCameraVideo:NO];
        });

        itShouldBehaveLike(@"one of the inputs is invalid");
    });

    describe(@"when the export session fails", ^{
        NSURL *bogusOutputURL = [NSURL fileURLWithPath:@"/../../../FakeDirectory/DoesNotWork"];

        beforeEach(^{
            promise = [stitcher stitchCameraCaptureAtURL:cameraURL withScreenCaptureAtURL:screenURL outputURL:bogusOutputURL videoPreviewTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(0.5, 30)) excludeCameraVideo:NO];
            with_timeout(10.f, ^{
                in_time(promise.rejected) should be_truthy;
            });
        });

        it(@"should reject the promise with the error", ^{
            promise.rejected should be_truthy;
            promise.error should_not be_nil;
        });

        it(@"should end the background task", ^{
            application should have_received(@selector(endBackgroundTask:)).with(taskIdentifier);
        });
    });
});

SPEC_END
