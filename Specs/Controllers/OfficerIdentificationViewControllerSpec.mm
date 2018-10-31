#import "OfficerIdentificationViewController.h"
#import "OfficerIdentificationViewControllerDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OfficerIdentificationViewControllerSpec)

describe(@"OfficerIdentificationViewController", ^{
    __block OfficerIdentificationViewController *controller;
    __block id<OfficerIdentificationViewControllerDelegate> delegate;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"OfficerIdentificationViewController"];
        delegate = nice_fake_for(@protocol(OfficerIdentificationViewControllerDelegate));

        [controller configureWithAudioLevelMeter:nil delegate:delegate];
        controller.view should_not be_nil;
    });

    describe(@"when the continue button is tapped", ^{
        beforeEach(^{
            [controller.continueButton tap];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(officerIdentificationViewControllerDidContinue:)).with(controller);
        });
    });

    describe(@"when the view appears", ^{
        beforeEach(^{
            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(officerIdentificationViewControllerDidAppear:)).with(controller);
        });
    });
});

SPEC_END
