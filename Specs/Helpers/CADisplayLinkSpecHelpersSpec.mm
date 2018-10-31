#import "CADisplayLink+SpecHelpers.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CADisplayLinkSpecHelpersSpec)

describe(@"CADisplayLinkSpecHelpers", ^{
    __block id target;

    beforeEach(^{
        target = @[];
        spy_on(target);

        [CADisplayLink displayLinkWithTarget:target selector:@selector(count)];
    });

    describe(@"triggering the most recent display link", ^{
        beforeEach(^{
            [CADisplayLink triggerMostRecentDisplayLink];
        });

        it(@"should perform the selector on the target", ^{
            target should have_received(@selector(count));
        });
    });
});

SPEC_END
