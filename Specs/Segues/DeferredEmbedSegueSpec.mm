#import "DeferredEmbedSegue.h"
#import "EmbedContainer.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface EmbedContainerViewController : UIViewController<EmbedContainer> {
    UIView *_containerView;
}
@end
@implementation EmbedContainerViewController
- (UIView *)embedContainerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(50.f, 50.f, 320.f, 200.f)];
    }
    return _containerView;
}
@end

SPEC_BEGIN(DeferredEmbedSegueSpec)

describe(@"DeferredEmbedSegue", ^{
    __block DeferredEmbedSegue *segue;
    __block EmbedContainerViewController *containerViewController;
    __block UIViewController *destinationViewController;

    beforeEach(^{
        containerViewController = [[EmbedContainerViewController alloc] init];
        destinationViewController = [[UIViewController alloc] init];
        segue = [[DeferredEmbedSegue alloc] initWithIdentifier:@"embedNoConfirmation"
                                                             source:containerViewController
                                                        destination:destinationViewController];
    });

    context(@"when there is no child view controller that has been embedded", ^{
        describe(@"when the segue is performed", ^{
            beforeEach(^{
                [segue perform];
            });

            it(@"should make the destination view controller a child view controller of the container view controller", ^{
                containerViewController.childViewControllers should contain(destinationViewController);
            });

            it(@"should place the destination view controller in the container view controller's container view", ^{
                containerViewController.embedContainerView.subviews should contain(destinationViewController.view);
            });

            it(@"should size the destination view controller's view to fit the container view", ^{
                destinationViewController.view.frame should equal(containerViewController.embedContainerView.bounds);
            });
        });
    });

    context(@"when there is an existing child view controller embedded", ^{
        __block UIViewController *nextDestinationViewController;

        beforeEach(^{
            [segue perform];
            nextDestinationViewController = [[UIViewController alloc] init];
            segue = [[DeferredEmbedSegue alloc] initWithIdentifier:@"embedNoConfirmation"
                                                                 source:containerViewController
                                                            destination:nextDestinationViewController];
        });

        describe(@"when the segue is performed", ^{
            beforeEach(^{
                [segue perform];
            });

            it(@"should make the destination view controller a child view controller of the container view controller", ^{
                containerViewController.childViewControllers should contain(nextDestinationViewController);
            });

            it(@"should place the destination view controller in the container view controller's container view", ^{
                containerViewController.embedContainerView.subviews should contain(nextDestinationViewController.view);
            });

            it(@"should size the destination view controller's view to fit the container view", ^{
                nextDestinationViewController.view.frame should equal(containerViewController.embedContainerView.bounds);
            });

            it(@"should remove the previous child view controller", ^{
                containerViewController.childViewControllers should_not contain(destinationViewController);
            });

            it(@"should remove the previous child view controller's view", ^{
                containerViewController.embedContainerView.subviews should_not contain(destinationViewController.view);
            });
        });
    });
});

SPEC_END
