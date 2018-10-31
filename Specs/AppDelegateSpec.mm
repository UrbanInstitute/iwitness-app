#import "AppDelegate.h"
#import "LineupsViewController.h"
#import "PresentationsViewController.h"
#import "HomeViewController.h"
#import "StitchingRestarter.h"
#import "PresentationStore.h"
#import "RecordingTimeAvailableCalculator.h"
#import "StitchingQueue.h"
#import "PresentationFlowViewControllerProvider.h"
#import "LineupStore.h"
#import "LineupViewControllerConfigurer.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AppDelegateSpec)

describe(@"AppDelegate", ^{
    __block AppDelegate *delegate;
    __block HomeViewController *rootViewController;
    __block LineupsViewController *lineupsViewController;
    __block PresentationsViewController *presentationsViewController;

    beforeEach(^{
        delegate = [[AppDelegate alloc] init];
    });

    describe(@"when the application has launched", ^{
        beforeEach(^{
            [delegate application:nil willFinishLaunchingWithOptions:nil];

            rootViewController = (HomeViewController *)delegate.window.rootViewController;
            lineupsViewController = (LineupsViewController *)((UINavigationController *)rootViewController.viewControllers[0]).topViewController;
            presentationsViewController = (PresentationsViewController *)((UINavigationController *)rootViewController.viewControllers[1]).topViewController;
            spy_on(lineupsViewController);
            spy_on(presentationsViewController);
            spy_on(delegate.stitchingRestarter);

            [delegate application:nil didFinishLaunchingWithOptions:nil];
        });

        it(@"should display a tab bar controller with two tabs", ^{
            rootViewController should be_instance_of([HomeViewController class]);
            rootViewController.viewControllers.count should equal(2);
        });

        it(@"should have a lineups tab", ^{
            lineupsViewController should be_instance_of([LineupsViewController class]);
        });

        it(@"should configure the lineups view controller", ^{
            lineupsViewController should have_received(@selector(configureWithPresentationFlowViewControllerProvider:lineupStore:presentationStore:recordingTimeAvailableCalculator:lineupViewControllerConfigurer:)).with(Arguments::any([PresentationFlowViewControllerProvider class]), Arguments::any([LineupStore class]), Arguments::any([PresentationStore class]), Arguments::any([RecordingTimeAvailableCalculator class]), Arguments::any([LineupViewControllerConfigurer class]));
        });

        it(@"should should configure the shared audio session", ^{
            [[AVAudioSession sharedInstance] category] should equal(AVAudioSessionCategoryPlayAndRecord);
        });

        it(@"should have a presentations tab", ^{
            presentationsViewController should be_instance_of([PresentationsViewController class]);
        });

        it(@"should restart incomplete stitching operations", ^{
            delegate.stitchingRestarter should have_received(@selector(restartIncompleteStitches));
        });

        it(@"should configure the presentations view controller", ^{
            presentationsViewController should have_received(@selector(configureWithPresentationStore:recordingTimeAvailableCalculator:stitchingQueue:)).with(Arguments::any([PresentationStore class]), Arguments::any([RecordingTimeAvailableCalculator class]), Arguments::any([StitchingQueue class]));
        });

        describe(@"when the application comes into the foreground", ^{
            beforeEach(^{
                [(id<CedarDouble>)delegate.stitchingRestarter reset_sent_messages];
                [delegate applicationWillEnterForeground:nil];
            });

            it(@"should restart incomplete stitching operations", ^{
                delegate.stitchingRestarter should have_received(@selector(restartIncompleteStitches));
            });
        });
    });
});

SPEC_END
