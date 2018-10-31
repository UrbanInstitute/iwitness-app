#import "SuspectSearchViewController.h"
#import "SuspectSearchViewControllerDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectSearchViewControllerSpec)

describe(@"SuspectSearchViewController", ^{
    __block SuspectSearchViewController *controller;
    __block id<SuspectSearchViewControllerDelegate> delegate;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectSearchViewController"];
        delegate = nice_fake_for(@protocol(SuspectSearchViewControllerDelegate));

        controller.view should_not be_nil;
        [controller configureWithCaseID:@"12345" delegate:delegate];
    });

    it(@"should set its title", ^{
        controller.title should equal(@"Suspect Search");
    });

    it(@"should display the case ID", ^{
        controller.view.caseIDLabel.text should equal(@"12345");
    });

    describe(@"tapping the search button", ^{
        beforeEach(^{
            controller.view.firstNameTextField.text = @"Leon";
            controller.view.lastNameTextField.text = @"Lewis";
            controller.view.suspectIDTextField.text = @"123456";
            spy_on(controller.view.firstNameTextField);
            spy_on(controller.view.lastNameTextField);
            spy_on(controller.view.suspectIDTextField);

            [controller.view.searchButton tap];
        });

        it(@"should notify its delegate", ^{
            delegate should have_received(@selector(suspectSearchViewController:didRequestSearchWithFirstName:lastName:suspectID:)).with(controller, @"Leon", @"Lewis", @"123456");
        });

        it(@"should dismiss the keyboard", ^{
            controller.view.firstNameTextField should have_received(@selector(resignFirstResponder));
            controller.view.lastNameTextField should have_received(@selector(resignFirstResponder));
            controller.view.suspectIDTextField should have_received(@selector(resignFirstResponder));
        });

        it(@"should disable the search button", ^{
            controller.view.searchButton.enabled should_not be_truthy;
        });

        context(@"editing the search", ^{
            beforeEach(^{
                controller.view.lastNameTextField.text = @"Lewi";
                [controller textField:controller.view.lastNameTextField shouldChangeCharactersInRange:NSMakeRange(4, 1) replacementString:@""];
            });

            it(@"should reenable the search button", ^{
                controller.view.searchButton.enabled should be_truthy;
            });
        });
    });
});

SPEC_END
