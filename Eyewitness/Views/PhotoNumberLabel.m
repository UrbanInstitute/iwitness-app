#import "PhotoNumberLabel.h"

@implementation PhotoNumberLabel

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2.0f;
}

@end
