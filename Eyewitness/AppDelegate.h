#import <UIKit/UIKit.h>

@class StitchingRestarter;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) StitchingRestarter *stitchingRestarter;
@end
