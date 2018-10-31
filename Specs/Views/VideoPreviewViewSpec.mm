#import "VideoPreviewView.h"
#import "CaptureSessionProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(VideoPreviewViewSpec)

describe(@"VideoPreviewView", ^{
    __block VideoPreviewView *view;
    __block AVCaptureSession *captureSession;
    __block AVCaptureVideoPreviewLayer *layer;
    __block CMFormatDescriptionRef formatDescription;
    CMVideoDimensions cameraDimensions = {1280, 720};

    beforeEach(^{
        captureSession = nice_fake_for([AVCaptureSession class]);
        view = [[VideoPreviewView alloc] initWithCaptureSession:captureSession];
        layer = (AVCaptureVideoPreviewLayer *)view.layer;

        CMVideoFormatDescriptionCreate(NULL, kCMVideoCodecType_422YpCbCr8, cameraDimensions.width, cameraDimensions.height, NULL, &formatDescription);

        AVCaptureInputPort *inputPort = nice_fake_for([AVCaptureInputPort class]);
        inputPort stub_method(@selector(formatDescription)).and_do_block(^CMFormatDescriptionRef{
            return formatDescription;
        });

        AVCaptureConnection *connection = nice_fake_for([AVCaptureConnection class]);
        connection stub_method(@selector(inputPorts)).and_return(@[inputPort]);

        spy_on(layer);
        layer stub_method(@selector(connection)).and_return(connection);
    });

    afterEach(^{
        CFRelease(formatDescription);
    });

    it(@"should display the front camera's video preview", ^{
        view.layer should be_instance_of([AVCaptureVideoPreviewLayer class]);
    });

    it(@"should have an AVCaptureSession", ^{
        [layer session] should be_same_instance_as(captureSession);
    });

    it(@"should have the same layer before and after being given a capture session", ^{
        view.layer should be_same_instance_as(layer);
    });

    it(@"should start the video stream when attached to a window", ^{
        UIWindow *window = [[UIWindow alloc] init];
        [window addSubview:view];
        captureSession should have_received(@selector(startRunning));
    });
});

SPEC_END
