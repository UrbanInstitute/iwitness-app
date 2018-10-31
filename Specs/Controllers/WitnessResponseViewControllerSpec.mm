#import "WitnessResponseViewController.h"
#import "AudioLevelMeter.h"
#import "AudioPlayerService.h"
#import "PromptToSpeakViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(WitnessResponseViewControllerSpec)

describe(@"WitnessResponseViewController", ^{
    __block WitnessResponseViewController *controller;
    __block id delegate;
    __block AudioLevelMeter *audioLevelMeter;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"QualifyUncertaintyViewController"];
        delegate = nice_fake_for(@protocol(WitnessResponseViewControllerDelegate));
        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);
        [controller configureWithDelegate:delegate audioLevelMeter:audioLevelMeter audioPlayerService:nil];
        controller.view should_not be_nil;

        NSMutableDictionary *context = [SpecHelper specHelper].sharedExampleContext;
        context[@"controller"] = controller;
        context[@"audioLevelMeter"] = audioLevelMeter;
        context[@"audioLevelIndicatorView"] = controller.audioLevelIndicatorViewEnabled;
    });

    itShouldBehaveLike(@"audio level metering");
});

SPEC_END

SHARED_EXAMPLE_GROUPS_BEGIN(WitnessResponseViewControllerSharedExamples)

sharedExamplesFor(@"speaking a prompt when the view appears before enabling the continue button", ^(NSDictionary *sharedContext) {
    __block WitnessResponseViewController *witnessResponseViewController;
    __block AudioPlayerService *audioPlayerService;

    beforeEach(^{
        witnessResponseViewController = sharedContext[@"controller"];
        audioPlayerService = sharedContext[@"audioPlayerService"];
    });

    context(@"when the view first appears", ^{
        __block KSDeferred *soundPlaybackDeferred;

        beforeEach(^{
            soundPlaybackDeferred = [KSDeferred defer];
            audioPlayerService stub_method(@selector(playSoundNamed:)).with(sharedContext[@"expectedSoundName"]).and_return(soundPlaybackDeferred.promise);
            [witnessResponseViewController viewWillAppear:NO];
            [witnessResponseViewController viewDidAppear:NO];
        });

        it(@"should disable the continue button", ^{
            witnessResponseViewController.continueButton.enabled should_not be_truthy;
        });

        it(@"should start playing the appropriate audio prompt", ^{
            audioPlayerService should have_received(@selector(playSoundNamed:)).with(sharedContext[@"expectedSoundName"]);
        });

        context(@"when sound playback completes", ^{
            beforeEach(^{
                [soundPlaybackDeferred resolveWithValue:nil];
            });

            it(@"should enable the continue button", ^{
                witnessResponseViewController.continueButton.enabled should be_truthy;
            });
        });
    });

    context(@"when the view disappears", ^{
        beforeEach(^{
            [witnessResponseViewController viewWillDisappear:NO];
        });

        it(@"should stop playing the audio prompt", ^{
            audioPlayerService should have_received(@selector(stopPlaying));
        });
    });
});

sharedExamplesFor(@"localizing witness prompt and 'speak now' strings", ^(NSDictionary *sharedContext) {
    __block WitnessResponseViewController *witnessResponseViewController;

    beforeEach(^{
        witnessResponseViewController = sharedContext[@"controller"];
    });

    itShouldBehaveLike(@"localizing 'speak now' prompt strings");

    describe(@"string localization", ^{
        context(@"English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                [witnessResponseViewController viewWillAppear:NO];
            });

            it(@"should localize the strings for English", ^{
                witnessResponseViewController.witnessPromptLabel.text should equal(sharedContext[@"englishText"]);
                witnessResponseViewController.continueButton.titleLabel.text should equal(@"CONTINUE →");
            });
        });

        context(@"Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                [witnessResponseViewController viewWillAppear:NO];
            });

            it(@"should localize the strings for Spanish", ^{
                witnessResponseViewController.witnessPromptLabel.text should equal(sharedContext[@"spanishText"]);
                witnessResponseViewController.continueButton.titleLabel.text should equal(@"SIGUIENTE →");
            });
        });
    });
});

SHARED_EXAMPLE_GROUPS_END
