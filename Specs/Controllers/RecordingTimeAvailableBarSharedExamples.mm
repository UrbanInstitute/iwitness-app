#import "RecordingTimeAvailableCalculator.h"
#import "EyewitnessTheme.h"
#import "RecordingTimeAvailableHeaderView.h"
using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SHARED_EXAMPLE_GROUPS_BEGIN(RecordingTimeAvailableBar)

sharedExamplesFor(@"show available recording time in the table header", ^(NSDictionary *sharedContext){
    __block UIViewController<UITableViewDelegate> *controller;
    __block UITableView *controllerTableView;
    __block RecordingTimeAvailableCalculator *timeAvailableCalculator;

    beforeEach(^{
        controller = sharedContext[@"controller"];
        controllerTableView = sharedContext[@"controllerTableView"];
        timeAvailableCalculator = sharedContext[@"timeAvailableCalculator"];
    });

    context(@"when the recording time available status is normal", ^{
        beforeEach(^{
            timeAvailableCalculator stub_method(@selector(recordingTimeAvailableStatus)).and_return(RecordingTimeAvailableStatusNormal);
            timeAvailableCalculator stub_method(@selector(calculateAvailableMinutesOfRecordingTime)).and_return((NSUInteger)123);

            controller.view should_not be_nil;
            [controller.view layoutIfNeeded];
        });

        it(@"should be shown in the top section header with normal styling", ^{
            RecordingTimeAvailableHeaderView *headerView = (RecordingTimeAvailableHeaderView *)[controllerTableView headerViewForSection:0];

            CGRectGetHeight(headerView.frame) should equal(30);
            headerView.contentView.subviews[0] should be_instance_of([UILabel class]);
            [headerView.contentView.subviews[0] text] should equal(@"More than an hour available on device");
            [headerView.contentView.subviews[0] textColor] should equal([EyewitnessTheme darkerGrayColor]);
            headerView.contentView.backgroundColor should equal([UIColor clearColor]);
        });
    });

    context(@"when the recording time available status is warning", ^{
        beforeEach(^{
            timeAvailableCalculator stub_method(@selector(recordingTimeAvailableStatus)).and_return(RecordingTimeAvailableStatusWarning);
            timeAvailableCalculator stub_method(@selector(calculateAvailableMinutesOfRecordingTime)).and_return((NSUInteger)17);

            controller.view should_not be_nil;
            [controller.view layoutIfNeeded];
        });

        it(@"should be shown in the top section header with warning styling", ^{
            RecordingTimeAvailableHeaderView *headerView = (RecordingTimeAvailableHeaderView *)[controllerTableView headerViewForSection:0];

            CGRectGetHeight(headerView.frame) should equal(30);
            headerView.contentView.subviews[0] should be_instance_of([UILabel class]);
            [headerView.contentView.subviews[0] text] should equal(@"17m available on device");
            [headerView.contentView.subviews[0] textColor] should equal([UIColor whiteColor]);
            headerView.contentView.backgroundColor should equal([EyewitnessTheme warnColor]);
        });
    });

    describe(@"updating the available recording time", ^{
        context(@"when the view appears", ^{
            beforeEach(^{
                [SpecHelper specHelper].sharedExampleContext[@"subjectAction"] = ^{
                    [controller viewWillAppear:NO];
                    [controller viewDidAppear:NO];
                };
            });

            itShouldBehaveLike(@"updating the available recording time in the table header");
        });

        context(@"when the app comes into the foreground", ^{
            beforeEach(^{
                [SpecHelper specHelper].sharedExampleContext[@"subjectAction"] = ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
                };
            });

            itShouldBehaveLike(@"updating the available recording time in the table header");
        });
    });
});

sharedExamplesFor(@"updating the available recording time in the table header", ^(NSDictionary *sharedContext) {
    __block UIViewController<UITableViewDelegate> *controller;
    __block UITableView *controllerTableView;
    __block RecordingTimeAvailableCalculator *timeAvailableCalculator;
    __block void (^subjectAction)(void);
    __block NSUInteger availableMinutes;

    beforeEach(^{
        controller = sharedContext[@"controller"];
        controllerTableView = sharedContext[@"controllerTableView"];
        timeAvailableCalculator = sharedContext[@"timeAvailableCalculator"];
        subjectAction = sharedContext[@"subjectAction"];

        availableMinutes = 123;
        timeAvailableCalculator stub_method(@selector(recordingTimeAvailableStatus)).and_return(RecordingTimeAvailableStatusNormal);
        timeAvailableCalculator stub_method(@selector(calculateAvailableMinutesOfRecordingTime)).and_do_block(^NSUInteger{
            return availableMinutes;
        });

        controller.view should_not be_nil;
        [controller.view layoutIfNeeded];
    });

    it(@"should update the recording time for more than an hour when the subject action has been carried out", ^{
        availableMinutes = 120;
        subjectAction();

        [controller.view layoutIfNeeded];
        RecordingTimeAvailableHeaderView *headerView = (RecordingTimeAvailableHeaderView *)[controllerTableView headerViewForSection:0];
        [headerView.contentView.subviews[0] text] should equal(@"More than an hour available on device");
    });

    it(@"should update the recording time for less than an hour when the subject action has been carried out", ^{
        availableMinutes = 59;
        subjectAction();

        [controller.view layoutIfNeeded];
        RecordingTimeAvailableHeaderView *headerView = (RecordingTimeAvailableHeaderView *)[controllerTableView headerViewForSection:0];
        [headerView.contentView.subviews[0] text] should equal(@"59m available on device");
    });
});

SHARED_EXAMPLE_GROUPS_END
