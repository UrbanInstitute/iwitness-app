#import <QuartzCore/QuartzCore.h>
#import "GrayWell.h"
#import "EyewitnessTheme.h"

@implementation GrayWell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [EyewitnessTheme lightGrayColor];
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [EyewitnessTheme darkGrayColor].CGColor;
    self.layer.cornerRadius = 4.0f;
    self.layer.masksToBounds = YES;
}

@end
