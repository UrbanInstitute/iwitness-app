#import "LineupsViewController.h"
#import "LineupStore.h"
#import "Lineup.h"
#import "LineupCell.h"
#import "PortraitOnlyNavigationController.h"
#import "RecordingTimeAvailableCalculator.h"
#import "PresentationStore.h"
#import "Presentation.h"
#import "PresentationFlowViewControllerProvider.h"
#import "PhotoAssetImporter.h"
#import "AnalyticsTracker.h"
#import "LineupViewControllerConfigurer.h"
#import "SuspectSearchSplitViewControllerProvider.h"
#import "Person.h"
#import "Portrayal.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "SuspectPortrayalsViewControllerProvider.h"
#import "PersonSearchServiceProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupsViewControllerSpec)

describe(@"LineupsViewController", ^{
    __block LineupsViewController *controller;
    __block PresentationFlowViewControllerProvider *presentationFlowViewControllerProvider;
    __block LineupStore *lineupStore;
    __block PresentationStore *presentationStore;
    __block Presentation *createdPresentation;
    __block NSMutableArray *storedLineups;
    __block RecordingTimeAvailableCalculator *timeAvailableCalculator;
    __block PhotoAssetImporter *photoAssetImporter;
    __block AnalyticsTracker *analyticsTracker;
    __block LineupViewControllerConfigurer *lineupViewControllerConfigurer;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupsViewController"];
        spy_on(controller);

        presentationFlowViewControllerProvider = nice_fake_for([PresentationFlowViewControllerProvider class]);
        presentationFlowViewControllerProvider stub_method(@selector(presentationFlowViewControllerWithPresentation:flowDelegate:)).and_return(nice_fake_for([PresentationFlowViewController class]));

        Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"file://suspects/1.jpg"] date:[NSDate date]];

        Person *suspect1 = [[Person alloc] init];
        suspect1.portrayals = @[portrayal];

        Lineup *lineup1 = [[Lineup alloc] initWithCreationDate:[NSDate dateWithTimeIntervalSince1970:1392067396] suspect:suspect1];
        lineup1.caseID = @"1234";
        lineup1.fillerPhotosFileURLs = @[ [NSURL URLWithString:@"file://fillers/1.jpg"],
                                          [NSURL URLWithString:@"file://fillers/2.jpg"],
                                          [NSURL URLWithString:@"file://fillers/3.jpg"],
                                          [NSURL URLWithString:@"file://fillers/4.jpg"],
                                          [NSURL URLWithString:@"file://fillers/5.jpg"]
                                          ];

        Person *suspect2 = [[Person alloc] init];
        suspect2.portrayals = @[portrayal];

        Lineup *lineup2 = [[Lineup alloc] init];
        lineup2.suspect = suspect2;
        lineup2.caseID = @"2345";
        lineup2.fillerPhotosFileURLs = @[ [NSURL URLWithString:@"file://fillers/1.jpg"] ];

        lineup1.valid should be_truthy;
        lineup2.valid should be_falsy;

        Lineup *lineup3 = [[Lineup alloc] init];
        lineup3.caseID = @"3456";

        storedLineups = [@[ lineup1, lineup2, lineup3 ] mutableCopy];

        lineupStore = nice_fake_for([LineupStore class]);
        lineupStore stub_method(@selector(allLineups)).and_do_block(^NSArray * {
            return [storedLineups copy];
        });

        createdPresentation = nice_fake_for([Presentation class]);
        presentationStore = fake_for([PresentationStore class]);
        presentationStore stub_method(@selector(createPresentationWithLineup:)).and_return(createdPresentation);
        presentationStore stub_method(@selector(deletePresentation:));

        timeAvailableCalculator = nice_fake_for([RecordingTimeAvailableCalculator class]);
        photoAssetImporter = nice_fake_for([PhotoAssetImporter class]);
        analyticsTracker = fake_for([AnalyticsTracker class]);
        lineupViewControllerConfigurer = [[LineupViewControllerConfigurer alloc] initWithLineupStore:lineupStore
                                                                                  photoAssetImporter:photoAssetImporter
                                                                                            delegate:controller];

        [controller configureWithPresentationFlowViewControllerProvider:presentationFlowViewControllerProvider
                                                            lineupStore:lineupStore
                                                      presentationStore:presentationStore
                                       recordingTimeAvailableCalculator:timeAvailableCalculator
                                        lineupViewControllerConfigurer:lineupViewControllerConfigurer];

        controller.view should_not be_nil;
        [controller.view layoutIfNeeded];
        [controller viewWillAppear:NO];
    });

    describe(@"displaying remaining recording space", ^{
        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupsViewController"];
            [controller configureWithPresentationFlowViewControllerProvider:presentationFlowViewControllerProvider
                                                                lineupStore:lineupStore
                                                          presentationStore:presentationStore
                                           recordingTimeAvailableCalculator:timeAvailableCalculator
                                             lineupViewControllerConfigurer:lineupViewControllerConfigurer];
            controller.view should_not be_nil;

            NSMutableDictionary *context = [SpecHelper specHelper].sharedExampleContext;
            context[@"controller"] = controller;
            context[@"controllerTableView"] = controller.lineupsTableView;
            context[@"timeAvailableCalculator"] = timeAvailableCalculator;
        });

        itShouldBehaveLike(@"show available recording time in the table header");
    });

    describe(@"listing lineups in the lineup store", ^{
        it(@"should list all lineups", ^{
            [controller.lineupsTableView numberOfRowsInSection:0] should equal(3);
        });

        it(@"should list them in the correct order", ^{
            LineupCell *cell = (LineupCell *)[controller tableView:controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell.caseID should equal(@"1234");
            cell.dateString should equal(@"2/10/14");

            ((LineupCell *)[controller tableView:controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]).caseID should equal(@"2345");
            ((LineupCell *)[controller tableView:controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]]).caseID should equal(@"3456");
        });

        it(@"should display the appropriate PRESENT TO WITNESS button", ^{
            LineupCell *validLineupCell = (LineupCell *)[controller tableView:controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            LineupCell *invalidLineupCell = (LineupCell *)[controller tableView:controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            validLineupCell.presentToWitnessButton.enabled should be_truthy;
            invalidLineupCell.presentToWitnessButton.enabled should be_falsy;
        });
    });

    describe(@"expanding and collapsing lineups in the list", ^{
        __block LineupCell *cell;
        beforeEach(^{
            cell = controller.lineupsTableView.visibleCells.firstObject;
        });

        void(^simulateCellTap)(NSIndexPath *) = ^(NSIndexPath *indexPath){
            BOOL alreadySelected = [[controller.lineupsTableView indexPathsForSelectedRows] containsObject:indexPath];

            if (alreadySelected) {
                [controller.lineupsTableView deselectRowAtIndexPath:indexPath animated:NO];
                [controller tableView:controller.lineupsTableView didDeselectRowAtIndexPath:indexPath];
            } else {
                [controller tableView:controller.lineupsTableView willSelectRowAtIndexPath:indexPath];
                [controller.lineupsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                [controller tableView:controller.lineupsTableView didSelectRowAtIndexPath:[controller.lineupsTableView indexPathForCell:cell]];
                [controller.lineupsTableView indexPathsForSelectedRows] should_not be_empty;
            }
        };

        describe(@"expanding a collapsed lineup cell", ^{
            beforeEach(^{
                simulateCellTap([NSIndexPath indexPathForRow:0 inSection:0]);
                [controller.lineupsTableView layoutIfNeeded];
                cell = (LineupCell *)[controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });

            it(@"should make the expanded cell taller than a collapsed cell", ^{
                CGRect expandedFrame = [controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].frame;
                CGRect collapsedFrame = [controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].frame;

                CGFloat expandedHeight = [controller tableView:controller.lineupsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                CGFloat collapsedHeight = [controller tableView:controller.lineupsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

                expandedHeight should be_greater_than(collapsedHeight);
                CGRectGetHeight(expandedFrame) should be_greater_than(CGRectGetHeight(collapsedFrame));
            });
        });

        describe(@"tapping an expanded lineup cell", ^{
            beforeEach(^{
                simulateCellTap([NSIndexPath indexPathForRow:0 inSection:0]);
                [controller.lineupsTableView layoutIfNeeded];

                simulateCellTap([NSIndexPath indexPathForRow:0 inSection:0]);
                [controller.lineupsTableView layoutIfNeeded];

                cell = (LineupCell *)[controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });

            it(@"should restore the expanded cell to the collapsed height", ^{
                CGFloat collapsedHeight = [controller tableView:controller.lineupsTableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                collapsedHeight should equal(controller.lineupsTableView.rowHeight);
            });

            it(@"should deselect (i.e. collapse) the cell", ^{
                [controller.lineupsTableView indexPathsForSelectedRows] should be_empty;
            });
        });
    });

    describe(@"when a presentation completes", ^{
        beforeEach(^{
            LineupCell *cell = controller.lineupsTableView.visibleCells.firstObject;
            cell.selected = YES;
            [cell.presentToWitnessButton tap];
            controller.presentedViewController should_not be_nil;
        });

        context(@"by finishing normally", ^{
            beforeEach(^{
                [controller presentationFlowViewControllerDidFinish:nil];
            });

            it(@"should dismiss the presented view controller", ^{
                controller.presentedViewController should be_nil;
            });
        });

        context(@"by being canceled", ^{
            beforeEach(^{
                [controller presentationCanceled:nil];
            });

            it(@"should remove the presentation that was in progress", ^{
                presentationStore should have_received(@selector(deletePresentation:)).with(createdPresentation);
            });
        });
    });

    describe(@"starting a presentation", ^{
        beforeEach(^{
            LineupCell *cell = controller.lineupsTableView.visibleCells.firstObject;
            cell.selected = YES;
            [cell.presentToWitnessButton tap];
        });

        it(@"should start a modal presentation flow", ^{
            [controller.presentedViewController view];
            controller.presentedViewController should be_instance_of([PresentationFlowViewController class]);
        });

        it(@"should have created a presentation in the presentation store", ^{
            presentationStore should have_received(@selector(createPresentationWithLineup:));
        });
    });

    describe(@"each time the view will appear", ^{
        beforeEach(^{
            Lineup *newLineup = [[Lineup alloc] init];
            Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"file://suspects/new.jpg"] date:[NSDate date]];
            newLineup.caseID = @"123457";
            newLineup.suspect.portrayals = @[portrayal];
            newLineup.fillerPhotosFileURLs = @[[NSURL URLWithString:@"file://fillers/new.jpg"]];
            [storedLineups addObject:newLineup];

            [controller.lineupsTableView numberOfRowsInSection:0] should equal(3);
            [controller viewWillAppear:NO];
        });

        it(@"should update table of lineups when returning from the lineup view controller", ^{
            [controller.lineupsTableView numberOfRowsInSection:0] should equal(4);
        });
    });

    describe(@"creating a lineup", ^{
        beforeEach(^{
            [controller.createLineupButton tap];
        });

        it(@"should open an empty lineup view controller modally", ^{
            controller.presentedViewController should be_instance_of([PortraitOnlyNavigationController class]);
            [(UINavigationController *)controller.presentedViewController topViewController] should be_instance_of([LineupViewController class]);
        });

        describe(@"when the lineup view controller completes", ^{
            beforeEach(^{
                LineupViewController * lineupViewController = (LineupViewController *)[(UINavigationController *)controller.presentedViewController topViewController];
                [controller lineupViewControllerDidComplete:lineupViewController];
            });

            it(@"should remove the lineup view controller once it has completed", ^{
                controller.presentedViewController should be_nil;
            });
        });
    });

    describe(@"configuring the lineup view controller", ^{
        __block UINavigationController *navigationController;
        __block LineupViewController *lineupViewController;

        beforeEach(^{
            lineupViewController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupViewController"];
            spy_on(lineupViewController);
            navigationController = [[UINavigationController alloc] initWithRootViewController:lineupViewController];
        });

        context(@"for creating a new lineup", ^{
            beforeEach(^{
                UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"ShowCreateLineup"
                                                                                  source:controller
                                                                             destination:navigationController];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should configure the lineup controller with a store and delegate", ^{
                lineupViewController should have_received(@selector(configureWithLineupStore:lineup:photoAssetImporter:suspectSearchSplitViewControllerProvider:perpetratorDescriptionViewControllerProvider:suspectPortrayalsViewControllerProvider:personSearchServiceProvider:delegate:)).with(lineupStore, nil, photoAssetImporter, Arguments::any([SuspectSearchSplitViewControllerProvider class]), Arguments::any([PerpetratorDescriptionViewControllerProvider class]), Arguments::any([SuspectPortrayalsViewControllerProvider class]), Arguments::any([PersonSearchServiceProvider class]), controller);
            });
        });

        context(@"for editing an existing lineup", ^{
            __block Lineup *tappedLineup;

            beforeEach(^{
                UITableViewCell *tappedCell = [controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"ShowEditLineup"
                                                                                  source:controller
                                                                             destination:navigationController];

                tappedLineup = [[lineupStore allLineups] firstObject];

                [controller prepareForSegue:segue sender:tappedCell];
            });

            it(@"should configure the lineup controller with a store, the tapped lineup, and delegate", ^{
                lineupViewController should have_received(@selector(configureWithLineupStore:lineup:photoAssetImporter:suspectSearchSplitViewControllerProvider:perpetratorDescriptionViewControllerProvider:suspectPortrayalsViewControllerProvider:personSearchServiceProvider:delegate:)).with(lineupStore, tappedLineup, photoAssetImporter, Arguments::any([SuspectSearchSplitViewControllerProvider class]), Arguments::any([PerpetratorDescriptionViewControllerProvider class]), Arguments::any([SuspectPortrayalsViewControllerProvider class]), Arguments::any([PersonSearchServiceProvider class]), controller);
            });
        });
    });

    describe(@"editing a lineup", ^{
        __block UINavigationController *navController;

        beforeEach(^{
            [controller.lineupsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            UITableViewCell *cell = [controller.lineupsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            navController = [[UINavigationController alloc] initWithRootViewController:controller];

            [controller performSegueWithIdentifier:@"ShowEditLineup" sender:cell];
        });

        it(@"should open a lineup view controller modally", ^{
            controller.presentedViewController should be_instance_of([PortraitOnlyNavigationController class]);
            [(UINavigationController *)controller.presentedViewController topViewController] should be_instance_of([LineupViewController class]);
        });

        describe(@"when the lineup view controller completes", ^{
            beforeEach(^{
                LineupViewController * lineupViewController = (LineupViewController *)[(UINavigationController *)controller.presentedViewController topViewController];
                [controller lineupViewControllerDidComplete:lineupViewController];
            });

            it(@"should dismiss the lineup view controller once it has completed", ^{
                controller.presentedViewController should be_nil;
            });

            it(@"should select the cell of the lineup which was being edited", ^{
                [controller.lineupsTableView indexPathsForSelectedRows] should contain([NSIndexPath indexPathForRow:0 inSection:0]);
            });
        });
    });
});

SPEC_END
