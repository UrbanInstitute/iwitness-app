#import "WitnessCalibrationViewController.h"
#import "UIPopoverController+Spec.h"
#import "LanguagesViewController.h"
#import "WitnessCalibrationViewControllerDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(WitnessCalibrationViewControllerSpec)

describe(@"WitnessCalibrationViewController", ^{
    __block WitnessCalibrationViewController *controller;
    __block id<WitnessCalibrationViewControllerDelegate> delegate;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"WitnessCalibrationViewController"];
        delegate = nice_fake_for(@protocol(WitnessCalibrationViewControllerDelegate));
        [controller configureWithAudioLevelMeter:nil delegate:delegate];

        controller.view should_not be_nil;
    });

    it(@"should set the default language to english", ^{
        [WitnessLocalization witnessLanguageCode] should equal(@"en");
    });

    it(@"should display the selected language in the language selection button", ^{
        controller.languageSelectionButton.titleLabel.text should equal(@"ENGLISH");
    });

    describe(@"when the continue button is tapped", ^{
        beforeEach(^{
            [controller.continueButton tap];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(witnessCalibrationViewControllerDidContinue:)).with(controller);
        });
    });

    describe(@"when the language selection button is tapped", ^{
        __block UIPopoverController *popoverController;

        beforeEach(^{
            [controller.languageSelectionButton tap];
            popoverController = [UIPopoverController currentPopoverController];
        });

        it(@"should display a popover with the available languages", ^{
            popoverController.contentViewController should be_instance_of([LanguagesViewController class]);
        });

        context(@"when tapping on a language", ^{
            beforeEach(^{
                popoverController.contentViewController.view should_not be_nil;
                [popoverController.contentViewController viewWillAppear:NO];
                [popoverController.contentViewController viewDidAppear:NO];
                [((LanguagesViewController *)popoverController.contentViewController).tableView.visibleCells[1] tap];
            });

            it(@"should dismiss the popover controller", ^{
                [UIPopoverController currentPopoverController] should be_nil;
            });

            it(@"should change the language button", ^{
                controller.languageSelectionButton.titleLabel.text should equal(@"ESPAÑOL - SPANISH");
            });
        });
    });

});

SPEC_END
