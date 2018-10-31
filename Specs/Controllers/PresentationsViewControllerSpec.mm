#import <MediaPlayer/MediaPlayer.h>
#import "PresentationsViewController.h"
#import "PresentationCell.h"
#import "PresentationStore.h"
#import "Presentation.h"
#import "MoviePlayerViewController.h"
#import "StitchingProgressIndicatorView.h"
#import "VideoStitcher.h"
#import "StitchingQueue.h"
#import "RecordingTimeAvailableCalculator.h"
#import "DefaultButton.h"
#import "AnalyticsTracker.h"
#import "CedarAsync.h"
#import "Lineup.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PresentationsViewControllerSpec)

describe(@"PresentationsViewController", ^{
    __block PresentationsViewController *controller;
    __block UINavigationController *navController;
    __block PresentationStore *presentationStore;
    __block NSMutableArray *allPresentations;
    NSURL *presentationVideoURL = [[NSBundle mainBundle] URLForResource:@"instructions" withExtension:@"mp4"];

    __block Presentation *stitchedPresentation;
    __block Presentation *stitchingPresentation;

    __block StitchingQueue *stitchingQueue;
    __block RecordingTimeAvailableCalculator *timeAvailableCalculator;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PresentationsViewController"];
        navController = [[UINavigationController alloc] initWithRootViewController:controller];

        Lineup *lineupForStitchedPresentation = nice_fake_for([Lineup class]);
        Lineup *lineupForStitchingPresentation = nice_fake_for([Lineup class]);

        lineupForStitchedPresentation stub_method(@selector(caseID)).and_return(@"ABC123");
        lineupForStitchingPresentation stub_method(@selector(caseID)).and_return(@"DEF456");

        presentationStore = nice_fake_for([PresentationStore class]);
        stitchedPresentation = nice_fake_for([Presentation class]);
        stitchedPresentation stub_method(@selector(date)).and_return([NSDate dateWithTimeIntervalSince1970:1389558900]);
        stitchedPresentation stub_method(@selector(lineup)).and_return(lineupForStitchedPresentation);
        stitchedPresentation stub_method(@selector(videoURL)).and_return(presentationVideoURL);
        stitchedPresentation stub_method(@selector(UUID)).and_return(@"UUID-FOR-THIS-ALREADY-STITCHED-PRESENTATION");

        stitchingPresentation = nice_fake_for([Presentation class]);
        stitchingPresentation stub_method(@selector(date)).and_return([NSDate dateWithTimeIntervalSince1970:1389559000]);
        stitchingPresentation stub_method(@selector(lineup)).and_return(lineupForStitchingPresentation);
        stitchingPresentation stub_method(@selector(UUID)).and_return(@"UUID-FOR-THIS-STITCHING-PRESENTATION");

        allPresentations = [NSMutableArray arrayWithObjects:stitchedPresentation, stitchingPresentation, nil];

        presentationStore stub_method(@selector(allPresentations)).and_do_block(^NSArray *{
           return allPresentations;
        });

        presentationStore stub_method(@selector(deletePresentation:)).with(stitchedPresentation).and_do_block(^(Presentation *presentationToDelete){
            [allPresentations removeObject:presentationToDelete];
        });

        presentationStore stub_method(@selector(presentationWithDate:)).with(stitchingPresentation.date).and_return(stitchingPresentation);

        stitchingQueue = nice_fake_for([StitchingQueue class]);
        timeAvailableCalculator = nice_fake_for([RecordingTimeAvailableCalculator class]);
        spy_on([AnalyticsTracker sharedInstance]);

        [controller configureWithPresentationStore:presentationStore
                  recordingTimeAvailableCalculator:timeAvailableCalculator
                                    stitchingQueue:stitchingQueue];
        controller.view should_not be_nil;

        NSMutableDictionary *context = [SpecHelper specHelper].sharedExampleContext;
        context[@"controller"] = controller;
        context[@"controllerTableView"] = controller.tableView;
        context[@"timeAvailableCalculator"] = timeAvailableCalculator;
    });

    it(@"should only support portrait upside-right orientation", ^{
        [controller supportedInterfaceOrientations] should equal(UIInterfaceOrientationMaskPortrait);
    });

    itShouldBehaveLike(@"show available recording time in the table header");

    describe(@"when the view appears", ^{
        beforeEach(^{
            VideoStitcher *stitcher = nice_fake_for([VideoStitcher class]);
            stitcher stub_method(@selector(progress)).and_return(0.4f);
            stitchingQueue stub_method(@selector(stitcherForPresentation:)).with(stitchingPresentation).and_return(stitcher);

            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];
        });

        describe(@"cells representing unstitched presentations", ^{
            __block PresentationCell *unstitchedPresentationCell;

            beforeEach(^{
                unstitchedPresentationCell = controller.tableView.visibleCells[0];
            });

            it(@"should display the correct data for the presentation", ^{
                unstitchedPresentationCell.dateLabel.text should equal(@"January 12, 2014 15:36");
                unstitchedPresentationCell.caseIDLabel.text should equal(@"DEF456");
            });

            it(@"should display the progress of stitching", ^{
                unstitchedPresentationCell.indicatorView.progress should be_close_to(0.4).within(0.001);
            });

            it(@"should not allow the user to begin the presentation", ^{
                unstitchedPresentationCell.viewPresentationButton.hidden should be_truthy;
            });
        });

        describe(@"cells representing stitched presentations", ^{
            __block PresentationCell *stitchedPresentationCell;

            beforeEach(^{
                stitchedPresentationCell = controller.tableView.visibleCells[1];
            });

            it(@"should display the correct data for the presentation", ^{
                stitchedPresentationCell.dateLabel.text should equal(@"January 12, 2014 15:35");
                stitchedPresentationCell.caseIDLabel.text should equal(@"ABC123");
            });

            it(@"should allow the user to begin the presentation", ^{
                stitchedPresentationCell.viewPresentationButton.hidden should be_falsy;
            });

            describe(@"when the user taps the view presentation button", ^{
                beforeEach(^{
                    spy_on(navController);
                    navController stub_method(@selector(presentMoviePlayerViewControllerAnimated:));
                    [stitchedPresentationCell.viewPresentationButton tap];
                });

                it(@"should show a movie player", ^{
                    navController should have_received(@selector(presentMoviePlayerViewControllerAnimated:)).with(Arguments::any([MoviePlayerViewController class]));
                });

                it(@"should track the presentation playback", ^{
                    NSTimeInterval length = CMTimeGetSeconds([AVURLAsset URLAssetWithURL:presentationVideoURL options:nil].duration);
                    in_time([AnalyticsTracker sharedInstance]) should have_received(@selector(trackPresentationPlaybackWithLength:)).with(length);
                });
            });
        });

        it(@"should ensure it has the latest list of presentations", ^{
            presentationStore should have_received(@selector(reload));
        });

        it(@"should show a list of presentations", ^{
            controller.tableView.visibleCells.firstObject should be_instance_of([PresentationCell class]);
        });

        it(@"should display the presentations with the most recent one at the top", ^{
            ((PresentationCell *)controller.tableView.visibleCells[0]).dateLabel.text should equal(@"January 12, 2014 15:36");
            ((PresentationCell *)controller.tableView.visibleCells[1]).dateLabel.text should equal(@"January 12, 2014 15:35");
        });

        it(@"should start observing the stitching queue for updates", ^{
            stitchingQueue should have_received(@selector(addStitchingObserver:)).with(controller);
        });

        it(@"should have an edit button", ^{
            controller.navigationItem.rightBarButtonItem should equal(controller.editButtonItem);
        });
    });

    describe(@"when the view disappears", ^{
        beforeEach(^{
            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];

            [controller viewWillDisappear:NO];
            [controller viewDidDisappear:NO];
        });

        it(@"should stop observing the stitching queue for updates", ^{
            stitchingQueue should have_received(@selector(removeStitchingObserver:)).with(controller);
        });
    });

    describe(@"updating the progress indicator", ^{
        __block PresentationCell *cell;

        beforeEach(^{
            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];

            cell = controller.tableView.visibleCells[0];
        });

        describe(@"when the progress updates", ^{
            beforeEach(^{
                [controller stitchingQueue:stitchingQueue didUpdateProgress:0.6f forPresentationUUID:stitchingPresentation.UUID];
            });

            it(@"should update the cell's progress indicator view", ^{
                cell.indicatorView.progress should be_close_to(0.6f).within(0.001f);
            });
        });

        context(@"stitching completes", ^{
            beforeEach(^{
                [controller.tableView layoutIfNeeded];

                [controller stitchingQueue:stitchingQueue didCompleteStitchingForPresentationUUID:stitchingPresentation.UUID];

                cell = (PresentationCell *)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });

            it(@"should hide the progress indicator view", ^{
                cell.indicatorView.hidden should be_truthy;
            });

            it(@"should show the view presentation button", ^{
                cell.viewPresentationButton.hidden should be_falsy;
            });

            context(@"when tapping on the button", ^{
                beforeEach(^{
                    spy_on(navController);
                    navController stub_method(@selector(presentMoviePlayerViewControllerAnimated:));

                    stitchingPresentation stub_method(@selector(videoURL)).and_return([NSURL URLWithString:@"a/url"]);
                    [cell.viewPresentationButton tap];
                });

                it(@"should show the video", ^{
                    navController should have_received(@selector(presentMoviePlayerViewControllerAnimated:)).with(Arguments::any([MoviePlayerViewController class]));
                });
            });
        });

        context(@"stitching fails/cancelled", ^{
            beforeEach(^{
                [controller.tableView layoutIfNeeded];
                [controller stitchingQueue:stitchingQueue didCancelStitchingForPresentationUUID:stitchingPresentation.UUID];
                cell = (PresentationCell *)[controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });

            it(@"should hide the progress indicator view", ^{
                cell.indicatorView.hidden should be_truthy;
            });

            it(@"should show the view presentation button in the warning state", ^{
                cell.viewPresentationButton.hidden should be_falsy;
                cell.viewPresentationButton.style should equal(ButtonStyleWarn);
            });
        });
    });

    describe(@"deleting a presentation", ^{
        beforeEach(^{
            [controller.editButtonItem tap];

            PresentationCell *cell = controller.tableView.visibleCells[1];
            [cell tapDeleteAccessory];
            [cell tapDeleteConfirmation];
        });

        it(@"should show an alert view", ^{
            UIAlertView *alertView = [UIAlertView currentAlertView];
            alertView.title should equal(@"Are you sure you want to delete this presentation?");
            alertView.message should equal(@"This cannot be undone.");
            [alertView buttonTitleAtIndex:alertView.cancelButtonIndex] should equal(@"Delete");
            [alertView buttonTitleAtIndex:1] should equal(@"Cancel");
        });

        context(@"cancel button is tapped", ^{
            beforeEach(^{
                [[UIAlertView currentAlertView] dismissWithClickedButtonIndex:1 animated:NO];
            });

            it(@"should end editing", ^{
                controller.editing should be_falsy;
            });
        });

        context(@"delete button is tapped", ^{
            beforeEach(^{
                [[UIAlertView currentAlertView] dismissWithCancelButton];
            });

            it(@"should delete the presentation from the store", ^{
                presentationStore should have_received(@selector(deletePresentation:)).with(stitchedPresentation);
            });

            it(@"should remove the presentation from the list", ^{
                controller.tableView.visibleCells.count should equal(1);
                [presentationStore presentationWithDate:stitchedPresentation.date] should be_nil;
            });
        });

        describe(@"updating the recording time available after deletion", ^{
            beforeEach(^{
                [SpecHelper specHelper].sharedExampleContext[@"subjectAction"] = ^{
                    [[UIAlertView currentAlertView] dismissWithCancelButton];
                };
            });

            itShouldBehaveLike(@"updating the available recording time in the table header");
        });
    });
});

SPEC_END
