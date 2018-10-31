#import "PerpetratorAttributesTableViewController.h"
#import "PerpetratorDescription.h"
#import "AdditionalNotesViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PerpetratorAttributesTableViewControllerSpec)

describe(@"PerpetratorAttributesTableViewController", ^{
    __block PerpetratorAttributesTableViewController *controller;
    __block PerpetratorDescription *perpetratorDescription;
    __block UINavigationController *navController;

    void(^configureAndPresentController)() = ^{
        [controller configureWithCaseID:@"12345" perpetratorDescription:perpetratorDescription];
        [UIApplication showViewController:navController];
    };

    beforeEach(^{
        perpetratorDescription = [[PerpetratorDescription alloc] init];
        controller = [[UIStoryboard storyboardWithName:@"WitnessDescription" bundle:nil] instantiateViewControllerWithIdentifier:@"PerpetratorAttributesTableViewController"];
        navController = [[UINavigationController alloc] initWithRootViewController:controller];
        configureAndPresentController();
    });

    describe(@"when the 'tap to edit' button of the Additional Description row is tapped", ^{
        beforeEach(^{
            [controller.additionalDescriptionTapToEditButton tap];
        });

        it(@"should push a AdditionalNotesVC on the nav stack", ^{
            [controller.navigationController topViewController] should be_instance_of([AdditionalNotesViewController class]);
        });
    });

    describe(@"preparing for a segue", ^{
        context(@"for an AdditionalNotesVC", ^{
            __block AdditionalNotesViewController *destinationController;

            beforeEach(^{
                destinationController = nice_fake_for([AdditionalNotesViewController class]);
                UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"ShowAddNotes" source:controller destination:destinationController performHandler:^{}];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should configure the controller", ^{
                destinationController should have_received(@selector(configureWithCaseID:perpetratorDescription:)).with(@"12345", perpetratorDescription);
            });
        });
    });
});

SPEC_END
