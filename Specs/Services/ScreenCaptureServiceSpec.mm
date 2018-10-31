#import "ScreenCaptureService.h"
#import "CedarAsync.h"
#import "NSFileManager+CommonDirectories.h"
#import "ObserveTouchesGestureRecognizer.h"
#import "AnalyticsTracker.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface ScreenCaptureService (SpecPrivate)
@property (strong, readonly) AVAssetWriter *assetWriter;
@property (strong, nonatomic) ObserveTouchesGestureRecognizer *observeTouchesGestureRecognizer;
@end

SPEC_BEGIN(ScreenCaptureServiceSpec)

describe(@"ScreenCaptureService", ^{
    __block ScreenCaptureService *service;
    __block NSURL *outputURL;
    __block KSPromise *promise;

    beforeEach(^{
        spy_on([AnalyticsTracker sharedInstance]);

        service = [[ScreenCaptureService alloc] init];
        service.observeTouchesGestureRecognizer = nice_fake_for([ObserveTouchesGestureRecognizer class]);

        outputURL = [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"myCapture.mov"];
        [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    });

    describe(@"when recording successfully", ^{
        beforeEach(^{
            [service startCapturingScreenToURL:outputURL];
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2f]];
            promise = [service stopCapturing];
        });

        it(@"should record the screen and store the video in the outputURL", ^{
            [[NSFileManager defaultManager] fileExistsAtPath:[outputURL path]] should be_truthy;
        });

        it(@"should notify the touch gesture recognizer to stop observing touches", ^{
            service.observeTouchesGestureRecognizer should have_received(@selector(stopObservingTouches));
        });

        it(@"should query its gesture recognizer for active touches to composite into the recording", ^{
            service.observeTouchesGestureRecognizer should have_received(@selector(activeTouches));
        });

        describe(@"when it has finished writing", ^{
            beforeEach(^{
                with_timeout(10, ^{
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
        });
    });

    describe(@"when a file already exists at the outputURL", ^{
        NSString *someString = @"FOO";

        beforeEach(^{
            [someString writeToURL:outputURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
            [service startCapturingScreenToURL:outputURL];
            [service stopCapturing];
        });

        it(@"should overwrite it", ^{
            [NSData dataWithContentsOfURL:outputURL] should_not equal([someString dataUsingEncoding:NSUTF8StringEncoding]);
        });
    });

    describe(@"when the assetWriter fails before attempting to stop capturing", ^{
        NSError *someError = [NSError errorWithDomain:@"OutOfKittensError" code:1234 userInfo:@{}];

        beforeEach(^{
            [service startCapturingScreenToURL:outputURL];
            spy_on(service.assetWriter);
            service.assetWriter stub_method(@selector(error)).and_return(someError);
            promise = [service stopCapturing];
        });

        it(@"should attach the error to the promise", ^{
            promise.error should equal(someError);
        });

        it(@"should track the failure", ^{
            [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationScreenCaptureFailureWithError:)).with(someError);
        });
    });

    describe(@"when the assetWriter fails while finishing writing", ^{
        NSError *someError = [NSError errorWithDomain:@"PuppyOverflow" code:1234 userInfo:@{}];

        beforeEach(^{
            [service startCapturingScreenToURL:outputURL];
            spy_on(service.assetWriter);
            service.assetWriter stub_method(@selector(finishWritingWithCompletionHandler:)).and_do_block(^(void(^completionBlock)()){
                service.assetWriter stub_method(@selector(error)).and_return(someError);
                completionBlock();
            });

            promise = [service stopCapturing];

            with_timeout(0.1f, ^{
                in_time(promise.rejected) should be_truthy;
            });
        });

        it(@"should reject the promise with the error", ^{
            promise.error should be_same_instance_as(someError);
        });

        it(@"should track the failure", ^{
            [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationScreenCaptureFailureWithError:)).with(someError);
        });
    });
});

SPEC_END
