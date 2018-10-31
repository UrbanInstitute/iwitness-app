#import "PortraitOnlyNavigationController.h"

@interface PortraitOnlyNavigationController ()

@end

@implementation PortraitOnlyNavigationController

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
