#import "UIApplication+SpecHelpers.h"

static UIBackgroundTaskIdentifier __backgroundTaskIdentifier;
static void(^__expirationHandler)();

@implementation UIApplication (SpecHelpers)

+ (void)showViewController:(UIViewController *)controller {
    UIApplication.sharedApplication.keyWindow.rootViewController = controller;
}

+ (void)redisplayViewController {
    static UIViewController *otherController;
    if(!otherController) {
        otherController = [[UIViewController alloc] init];
    }

    UIViewController *originalViewController = self.sharedApplication.keyWindow.rootViewController;
    [self showViewController:otherController];
    [self showViewController:originalViewController];
}

- (void)setBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier {
    __backgroundTaskIdentifier = backgroundTaskIdentifier;
}

- (void(^)())expirationHandler {
    return __expirationHandler;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithName:(NSString *)name expirationHandler:(void (^)())handler {
    return [self beginBackgroundTaskWithExpirationHandler:handler];
}

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    __expirationHandler = handler;
    return __backgroundTaskIdentifier;
}
#pragma clang diagnostic pop

@end