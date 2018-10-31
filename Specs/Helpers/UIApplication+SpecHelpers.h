@interface UIApplication (SpecHelpers)
+ (void)showViewController:(UIViewController *)controller;
+ (void)redisplayViewController;
- (void)setBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier;
- (void(^)())expirationHandler;
@end