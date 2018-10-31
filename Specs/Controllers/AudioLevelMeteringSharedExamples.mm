#import "AudioLevelMeter.h"
#import "AudioLevelIndicatorView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SHARED_EXAMPLE_GROUPS_BEGIN(AudioLevelMetering)

sharedExamplesFor(@"audio level metering", ^(NSDictionary *sharedContext) {
    __block UIViewController *controller;
    __block AudioLevelMeter *audioLevelMeter;
    __block AudioLevelIndicatorView *audioLevelIndicatorView;

    beforeEach(^{
        controller = sharedContext[@"controller"];
        audioLevelMeter = sharedContext[@"audioLevelMeter"];
        audioLevelIndicatorView = sharedContext[@"audioLevelIndicatorView"];
        [controller viewDidAppear:NO];
    });

    describe(@"when the view is about to disappear", ^{
        beforeEach(^{
            [controller viewWillDisappear:NO];
        });

        it(@"should not stop metering (PresentationFlowVC must do this)", ^{
            audioLevelMeter should_not have_received(@selector(stopMetering));
        });
    });

    it(@"should not start metering (PresentationFlowVC must do this)", ^{
        audioLevelMeter should_not have_received(@selector(startMetering));
    });

    it(@"should continuously pass the current average power level and peak hold level to the audio level indicator view", ^{
        [audioLevelMeter willChangeValueForKey:@"averagePowerLevel"];
        [audioLevelMeter willChangeValueForKey:@"peakHoldLevel"];

        __block CGFloat averagePowerLevel = 0.5;
        audioLevelMeter stub_method(@selector(averagePowerLevel)).and_do_block(^CGFloat{
            return averagePowerLevel;
        });

        __block CGFloat peakHoldLevel = 0.5;
        audioLevelMeter stub_method(@selector(peakHoldLevel)).and_do_block(^CGFloat{
            return peakHoldLevel;
        });

        [audioLevelMeter didChangeValueForKey:@"peakHoldLevel"];
        [audioLevelMeter didChangeValueForKey:@"averagePowerLevel"];

        audioLevelIndicatorView.averagePowerLevel should equal(0.5f);
        audioLevelIndicatorView.peakHoldLevel should equal(0.5f);

        [audioLevelMeter willChangeValueForKey:@"averagePowerLevel"];
        [audioLevelMeter willChangeValueForKey:@"peakHoldLevel"];
        averagePowerLevel = 0.2;
        peakHoldLevel = 0.4;
        [audioLevelMeter didChangeValueForKey:@"peakHoldLevel"];
        [audioLevelMeter didChangeValueForKey:@"averagePowerLevel"];

        audioLevelIndicatorView.averagePowerLevel should equal(0.2f);
        audioLevelIndicatorView.peakHoldLevel should equal(0.4f);
    });
});


SHARED_EXAMPLE_GROUPS_END
