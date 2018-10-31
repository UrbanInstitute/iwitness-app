#import "DefaultButton.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(DefaultButtonSpec)

describe(@"DefaultButton", ^{
    __block DefaultButton *button;

    beforeEach(^{
        button = [[DefaultButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    describe(@"accepting touches when disabled", ^{
        beforeEach(^{
            button.enabled = NO;
        });

        it(@"should receive touches", ^{
            [button hitTest:CGPointMake(1, 1) withEvent:nil] should equal(button);
        });
    });
});

SPEC_END
