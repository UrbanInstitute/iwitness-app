#import "WitnessIdentificationViewController.h"
#import "WitnessIdentificationViewControllerDelegate.h"
#import "AudioLevelMeter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(WitnessIdentificationViewControllerSpec)

describe(@"WitnessIdentificationViewController", ^{
    __block WitnessIdentificationViewController *controller;
    __block id<WitnessIdentificationViewControllerDelegate> delegate;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"WitnessIdentificationViewController"];
        delegate = nice_fake_for(@protocol(WitnessIdentificationViewControllerDelegate));
        [controller configureWithAudioLevelMeter:nil delegate:delegate];
        controller.view should_not be_nil;
    });

    describe(@"when the continue button is tapped", ^{
        beforeEach(^{
            [controller.continueButton tap];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(witnessIdentificationViewControllerDidContinue:)).with(controller);
        });
    });

    describe(@"string localization", ^{
        context(@"English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for English", ^{
                controller.speakNowLabel.text should equal(@"SPEAK NOW");
                controller.directionsPromptLabel.text should equal(@"Please state your name for the record and then press the “Continue →” button below.");
                controller.continueButton.titleLabel.text should equal(@"CONTINUE →");
            });
        });

        context(@"Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for Spanish", ^{
                controller.speakNowLabel.text should equal(@"HABLE AHORA");
                controller.directionsPromptLabel.text should equal(@"Por favor diga su nombre para el registro y luego pulse el botón “Siguiente →” abajo.");
                controller.continueButton.titleLabel.text should equal(@"SIGUIENTE →");
            });
        });
    });
});

SPEC_END
