#import "QualifyIdentificationViewController.h"
#import "AudioPlayerService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(QualifyIdentificationViewControllerSpec)

describe(@"QualifyIdentificationViewController", ^{
    __block QualifyIdentificationViewController *controller;
    __block id<WitnessResponseViewControllerDelegate> delegate;
    __block AudioPlayerService *audioPlayerService;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"QualifyIdentificationViewController"];
        delegate = nice_fake_for(@protocol(WitnessResponseViewControllerDelegate));

        audioPlayerService = nice_fake_for([AudioPlayerService class]);
        [controller configureWithDelegate:delegate audioLevelMeter:nil audioPlayerService:audioPlayerService];
        controller.view should_not be_nil;

        [SpecHelper.specHelper.sharedExampleContext addEntriesFromDictionary:@{ @"controller": controller,
                                                                                @"audioPlayerService": audioPlayerService,
                                                                                @"expectedSoundName": @"identification_qualification",
                                                                                @"englishText": @"Please state where you recognize this person from.",
                                                                                @"spanishText": @"Sírvase indicar, en sus propias palabras, en las que reconoce a esta persona de." }];
    });

    itShouldBehaveLike(@"speaking a prompt when the view appears before enabling the continue button");

    itShouldBehaveLike(@"localizing witness prompt and 'speak now' strings");

    describe(@"when the Continue button is tapped", ^{
        beforeEach(^{
            controller.continueButton.enabled = YES;
            [controller.continueButton tap];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(qualifyIdentificationViewControllerDidContinue:)).with(controller);
        });

        it(@"should disable the continue button", ^{
            controller.continueButton.enabled should be_falsy;
        });
    });
});

SPEC_END
