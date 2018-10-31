#import "FaceDetector.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface FaceDetector (Spec) <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureConnection *connection;
@end

SPEC_BEGIN(FaceDetectorSpec)

describe(@"FaceDetector", ^{
    __block FaceDetector *detector;

    beforeEach(^{
        AVCaptureSession *captureSession = nice_fake_for([AVCaptureSession class]);

        // Set up a chain of fake objects for the tests to use:
        //  AVCaptureMetadataOutput -> AVCaptureConnection
        captureSession stub_method(@selector(addOutput:)).and_do_block(^(AVCaptureOutput *metaDataOutput){
            spy_on(metaDataOutput);

            captureSession stub_method(@selector(outputs)).and_return(@[metaDataOutput]);

            AVCaptureConnection *connection = nice_fake_for([AVCaptureConnection class]);
            metaDataOutput stub_method(@selector(connections)).and_return(@[connection]);
        });

        detector = [[FaceDetector alloc] initWithCaptureSession:captureSession];
    });

    it(@"should indicate the number of faces found by the capture session metadata output", ^{
        AVMetadataFaceObject *faceObject = nice_fake_for([AVMetadataFaceObject class]);
        [detector captureOutput:nil didOutputMetadataObjects:@[faceObject] fromConnection:nil];
        detector.numberOfFacesDetected should equal(1);
    });

    describe(@"starting face detection", ^{
        beforeEach(^{
            [detector startDetecting];
        });

        it(@"should have an enabled connection", ^{
            detector.connection should have_received(@selector(setEnabled:)).with(YES);
        });
    });

    describe(@"stopping face detection", ^{
        beforeEach(^{
            [detector startDetecting];
            [detector stopDetecting];
        });

        it(@"should not have an enabled connection", ^{
            detector.connection should have_received(@selector(setEnabled:)).with(NO);
        });
    });
});

SPEC_END
