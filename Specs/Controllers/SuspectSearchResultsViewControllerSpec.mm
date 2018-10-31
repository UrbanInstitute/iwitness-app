#import "SuspectSearchResultsViewController.h"
#import "PersonSearchService.h"
#import "Person.h"
#import "Portrayal.h"
#import "FaceLoader.h"
#import "PersonResultCell.h"
#import "SuspectCardView.h"
#import "SuspectSearchResultsHeaderView.h"
#import "SuspectPortrayalsViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectSearchResultsViewControllerSpec)

describe(@"SuspectSearchResultsViewController", ^{
    __block SuspectSearchResultsViewController *controller;
    __block UINavigationController *navController;
    __block PersonSearchService *personSearchService;
    __block KSDeferred *personResultsDeferred;

    beforeEach(^{
        personResultsDeferred = [KSDeferred defer];
        personSearchService = fake_for([PersonSearchService class]);
        personSearchService stub_method(@selector(personResultsForFirstName:lastName:suspectID:)).and_return(personResultsDeferred.promise);

        controller = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectSearchResultsViewController"];
        [controller configureWithPersonSearchService:personSearchService];

        navController = [[UINavigationController alloc] initWithRootViewController:controller];

        controller.view should_not be_nil;
        [controller.view layoutIfNeeded];
    });

    it(@"should not indicate any number of results", ^{
        controller.view.suspectSearchResultsHeaderView.numberOfResultsLabel.text should equal(@"");
    });

    describe(@"handling search requests", ^{
        beforeEach(^{
            [controller suspectSearchViewController:nil didRequestSearchWithFirstName:@"Leon" lastName:@"Lewis" suspectID:@"45234" ];
        });

        it(@"should request search results", ^{
            personSearchService should have_received(@selector(personResultsForFirstName:lastName:suspectID:)).with(@"Leon", @"Lewis", @"45234");
        });

        context(@"when the results are available", ^{
            __block Person *person;
            __block PersonResultCell *vendedPersonResultCell;

            beforeEach(^{
                NSDate *dateOfBirth = [NSDate dateWithTimeIntervalSince1970:159235200];
                NSURL *photoURL = [[NSBundle mainBundle] URLForResource:@"463672-0" withExtension:@"jpg" subdirectory:@"PhotoRecords"];
                Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:photoURL date:[NSDate date]];
                person = [[Person alloc] initWithFirstName:@"Leon" lastName:@"Lewis" dateOfBirth:dateOfBirth systemID:@"463672" portrayals:@[portrayal]];

                [personResultsDeferred resolveWithValue:@[person]];
            });

            describe(@"getting collection view cells", ^{
                beforeEach(^{
                    vendedPersonResultCell = [[PersonResultCell alloc] init];
                    spy_on(vendedPersonResultCell);
                    vendedPersonResultCell stub_method(@selector(reuseIdentifier)).and_return(@"PersonResultCell");

                    spy_on(controller.view.collectionView);
                    controller.view.collectionView stub_method(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:)).with(@"PersonResultCell", [NSIndexPath indexPathForItem:0 inSection:0]).and_return(vendedPersonResultCell);

                    [controller.view.collectionView.dataSource collectionView:controller.view.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                });

                it(@"should configure the cell with the person and a face loader", ^{
                    vendedPersonResultCell should have_received(@selector(configureWithPerson:faceLoader:)).with(person, Arguments::any([FaceLoader class]));
                });
            });

            describe(@"and the collection view lays out its contents", ^{
                beforeEach(^{
                    [controller.view.collectionView layoutIfNeeded];
                });

                it(@"should indicate the number of results", ^{
                    controller.view.suspectSearchResultsHeaderView.numberOfResultsLabel.text should equal(@"1 result");
                });

                it(@"should present the person result cell", ^{
                    [controller.view.collectionView visibleCells].firstObject should be_instance_of([PersonResultCell class]);
                });

                describe(@"tapping a result", ^{
                    beforeEach(^{
                        [controller.view.collectionView.visibleCells.firstObject tap];
                    });

                    it(@"should show the portrayals view controller", ^{
                        navController.topViewController should be_instance_of([SuspectPortrayalsViewController class]);
                    });
                });
            });
        });

        context(@"when no results are available", ^{
            beforeEach(^{
                [personResultsDeferred resolveWithValue:@[]];
                [controller.view.collectionView layoutIfNeeded];
            });

            it(@"should indicate that there are no results", ^{
                controller.view.suspectSearchResultsHeaderView.numberOfResultsLabel.text should equal(@"0 results");
            });

            it(@"should show no result cells", ^{
                controller.view.collectionView.visibleCells should be_empty;
            });
        });

        context(@"when the service throws an error", ^{
            beforeEach(^{
                [personResultsDeferred rejectWithError:nil];
            });
        });
    });
});

SPEC_END
