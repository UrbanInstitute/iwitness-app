#import "QualifyUncertaintyViewController.h"
#import "AudioPlayerService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(QualifyUncertaintyViewControllerSpec)

describe(@"QualifyUncertaintyViewController", ^{
    __block QualifyUncertaintyViewController *controller;
    __block id<WitnessResponseViewControllerDelegate> delegate;
    __block AudioPlayerService *audioPlayerService;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"QualifyUncertaintyViewController"];
        delegate = nice_fake_for(@protocol(WitnessResponseViewControllerDelegate));
        audioPlayerService = nice_fake_for([AudioPlayerService class]);
        [controller configureWithDelegate:delegate audioLevelMeter:nil audioPlayerService:audioPlayerService];
        controller.view should_not be_nil;
        [SpecHelper.specHelper.sharedExampleContext addEntriesFromDictionary:@{ @"controller": controller,
                                                                                @"audioPlayerService": audioPlayerService,
                                                                                @"expectedSoundName": @"uncertainty_qualification",
                                                                                @"englishText": @"Please explain.",
                                                                                @"spanishText": @"En sus propias palabras, explique." }];
    });

    itShouldBehaveLike(@"speaking a prompt when the view appears before enabling the continue button");

    itShouldBehaveLike(@"localizing witness prompt and 'speak now' strings");

    describe(@"when the Continue button is tapped", ^{
        beforeEach(^{
            controller.continueButton.enabled = YES;
            [controller.continueButton tap];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(qualifyUncertaintyViewControllerDidContinue:)).with(controller);
        });

        it(@"should disable the continue button", ^{
            controller.continueButton.enabled should be_falsy;
        });
    });
});

SPEC_END
