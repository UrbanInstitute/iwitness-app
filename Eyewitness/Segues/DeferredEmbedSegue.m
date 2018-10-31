#import "DeferredEmbedSegue.h"
#import "EmbedContainer.h"

@implementation DeferredEmbedSegue

- (void)perform {
    [self cleanUpContainingViewController];

    [self.sourceViewController addChildViewController:self.destinationViewController];

    id<EmbedContainer> containingViewController = self.sourceViewController;
    [[self.destinationViewController view] setFrame:containingViewController.embedContainerView.bounds];

    [[containingViewController embedContainerView] addSubview:[self.destinationViewController view]];
    [self.destinationViewController didMoveToParentViewController:self.sourceViewController];
}

- (void)cleanUpContainingViewController {
    UIViewController<EmbedContainer> *containingViewController = self.sourceViewController;
    UIViewController *currentChildViewController = [containingViewController.childViewControllers firstObject];

    if (currentChildViewController) {
        [currentChildViewController willMoveToParentViewController:nil];
        [currentChildViewController.view removeFromSuperview];
        [currentChildViewController removeFromParentViewController];
    }
}

@end
