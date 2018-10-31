#import "SubtitlesView.h"
#import "EyewitnessTheme.h"

@implementation SubtitlesView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.text = nil;
    self.backgroundColor = [EyewitnessTheme grayColor];
    self.layer.cornerRadius = 20;
}

@end
