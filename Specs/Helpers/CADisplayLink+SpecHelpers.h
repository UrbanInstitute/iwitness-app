#import <QuartzCore/QuartzCore.h>

@interface CADisplayLink (SpecHelpers)
+ (id)mostRecentTarget;
+ (SEL)mostRecentSelector;
+ (void)triggerMostRecentDisplayLink;
@end
