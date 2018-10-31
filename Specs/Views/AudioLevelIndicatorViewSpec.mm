#import "AudioLevelIndicatorView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AudioLevelIndicatorViewSpec)

describe(@"AudioLevelIndicatorView", ^{
    __block AudioLevelIndicatorView *view;

    beforeEach(^{
        view = [[AudioLevelIndicatorView alloc] init];
    });

    describe(@"should clip the values of the average power level", ^{
        it(@"should clip negative values to zero", ^{
            view.averagePowerLevel = -1.0f;
            view.averagePowerLevel should equal(0.0f);
        });

        it(@"should clip high values to one", ^{
            view.averagePowerLevel = 2.0f;
            view.averagePowerLevel should equal(1.0f);
        });
    });

    describe(@"should clip the values of the peak hold level", ^{
        it(@"should clip negative values to zero", ^{
            view.peakHoldLevel = -1.0f;
            view.peakHoldLevel should equal(0.0f);
        });

        it(@"should clip high values to one", ^{
            view.peakHoldLevel = 2.0f;
            view.peakHoldLevel should equal(1.0f);
        });
    });
});

SPEC_END
