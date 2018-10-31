#import "LineupViewControllerConfigurer.h"
#import "LineupStore.h"
#import "Lineup.h"
#import "PhotoAssetImporter.h"
#import "AnalyticsTracker.h"
#import "LineupViewController.h"
#import "SuspectSearchSplitViewControllerProvider.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "SuspectPortrayalsViewControllerProvider.h"
#import "PersonSearchServiceProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupViewControllerConfigurerSpec)

describe(@"LineupViewControllerConfigurer", ^{
    __block LineupViewControllerConfigurer *configurer;
    __block LineupStore *lineupStore;
    __block PhotoAssetImporter *photoAssetImporter;
    __block AnalyticsTracker *analyticsTracker;
    __block id<LineupViewControllerDelegate> delegate;
    __block LineupViewController *lineupViewController;

    beforeEach(^{
        lineupStore = fake_for([LineupStore class]);
        photoAssetImporter = fake_for([PhotoAssetImporter class]);
        analyticsTracker = fake_for([AnalyticsTracker class]);
        delegate = fake_for(@protocol(LineupViewControllerDelegate));
        lineupViewController = fake_for([LineupViewController class]);
        lineupViewController stub_method(@selector(configureWithLineupStore:lineup:photoAssetImporter:suspectSearchSplitViewControllerProvider:perpetratorDescriptionViewControllerProvider:suspectPortrayalsViewControllerProvider:personSearchServiceProvider:delegate:));

        configurer = [[LineupViewControllerConfigurer alloc] initWithLineupStore:lineupStore
                                                              photoAssetImporter:photoAssetImporter
                                                                        delegate:delegate];
    });

    describe(@"configuring a lineup view controller for lineup creation", ^{
        beforeEach(^{
            [configurer configureLineupViewControllerForLineupCreation:lineupViewController];
        });

        it(@"should configure the lineup view controller with its static dependencies and no lineup", ^{
            lineupViewController should have_received(@selector(configureWithLineupStore:lineup:photoAssetImporter:suspectSearchSplitViewControllerProvider:perpetratorDescriptionViewControllerProvider:suspectPortrayalsViewControllerProvider:personSearchServiceProvider:delegate:)).with(lineupStore,
                                                                                                                                    nil,
                                                                                                                                    photoAssetImporter,
                                                                                                                                    Arguments::any([SuspectSearchSplitViewControllerProvider class]),
                                                                                                                                    Arguments::any([PerpetratorDescriptionViewControllerProvider class]),
                                                                                                                                    Arguments::any([SuspectPortrayalsViewControllerProvider class]),
                                                                                                                                    Arguments::any([PersonSearchServiceProvider class]),
                                                                                                                                    delegate);
        });
    });

    describe(@"configuring a lineup view controller for editing a lineup", ^{
        __block Lineup *lineup;
        beforeEach(^{
            lineup = fake_for([Lineup class]);
            [configurer configureLineupViewController:lineupViewController forEditingLineup:lineup];
        });

        it(@"should configure the lineup view controller with its static dependencies and the lineup to be edited", ^{
            lineupViewController should have_received(@selector(configureWithLineupStore:lineup:photoAssetImporter:suspectSearchSplitViewControllerProvider:perpetratorDescriptionViewControllerProvider:suspectPortrayalsViewControllerProvider:personSearchServiceProvider:delegate:)).with(lineupStore,
                                                                                                                                    lineup,
                                                                                                                                    photoAssetImporter,
                                                                                                                                    Arguments::any([SuspectSearchSplitViewControllerProvider class]),
                                                                                                                                    Arguments::any([PerpetratorDescriptionViewControllerProvider class]),
                                                                                                                                    Arguments::any([SuspectPortrayalsViewControllerProvider class]),
                                                                                                                                    Arguments::any([PersonSearchServiceProvider class]),
                                                                                                                                    delegate);
        });
    });
});

SPEC_END
