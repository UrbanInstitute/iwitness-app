#import "DefaultTextField.h"
#import "UIImage+SinglePixelImage.h"

@implementation DefaultTextField

- (void)awakeFromNib {
    [super awakeFromNib];
    self.disabledBackground = [UIImage singlePixelImageWithColor:[UIColor clearColor]];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    [self setNeedsLayout];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset([super textRectForBounds:bounds], self.enabled ? 5 : 0, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

@end
