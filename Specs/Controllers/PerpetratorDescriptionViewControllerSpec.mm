#import "PerpetratorDescriptionViewController.h"
#import "PerpetratorAttributesTableViewController.h"
#import "PerpetratorDescription.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PerpetratorDescriptionViewControllerSpec)

describe(@"PerpetratorDescriptionViewController", ^{
    __block PerpetratorDescriptionViewController *controller;
    __block PerpetratorDescription *perpetratorDescription;

    void(^configureAndPresentController)() = ^{
        [controller configureWithCaseID:@"12345" perpetratorDescription:perpetratorDescription];
        [UIApplication showViewController:controller];
    };

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"WitnessDescription" bundle:nil] instantiateViewControllerWithIdentifier:@"PerpetratorDescriptionViewController"];

        perpetratorDescription = [[PerpetratorDescription alloc] init];

        configureAndPresentController();
    });

    it(@"should display the case ID", ^{
        controller.view.caseIDLabel.text should equal(@"12345");
    });

    it(@"should display no additional notes", ^{
        controller.view.descriptionLabel.text should equal(@"");
    });

    describe(@"when embedding child view controllers", ^{
        describe(@"the PerpetratorAttributesTableViewController", ^{
            __block PerpetratorAttributesTableViewController *attributesController;

            beforeEach(^{
                attributesController = nice_fake_for([PerpetratorAttributesTableViewController class]);
                UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"EmbedPerpAttributes"
                                                                           source:controller
                                                                      destination:attributesController
                                                                   performHandler:^{}];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should be configured with the lineup", ^{
                attributesController should have_received(@selector(configureWithCaseID:perpetratorDescription:)).with(@"12345", perpetratorDescription);
            });
        });
    });

    describe(@"when the additional description is changed and the controller is displayed again", ^{
        beforeEach(^{
            [UIApplication showViewController:[[UIViewController alloc] init]];
            perpetratorDescription.additionalNotes = @"He had a conjoined fetus hanging off his head!";
            [UIApplication showViewController:controller];
        });

        it(@"should update the additional notes label", ^{
            controller.view.descriptionLabel.text should equal(@"Witness said:\n“He had a conjoined fetus hanging off his head!”");
        });
    });
});

SPEC_END
