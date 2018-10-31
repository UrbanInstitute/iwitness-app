#import "CaptureSessionProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CaptureSessionProviderSpec)

#if !TARGET_IPHONE_SIMULATOR
describe(@"CaptureSessionProvider", ^{
    __block CaptureSessionProvider *provider;
    __block AVCaptureSession *captureSession;

    beforeEach(^{
        provider = [[CaptureSessionProvider alloc] init];
        captureSession = provider.captureSession;
    });

    describe(@"the captureSession's video input", ^{
        __block AVCaptureDeviceInput *videoInput;

        beforeEach(^{
            NSInteger videoIndex = [captureSession.inputs indexOfObjectPassingTest:^BOOL(AVCaptureDeviceInput *input, NSUInteger idx, BOOL *stop) {
                AVCaptureDevice *device = input.device;
                return [device hasMediaType:AVMediaTypeVideo];
            }];
            videoInput = captureSession.inputs[videoIndex];
        });

        it(@"should have an input with a video device", ^{
            videoInput should_not be_nil;
        });

        it(@"should set video input to the front camera", ^{
            videoInput.device.position should equal(AVCaptureDevicePositionFront);
        });
    });

    describe(@"the captureSession's audio input", ^{
        __block AVCaptureDeviceInput *audioInput;

        beforeEach(^{
            NSInteger audioIndex = [captureSession.inputs indexOfObjectPassingTest:^BOOL(AVCaptureDeviceInput *input, NSUInteger idx, BOOL *stop) {
                AVCaptureDevice *device = input.device;
                return [device hasMediaType:AVMediaTypeAudio];
            }];
            audioInput = captureSession.inputs[audioIndex];
        });

        it(@"should have an input with an audio device", ^{
            audioInput should_not be_nil;
        });
    });
});
#endif

SPEC_END
