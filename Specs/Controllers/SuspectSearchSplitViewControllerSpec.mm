#import "SuspectSearchSplitViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectSearchSplitViewControllerSpec)

describe(@"SuspectSearchSplitViewController", ^{
    __block SuspectSearchSplitViewController *controller;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectSearchSplitViewController"];
        controller.view should_not be_nil;
    });

    it(@"should set its children view controllers", ^{
        controller.searchViewController should_not be_nil;
        controller.resultsViewController should_not be_nil;
    });
});

SPEC_END
