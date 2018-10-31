#import "PresentationRecorderProvider.h"
#import "PresentationRecorder.h"
#import "Presentation.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PresentationRecorderProviderSpec)

describe(@"PresentationRecorderProvider", ^{
    __block PresentationRecorderProvider *provider;

    beforeEach(^{
        provider = [[PresentationRecorderProvider alloc] init];
    });

    describe(@"providing a presentation recorder", ^{
        __block PresentationRecorder *recorder;
        __block Presentation *presentation;

        beforeEach(^{
            presentation = nice_fake_for([Presentation class]);
            presentation stub_method(@selector(date)).and_return([NSDate dateWithTimeIntervalSinceNow:-1000]);

            AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
            recorder = [provider presentationRecorderForPresentation:presentation captureSession:captureSession];
        });

        it(@"should return a configured presentation recorder", ^{
            recorder should be_instance_of([PresentationRecorder class]);
            recorder.presentation should_not be_nil;
            recorder.videoRecorder should_not be_nil;
            recorder.screenCaptureService should_not be_nil;
        });
    });
});

SPEC_END
