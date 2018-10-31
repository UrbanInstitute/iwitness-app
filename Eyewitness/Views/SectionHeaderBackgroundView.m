#import "SectionHeaderBackgroundView.h"
#import "EyewitnessTheme.h"

@implementation SectionHeaderBackgroundView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];

    UIImageView *roundedCornersBackground = [[UIImageView alloc] initWithFrame:self.bounds];
    roundedCornersBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    roundedCornersBackground.image = [self createBackgroundImage];
    [self insertSubview:roundedCornersBackground atIndex:0];
}

- (UIImage *)createBackgroundImage {
    CGSize imageSize = CGSizeMake(9, 5);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
    [[EyewitnessTheme lightGrayColor] set];

    UIBezierPath *roundedTopCornersPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){ CGPointZero, imageSize } byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight) cornerRadii:CGSizeMake(4, 4)];
    [roundedTopCornersPath fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 0, 4)];
}

@end
