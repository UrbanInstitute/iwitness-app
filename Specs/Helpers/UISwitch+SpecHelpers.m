#import "UISwitch+SpecHelpers.h"

@implementation UISwitch (SpecHelpers)

- (void)toggle {
    self.on = !self.on;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
