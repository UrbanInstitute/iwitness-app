#import "DefaultButton.h"
#import "EyewitnessTheme.h"

@implementation DefaultButton

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];

    self.titleLabel.font = [EyewitnessTheme buttonTextFont];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.minimumScaleFactor = FLT_MIN;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;

    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:[EyewitnessTheme darkGrayColor] forState:UIControlStateDisabled];

    [self updateBackgroundImages];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event] && !self.hidden && self.alpha > 0.1f) {
        return self;
    }
    return [super hitTest:point withEvent:event];
}

- (void)updateBackgroundImages {
    switch (self.style) {
        case ButtonStylePrimary:
            [self setBackgroundImage:[self backgroundImageWithColor:[EyewitnessTheme primaryColor]] forState:UIControlStateNormal];
            [self setBackgroundImage:[self backgroundImageWithColor:[EyewitnessTheme primaryActiveColor]] forState:UIControlStateHighlighted];
            break;
        case ButtonStyleWarn:
            [self setBackgroundImage:[self backgroundImageWithColor:[EyewitnessTheme warnColor]] forState:UIControlStateNormal];
            [self setBackgroundImage:[self backgroundImageWithColor:[EyewitnessTheme warnActiveColor]] forState:UIControlStateHighlighted];
            break;
        default:
            break;
    }

    [self setBackgroundImage:[self backgroundImageWithColor:[EyewitnessTheme lightGrayColor]] forState:UIControlStateDisabled];
}

- (void)setStyle:(ButtonStyle)style {
    _style = style;
    [self updateBackgroundImages];
}

- (UIImage *)backgroundImageWithColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(9, 9), NO, [UIScreen mainScreen].scale);

    [color set];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 9, 9) cornerRadius:4] fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
}

@end
