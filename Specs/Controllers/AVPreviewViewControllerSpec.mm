#import "AVPreviewViewController.h"
#import "AudioLevelIndicatorView.h"
#import "CaptureSessionProvider.h"
#import "AudioLevelMeter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AVPreviewViewControllerSpec)

describe(@"AVPreviewViewController", ^{
    __block AVPreviewViewController *controller;
    __block AudioLevelMeter *audioLevelMeter;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"OfficerIdentificationViewController"];
        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);

        [controller configureWithAudioLevelMeter:audioLevelMeter];
        controller.view should_not be_nil;

        NSMutableDictionary *context = [SpecHelper specHelper].sharedExampleContext;
        context[@"controller"] = controller;
        context[@"audioLevelMeter"] = audioLevelMeter;
        context[@"audioLevelIndicatorView"] = controller.audioLevelIndicatorView;
    });

    itShouldBehaveLike(@"audio level metering");
});

SPEC_END
