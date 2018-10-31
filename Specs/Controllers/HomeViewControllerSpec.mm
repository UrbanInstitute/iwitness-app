#import "HomeViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(HomeViewControllerSpec)

describe(@"HomeViewController", ^{
    __block HomeViewController *controller;

    beforeEach(^{
        controller = [[HomeViewController alloc] init];
    });

    it(@"should only support portrait upside-right orientation", ^{
        [controller supportedInterfaceOrientations] should equal(UIInterfaceOrientationMaskPortrait);
    });
});

SPEC_END
