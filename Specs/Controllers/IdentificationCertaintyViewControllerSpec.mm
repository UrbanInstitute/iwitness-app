#import "IdentificationCertaintyViewController.h"
#import "AudioPlayerService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(IdentificationCertaintyViewControllerSpec)

describe(@"IdentificationCertaintyViewController", ^{
    __block IdentificationCertaintyViewController *controller;
    __block id<WitnessResponseViewControllerDelegate> delegate;
    __block AudioPlayerService *audioPlayerService;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"IdentificationCertaintyViewController"];
        delegate = nice_fake_for(@protocol(WitnessResponseViewControllerDelegate));

        audioPlayerService = nice_fake_for([AudioPlayerService class]);
        [controller configureWithDelegate:delegate audioLevelMeter:nil audioPlayerService:audioPlayerService];
        controller.view should_not be_nil;
        [SpecHelper.specHelper.sharedExampleContext addEntriesFromDictionary:@{ @"controller": controller,
                                                                                @"audioPlayerService": audioPlayerService,
                                                                                @"expectedSoundName": @"identification_certainty",
                                                                                @"englishText": @"Please state how certain you are of this identification.",
                                                                                @"spanishText": @"Sírvase indicar, en sus propias palabras, cómo ciertos eres de esta identificación." }];
    });

    itShouldBehaveLike(@"speaking a prompt when the view appears before enabling the continue button");

    itShouldBehaveLike(@"localizing witness prompt and 'speak now' strings");

    describe(@"when the Continue button is tapped", ^{
        beforeEach(^{
            controller.continueButton.enabled = YES;
            [controller.continueButton tap];
        });

        it(@"should inform the delegate that the controller has continued", ^{
            delegate should have_received(@selector(identificationCertaintyViewControllerDidContinue:)).with(controller);
        });

        it(@"should disable the continue button", ^{
            controller.continueButton.enabled should be_falsy;
        });
    });
});

SPEC_END
