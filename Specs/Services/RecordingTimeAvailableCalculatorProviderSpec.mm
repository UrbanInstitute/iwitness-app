#import "RecordingTimeAvailableCalculatorProvider.h"
#import "ScreenCaptureService.h"
#import "RecordingTimeAvailableCalculator.h"
#import "RecordingSpaceRequirements.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RecordingTimeAvailableCalculatorProviderSpec)

describe(@"RecordingTimeAvailableCalculatorProvider", ^{
    __block RecordingTimeAvailableCalculatorProvider *provider;
    __block ScreenCaptureService *screenCaptureService;

    beforeEach(^{
        screenCaptureService = fake_for([ScreenCaptureService class]);
        provider = [[RecordingTimeAvailableCalculatorProvider alloc] initWithScreenCaptureService:screenCaptureService];
    });

    describe(@"providing a recording time available calculator", ^{
        __block RecordingTimeAvailableCalculator *calculator;

        subjectAction(^{
            calculator = [provider recordingTimeAvailableCalculator];
        });

        context(@"screen-capture at 1x", ^{
            beforeEach(^{
                screenCaptureService stub_method(@selector(frameScale)).and_return(1.0f);
            });

            it(@"should make a calculator that uses standard-res space requirements", ^{
                calculator.recordingSpaceRequirements should equal([RecordingSpaceRequirements requirementsForStandardScreenCapture]);
            });
        });

        context(@"screen-capture at 2x", ^{
            beforeEach(^{
                screenCaptureService stub_method(@selector(frameScale)).and_return(2.0f);
            });

            it(@"should make a calculator that uses standard-res space requirements", ^{
                calculator.recordingSpaceRequirements should equal([RecordingSpaceRequirements requirementsForRetinaScreenCapture]);
            });
        });
    });
});

SPEC_END
