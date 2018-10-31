#import <Foundation/Foundation.h>

@interface KioskModeService : NSObject

- (KSPromise *)enableKioskMode;
- (KSPromise *)disableKioskMode;

@end
