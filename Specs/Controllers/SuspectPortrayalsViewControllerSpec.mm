#import <Foundation/Foundation.h>
#import "SuspectPhotoDetailViewController.h"
#import "SuspectPortrayalsViewController.h"
#import "Person.h"
#import "SuspectCardView.h"
#import "SuspectPortrayalCell.h"
#import "LineupViewController.h"
#import "Portrayal.h"
#import "PersonFactory.h"
#import "FaceLoader.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectPortrayalsViewControllerSpec)

describe(@"SuspectPortrayalsViewController", ^{
    __block SuspectPortrayalsViewController *controller;
    __block Person *person;

    NSArray *portrayalPhotoURLs = @[
            [[NSBundle mainBundle] URLForResource:@"463672-0" withExtension:@"jpg" subdirectory:@"PhotoRecords"],
            [[NSBundle mainBundle] URLForResource:@"463672-1" withExtension:@"jpg" subdirectory:@"PhotoRecords"]
    ];

    void(^configureAndPresentViewController)() = ^{
        [controller configureWithPerson:person];

        [UIApplication showViewController:controller];
    };

    beforeEach(^{
        person = [PersonFactory leon];
        person.portrayals = @[
                [[Portrayal alloc] initWithPhotoURL:portrayalPhotoURLs[0] date:[NSDate dateWithTimeIntervalSince1970:99912345]],
                [[Portrayal alloc] initWithPhotoURL:portrayalPhotoURLs[1] date:[NSDate dateWithTimeIntervalSince1970:99923456]]
        ];
        person.selectedPortrayal = person.portrayals.lastObject;

        controller = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectPortrayalsViewController"];

        configureAndPresentViewController();
    });

    sharedExamplesFor(@"syncing the portrayal view's image with the selected cell's image", ^(NSDictionary *sharedContext) {
        __block NSURL *selectedPortrayalPhotoURL;
        beforeEach(^{
            NSInteger indexOfSelectedCell = [(NSIndexPath *)controller.view.collectionView.indexPathsForSelectedItems.firstObject item];
            selectedPortrayalPhotoURL = portrayalPhotoURLs[indexOfSelectedCell];

            NSArray *connections = [[NSURLConnection connections] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURLConnection *connection, NSDictionary *bindings) {
                        return [connection.request.URL isEqual:selectedPortrayalPhotoURL];
                    }]];
            [connections makeObjectsPerformSelector:@selector(receiveResponse:) withObject:[[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:200 andHeaders:@{} andBodyData:[NSData dataWithContentsOfURL:selectedPortrayalPhotoURL]]];
        });

        it(@"should have asynchronously requested the new selected portrayals image", ^{
            [(controller.view.suspectCardView.imageView.image)
                    isEqualToByBytes:[UIImage imageWithContentsOfFile:selectedPortrayalPhotoURL.path]]
                    should be_truthy;
        });
    });

    describe(@"when preparing for segue", ^{
        context(@"and the destination is a SuspectPhotoDetailViewController", ^{
            __block SuspectPhotoDetailViewController *suspectPhotoDetailViewController;
            beforeEach(^{
                suspectPhotoDetailViewController = nice_fake_for([SuspectPhotoDetailViewController class]);
                UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"PushSuspectPhotoDetail"
                                                                           source:controller
                                                                      destination:suspectPhotoDetailViewController
                                                                   performHandler:^{}];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should configure the controller", ^{
                suspectPhotoDetailViewController should have_received(@selector(configureWithDelegate:person:portrayal:)).with(controller, person, person.portrayals.firstObject);
            });
        });
    });

    describe(@"when the view first loads", ^{
        it(@"should not show a delete button on the portrayal", ^{
            controller.view.suspectCardView.deleteButton.hidden should be_truthy;
        });

        it(@"should use the suspect ID and name as its title", ^{
            controller.title should equal(@"ID: 463672, Leon Lewis");
        });

        it(@"should display a portrayal cell for each available portrayal of the suspect", ^{
            controller.view.collectionView.visibleCells.count should equal(person.portrayals.count);
        });

        it(@"should configure the cell with the portrayal", ^{
            NSInteger indexOfCell = 1;

            //TODO: never allow more than one connection
            [[[NSURLConnection connections] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURLConnection *connection, NSDictionary *bindings) {
                return [connection.request.URL isEqual:portrayalPhotoURLs[indexOfCell]];
            }]] makeObjectsPerformSelector:@selector(receiveResponse:) withObject:[[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:200 andHeaders:@{} andBodyData:[NSData dataWithContentsOfURL:portrayalPhotoURLs[indexOfCell]]]];


            SuspectPortrayalCell *cell = (SuspectPortrayalCell *)[controller.view.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexOfCell inSection:0]];
            cell.dateLabel.text should equal(@"3/2/1973");
            [cell.imageView.image isEqualToByBytes:[UIImage imageWithContentsOfFile:[portrayalPhotoURLs[indexOfCell] path]]] should be_truthy;
        });

        it(@"should select the suspect portrayal cell matching the selected portrayal on the person", ^{
            SuspectPortrayalCell *cell = (SuspectPortrayalCell *)[controller.view.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
            cell.selected should be_truthy;
        });

        itShouldBehaveLike(@"syncing the portrayal view's image with the selected cell's image");
    });

    describe(@"when the view is about to appear", ^{
        beforeEach(^{
            spy_on(controller.view.suspectCardView); //TODO: should not have to call view lifecycle methods
            [controller viewWillAppear:NO];
        });

        it(@"should configure the portrayal view with the person and a face loader", ^{
            controller.view.suspectCardView should have_received(@selector(configureWithPerson:faceLoader:)).with(person, Arguments::any([FaceLoader class]));
        });
    });

    describe(@"selecting a portrayal", ^{
        __block SuspectPortrayalCell *firstCell;
        __block SuspectPortrayalCell *lastCell;

        beforeEach(^{
            firstCell = (SuspectPortrayalCell *)[controller.view.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            lastCell = (SuspectPortrayalCell *)[controller.view.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

            lastCell.selected should be_truthy;
            firstCell.selected should_not be_truthy;
        });

        context(@"that is already selected", ^{
            beforeEach(^{
                [lastCell tap];
            });

            it(@"should modally present a SuspectPhotoDetailViewController", ^{
                controller.presentedViewController should be_instance_of([SuspectPhotoDetailViewController class]);
            });

            describe(@"when the SuspectPhotoDetailViewController signals selection of a photo", ^{
                beforeEach(^{
                    [controller suspectPhotoDetailViewController:(SuspectPhotoDetailViewController *) controller.presentedViewController didSelectPortrayal:person.portrayals.lastObject];
                });

                itShouldBehaveLike(@"syncing the portrayal view's image with the selected cell's image");

                it(@"should not change the selected photo in the collection view", ^{
                    lastCell.selected should be_truthy;
                });

                it(@"should dismiss the modally presented controller", ^{
                    controller.presentedViewController should be_nil;
                });

                it(@"should update the selected portrayal on the person", ^{
                    person.selectedPortrayal should be_same_instance_as(person.portrayals.lastObject);
                });
            });
        });

        context(@"that is not selected", ^{
            beforeEach(^{
                [firstCell tap];
            });

            it(@"should modally present a SuspectPhotoDetailViewController", ^{
                controller.presentedViewController should be_instance_of([SuspectPhotoDetailViewController class]);
            });

            describe(@"when the SuspectPhotoDetailViewController signals selection of a photo", ^{
                beforeEach(^{
                    [controller suspectPhotoDetailViewController:(SuspectPhotoDetailViewController *) controller.presentedViewController didSelectPortrayal:person.portrayals.firstObject];
                    [controller viewWillAppear:NO];//TODO: fix this; currently necessary because of UIViewController+Spec stubs
                });

                itShouldBehaveLike(@"syncing the portrayal view's image with the selected cell's image");

                it(@"should dismiss the modally presented controller", ^{
                    controller.presentedViewController should be_nil;
                });

                it(@"should deselect the originally selected portrayal's cell", ^{
                    lastCell.selected should_not be_truthy;
                });

                it(@"should select the newly selected portrayal's cell", ^{
                    firstCell.selected should be_truthy;
                });

                it(@"should update the selected portrayal on the person", ^{
                    person.selectedPortrayal should be_same_instance_as(person.portrayals.firstObject);
                });
            });

            describe(@"when the SuspectPhotoDetailViewController signals cancelation", ^{
                beforeEach(^{
                    [controller suspectPhotoDetailViewControllerDidCancel:(SuspectPhotoDetailViewController *)controller.presentedViewController];
                });

                it(@"should dismiss the modally presented controller", ^{
                    controller.presentedViewController should be_nil;
                });

                it(@"should not change the selected photo in the collection view", ^{
                    lastCell.selected should be_truthy;
                });
            });
        });
    });

    describe(@"tapping 'Done'", ^{
        __block UINavigationController *navController;
        __block LineupViewController *lineupViewController;

        beforeEach(^{
            navController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupNavigationController"];
            [UIApplication showViewController:navController];
            lineupViewController = (LineupViewController *)navController.topViewController;
            [navController pushViewController:controller animated:NO];
            in_time(navController.view) should contain(controller.view).nested();

            spy_on(lineupViewController);
            [controller.navigationItem.rightBarButtonItem tap];
        });

        it(@"should exit to the lineup view controller", ^{
            navController.topViewController should be_same_instance_as(lineupViewController);
        });

        it(@"should call the unwind exit method on the lineup view controller", ^{
            lineupViewController should have_received(@selector(exitToLineup:));
        });
    });
});

SPEC_END
