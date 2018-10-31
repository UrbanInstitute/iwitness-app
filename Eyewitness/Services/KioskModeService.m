#import "KioskModeService.h"

@implementation KioskModeService

- (KSPromise *)enableKioskMode {
    KSDeferred *deferred = [KSDeferred defer];
    UIAccessibilityRequestGuidedAccessSession(YES, ^(BOOL didSucceed) {
        if (didSucceed) {
            [deferred resolveWithValue:nil];
        } else {
            [deferred rejectWithError:nil];
        }
    });
    return deferred.promise;
}

- (KSPromise *)disableKioskMode {
    KSDeferred *deferred = [KSDeferred defer];
    UIAccessibilityRequestGuidedAccessSession(NO, ^(BOOL didSucceed) {
        if (didSucceed) {
            [deferred resolveWithValue:nil];
        } else {
            [deferred rejectWithError:nil];
        }
    });
    return deferred.promise;
}

@end
