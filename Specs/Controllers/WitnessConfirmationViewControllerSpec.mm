#import "WitnessConfirmationViewController.h"
#import "AudioLevelMeter.h"
#import "AudioPlayerService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(WitnessConfirmationViewControllerSpec)

describe(@"WitnessConfirmationViewController", ^{
    __block WitnessConfirmationViewController *controller;
    __block id<WitnessConfirmationViewControllerDelegate> delegate;
    __block AudioLevelMeter *audioLevelMeter;
    __block AudioPlayerService *audioPlayerService;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"WitnessConfirmationViewController"];

        delegate = nice_fake_for(@protocol(WitnessConfirmationViewControllerDelegate));
        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);
        audioPlayerService = nice_fake_for([AudioPlayerService class]);
    });

    describe(@"audio metering", ^{
        beforeEach(^{
            [controller configureForCertaintyWithDelegate:delegate audioLevelMeter:audioLevelMeter audioPlayerService:audioPlayerService];
            controller.view should_not be_nil;

            NSMutableDictionary *context = [SpecHelper specHelper].sharedExampleContext;
            context[@"controller"] = controller;
            context[@"audioLevelMeter"] = audioLevelMeter;
            context[@"audioLevelIndicatorView"] = controller.audioLevelIndicatorView;
        });

        itShouldBehaveLike(@"audio level metering");
    });

    describe(@"string localization", ^{
        beforeEach(^{
            [controller configureForCertaintyWithDelegate:delegate audioLevelMeter:audioLevelMeter audioPlayerService:audioPlayerService];
            controller.view should_not be_nil;
        });

        context(@"English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for English", ^{
                controller.denialConfirmationLabel.text should equal(@"You stated you do not recognize this person; tap “Continue →” to move to the next photo.");
                controller.uncertaintyConfirmationLabel.text should equal(@"You stated you are not sure if you recognize this person; tap “Continue →” to move to the next photo.");
                controller.certaintyConfirmationLabel.text should equal(@"The presentation will continue until you have reviewed all photos.");
                controller.speakNowLabel.text should equal(@"RECORDING");
                controller.continueButton.titleLabel.text should equal(@"CONTINUE →");
            });
        });

        context(@"Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for Spanish", ^{
                controller.denialConfirmationLabel.text should equal(@"Usted ha declarado que no reconoce a esta persona; pulse “Siguiente →” para pasar a la siguiente foto.");
                controller.uncertaintyConfirmationLabel.text should equal(@"Usted dijo que no está seguro si usted reconoce a esta persona; pulse “Siguiente →” para pasar a la siguiente foto.");
                controller.certaintyConfirmationLabel.text should equal(@"La presentación continuará hasta que haya revisado todas las fotos.");
                controller.speakNowLabel.text should equal(@"GRABACIÓN");
                controller.continueButton.titleLabel.text should equal(@"SIGUIENTE →");
            });
        });
    });

    context(@"when not configured", ^{
        it(@"should blow up when the view loads", ^{
            ^{ [controller view]; } should raise_exception;
        });
    });

    sharedExamplesFor(@"notifying the delegate when continue is tapped", ^(NSDictionary *sharedContext) {
        describe(@"when the continue button is tapped", ^{
            beforeEach(^{
                controller.continueButton.enabled = YES;
                [controller.continueButton tap];
            });

            it(@"should notify its delegate that the continue button is tapped", ^{
                delegate should have_received(@selector(witnessConfirmationViewControllerDidContinue:)).with(controller);
            });

            it(@"should disable the continue button", ^{
                controller.continueButton.enabled should be_falsy;
            });
        });
    });

    sharedExamplesFor(@"playing an audio sample without disabling the continue button", ^(NSDictionary *sharedContext) {
        context(@"when the view first appears", ^{
            __block KSDeferred *soundPlaybackDeferred;

            beforeEach(^{
                soundPlaybackDeferred = [KSDeferred defer];
                audioPlayerService stub_method(@selector(playSoundNamed:)).with(sharedContext[@"expectedSoundName"]).and_return(soundPlaybackDeferred.promise);
                [controller viewWillAppear:NO];
                [controller viewDidAppear:NO];
            });

            it(@"should enable the continue button", ^{
                controller.continueButton.enabled should be_truthy;
            });

            it(@"should start playing the appropriate sound", ^{
                audioPlayerService should have_received(@selector(playSoundNamed:)).with(sharedContext[@"expectedSoundName"]);
            });

            context(@"when the view disappears", ^{
                beforeEach(^{
                    [controller viewWillDisappear:NO];
                });

                it(@"should stop playing an audio sample", ^{
                    audioPlayerService should have_received(@selector(stopPlaying));
                });
            });
        });
    });


    sharedExamplesFor(@"playing an audio sample and then enabling the continue button", ^(NSDictionary *sharedContext) {
        context(@"when the view first appears", ^{
            __block KSDeferred *soundPlaybackDeferred;

            beforeEach(^{
                soundPlaybackDeferred = [KSDeferred defer];
                audioPlayerService stub_method(@selector(playSoundNamed:)).with(sharedContext[@"expectedSoundName"]).and_return(soundPlaybackDeferred.promise);
                [controller viewWillAppear:NO];
                [controller viewDidAppear:NO];
            });

            it(@"should disable the continue button", ^{
                controller.continueButton.enabled should_not be_truthy;
            });

            it(@"should start playing the appropriate sound", ^{
                audioPlayerService should have_received(@selector(playSoundNamed:)).with(sharedContext[@"expectedSoundName"]);
            });

            context(@"when sound playback completes", ^{
                beforeEach(^{
                    [soundPlaybackDeferred resolveWithValue:nil];
                });

                it(@"should enable the continue button", ^{
                    controller.continueButton.enabled should be_truthy;
                });
            });

            context(@"when the view disappears", ^{
                beforeEach(^{
                    [controller viewWillDisappear:NO];
                });

                it(@"should stop playing an audio sample", ^{
                    audioPlayerService should have_received(@selector(stopPlaying));
                });
            });
        });
    });

    context(@"when configured for denial confirmation", ^{
        beforeEach(^{
            [controller configureForDenialWithDelegate:delegate audioLevelMeter:nil audioPlayerService:audioPlayerService];
            [SpecHelper specHelper].sharedExampleContext[@"expectedSoundName"] = @"denial_continue";
            controller.view should_not be_nil;
        });

        it(@"should hide all labels except the denial confirmation label", ^{
            controller.denialConfirmationLabel.hidden should be_falsy;
            controller.certaintyConfirmationLabel.hidden should be_truthy;
            controller.uncertaintyConfirmationLabel.hidden should be_truthy;
        });

        itShouldBehaveLike(@"playing an audio sample without disabling the continue button");

        itShouldBehaveLike(@"notifying the delegate when continue is tapped");
    });

    context(@"when configured for uncertainty confirmation", ^{
        beforeEach(^{
            [controller configureForUncertaintyWithDelegate:delegate audioLevelMeter:nil audioPlayerService:audioPlayerService];
            [SpecHelper specHelper].sharedExampleContext[@"expectedSoundName"] = @"uncertainty_continue";
            controller.view should_not be_nil;
        });

        it(@"should hide all labels except the uncertainty confirmation label", ^{
            controller.denialConfirmationLabel.hidden should be_truthy;
            controller.certaintyConfirmationLabel.hidden should be_truthy;
            controller.uncertaintyConfirmationLabel.hidden should be_falsy;
        });

        itShouldBehaveLike(@"playing an audio sample and then enabling the continue button");

        itShouldBehaveLike(@"notifying the delegate when continue is tapped");
    });

    context(@"when configured for identification confirmation", ^{
        beforeEach(^{
            [controller configureForCertaintyWithDelegate:delegate audioLevelMeter:nil audioPlayerService:audioPlayerService];
            [SpecHelper specHelper].sharedExampleContext[@"expectedSoundName"] = @"identification_continue";
            controller.view should_not be_nil;
        });

        it(@"should hide all labels except the uncertainty confirmation label", ^{
            controller.denialConfirmationLabel.hidden should be_truthy;
            controller.certaintyConfirmationLabel.hidden should be_falsy;
            controller.uncertaintyConfirmationLabel.hidden should be_truthy;
        });

        itShouldBehaveLike(@"playing an audio sample and then enabling the continue button");

        itShouldBehaveLike(@"notifying the delegate when continue is tapped");
    });
});

SPEC_END
