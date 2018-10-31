#import "CADisplayLink+SpecHelpers.h"

@implementation CADisplayLink (SpecHelpers)

static id mostRecentTarget__ = nil;
static SEL mostRecentSelector__ = NULL;

+ (void)afterEach {
    [self reset];
}

+ (id)mostRecentTarget {
    return mostRecentTarget__;
}
+ (SEL)mostRecentSelector {
    return mostRecentSelector__;
}

+ (void)reset {
    mostRecentTarget__ = nil;
    mostRecentSelector__ = NULL;
}

+ (void)triggerMostRecentDisplayLink {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [mostRecentTarget__ performSelector:mostRecentSelector__ withObject:nil];
#pragma clang diagnostic pop
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel {
    mostRecentTarget__ = target;
    mostRecentSelector__ = sel;
    return nil;
}
#pragma clang diagnostic pop

@end
