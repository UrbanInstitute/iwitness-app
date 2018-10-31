#import "LineupPerpetratorDescriptionViewController.h"
#import "PerpetratorDescription.h"
#import "PerpetratorDescriptionViewController.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "Lineup.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupPerpetratorDescriptionViewControllerSpec)

describe(@"LineupPerpetratorDescriptionViewController", ^{
    __block PerpetratorDescriptionViewControllerProvider *perpetratorDescriptionViewControllerProvider;
    __block LineupPerpetratorDescriptionViewController *controller;
    __block UINavigationController *navController;
    __block Lineup *lineup;

    void(^configureAndPresentController)() = ^{
        [controller configureWithLineup:lineup perpetratorDescriptionViewControllerProvider:perpetratorDescriptionViewControllerProvider];
        navController = [[UINavigationController alloc] initWithRootViewController:controller];
        [UIApplication showViewController:navController];
    };

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupPerpetratorDescriptionViewController"];

        lineup = [[Lineup alloc] init];
        lineup.caseID = @"9912345";

        perpetratorDescriptionViewControllerProvider = nice_fake_for([PerpetratorDescriptionViewControllerProvider class]);
    });


    describe(@"when the view is about to appear", ^{
        context(@"when additional details is nil", ^{
            beforeEach(^{
                lineup.perpetratorDescription.additionalNotes = nil;
                configureAndPresentController();
            });

            it(@"should blank out the prepetrator description", ^{
                controller.perpetratorDescriptionLabel.text should equal(@"");
            });
        });

        context(@"when additional details is blank", ^{
            beforeEach(^{
                lineup.perpetratorDescription.additionalNotes = @"";
                configureAndPresentController();
            });

            it(@"should show the witness perpetrator description", ^{
                controller.perpetratorDescriptionLabel.text should equal(@"");
            });
        });

        context(@"when additional details present", ^{
            beforeEach(^{
                lineup.perpetratorDescription.additionalNotes = @"She had long fingernails.";
                configureAndPresentController();
            });

            it(@"should show the witness perpetrator description", ^{
                controller.perpetratorDescriptionLabel.text should equal(@"Witness said:\n“She had long fingernails.”");
            });

            describe(@"when the view is about to appear again and the description has been changed", ^{
                beforeEach(^{
                    lineup.perpetratorDescription.additionalNotes = @"His hair looked stupid.";
                    configureAndPresentController();
                });

                it(@"should update the witness perpetrator description", ^{
                    controller.perpetratorDescriptionLabel.text should equal(@"Witness said:\n“His hair looked stupid.”");
                });
            });
        });
    });

    describe(@"when editing is enabled", ^{
        beforeEach(^{
            configureAndPresentController();
            controller.editing = NO;
            controller.editing = YES;
        });

        it(@"should show the Add Description button", ^{
            controller.addDescriptionButton.hidden should be_falsy;
        });

        describe(@"when the add description button is tapped", ^{
            __block PerpetratorDescriptionViewController *perpetratorDescriptionViewController;

            beforeEach(^{
                perpetratorDescriptionViewController = [[PerpetratorDescriptionViewController alloc] init];
                perpetratorDescriptionViewControllerProvider stub_method(@selector(perpetratorDescriptionViewControllerWithCaseID:perpetratorDescription:)).with(@"9912345", lineup.perpetratorDescription).and_return(perpetratorDescriptionViewController);
                [controller.addDescriptionButton tap];
            });

            it(@"should push a PerpetratorDescriptionViewController onto the navigation stack", ^{
                navController.topViewController should be_same_instance_as(perpetratorDescriptionViewController);
            });
        });
    });

    describe(@"when editing is disabled", ^{
        beforeEach(^{
            configureAndPresentController();
            controller.editing = NO;
        });

        it(@"should not show the Add Description button", ^{
            controller.addDescriptionButton.hidden should be_truthy;
        });
    });

    describe(@"when the lineup has been changed externally and the controller leaves editing mode", ^{
        beforeEach(^{
            lineup.perpetratorDescription.additionalNotes = @"He had a really cool tattoo.";
            configureAndPresentController();
            controller.editing = YES;
            lineup.perpetratorDescription.additionalNotes = @"On second thought, his tattoo was not that cool.";
            controller.editing = NO;
        });

        it(@"should update according to the model", ^{
            controller.perpetratorDescriptionLabel.text should equal(@"Witness said:\n“On second thought, his tattoo was not that cool.”");
        });
    });
});

SPEC_END
