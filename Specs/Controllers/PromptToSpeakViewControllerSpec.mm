#import "PromptToSpeakViewController.h"
#import "AudioLevelMeter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SHARED_EXAMPLE_GROUPS_BEGIN(PromptToSpeakViewControllerSharedExamples)

sharedExamplesFor(@"localizing 'speak now' prompt strings", ^(NSDictionary *sharedContext) {
    __block PromptToSpeakViewController *promptToSpeakViewController;

    beforeEach(^{
        promptToSpeakViewController = sharedContext[@"controller"];
    });

    describe(@"string localization", ^{
        context(@"English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                [promptToSpeakViewController viewWillAppear:NO];
            });

            it(@"should localize the strings for English", ^{
                promptToSpeakViewController.speakNowLabelEnabled.text should equal(@"SPEAK NOW");
                promptToSpeakViewController.speakNowLabelDisabled.text should equal(@"SPEAK NOW");
            });
        });

        context(@"Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                [promptToSpeakViewController viewWillAppear:NO];
            });

            it(@"should localize the strings for Spanish", ^{
                promptToSpeakViewController.speakNowLabelEnabled.text should equal(@"HABLE AHORA");
                promptToSpeakViewController.speakNowLabelDisabled.text should equal(@"HABLE AHORA");
            });
        });
    });
});

SHARED_EXAMPLE_GROUPS_END

SPEC_BEGIN(PromptToSpeakViewControllerSpec)

describe(@"PromptToSpeakViewController", ^{
    __block PromptToSpeakViewController *controller;
    __block AudioLevelMeter *audioLevelMeter;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"QualifyUncertaintyViewController"];
        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);
        [controller configureWithAudioLevelMeter:audioLevelMeter];
        controller.view should_not be_nil;

        NSMutableDictionary *context = [SpecHelper specHelper].sharedExampleContext;
        context[@"controller"] = controller;
        context[@"audioLevelMeter"] = audioLevelMeter;
        context[@"audioLevelIndicatorView"] = controller.audioLevelIndicatorViewEnabled;
    });

    itShouldBehaveLike(@"audio level metering");

    itShouldBehaveLike(@"localizing 'speak now' prompt strings");
});

SPEC_END

