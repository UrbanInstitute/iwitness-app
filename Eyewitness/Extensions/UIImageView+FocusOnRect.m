#import "UIImageView+FocusOnRect.h"

@implementation UIImageView (FocusOnRect)

- (void)focusOnImageRect:(CGRect)focusRect {
    if (CGRectEqualToRect(focusRect, CGRectNull)) {
        [self focusOnCenter];
    } else {
        [self focusOnImageRect:focusRect animated:NO];
    }
}

#pragma mark - private

- (void)focusOnImageRect:(CGRect)focusRect animated:(BOOL)animated {
    if (!self.image) { return; }

    CGSize imageSize = self.image.size;
    CGFloat horizontalScale = CGRectGetWidth(self.bounds) / imageSize.width;
    CGFloat verticalScale = CGRectGetHeight(self.bounds) / imageSize.height;
    CGFloat scaleToUse = (horizontalScale<verticalScale) ? verticalScale : horizontalScale;
    CGSize scaledImageSize = CGSizeMake(imageSize.width*scaleToUse, imageSize.height*scaleToUse);

    CGSize unitRectSize = CGSizeMake(CGRectGetWidth(self.bounds)/scaledImageSize.width, CGRectGetHeight(self.bounds)/scaledImageSize.height);
    CGRect unitRectangle = { CGPointMake((1.0f-unitRectSize.width)/2, (1.0f-unitRectSize.height)/2), unitRectSize };

    CGPoint focusCenter = CGPointMake(CGRectGetMidX(focusRect), CGRectGetMidY(focusRect));
    CGPoint unitFocusCenter = CGPointMake(focusCenter.x/imageSize.width, focusCenter.y/imageSize.height);

    unitRectangle.origin = CGPointMake(unitFocusCenter.x-(CGRectGetWidth(unitRectangle)/2),
                                       unitFocusCenter.y-(CGRectGetHeight(unitRectangle)/2));
    unitRectangle = CGRectConstrainedToRect(unitRectangle, CGRectMake(0, 0, 1, 1));

    self.contentMode = UIViewContentModeScaleAspectFit;

    if (animated) {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"contentsRect"];
        anim.fromValue = [NSValue valueWithCGRect:self.layer.contentsRect];
        anim.duration = 0.2;
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        [self.layer addAnimation:anim forKey:@"contentsRect"];
    }

    self.layer.contentsRect = unitRectangle;
}

- (void)focusOnCenter {
    self.layer.contentsRect = CGRectMake(0, 0, 1, 1);
    self.contentMode = UIViewContentModeScaleAspectFill;
}

static CGRect CGRectConstrainedToRect(CGRect sourceRect, CGRect constrainingRect) {
    if (CGRectGetMinX(sourceRect) < CGRectGetMinX(constrainingRect)) {
        sourceRect.origin.x = CGRectGetMinX(constrainingRect);
    }
    if (CGRectGetMinY(sourceRect) < CGRectGetMinY(constrainingRect)) {
        sourceRect.origin.y = CGRectGetMinY(constrainingRect);
    }

    if (CGRectGetMaxX(sourceRect) > CGRectGetMaxX(constrainingRect)) {
        sourceRect.origin.x = CGRectGetMaxX(constrainingRect)-CGRectGetWidth(sourceRect);
    }
    if (CGRectGetMaxY(sourceRect) > CGRectGetMaxY(constrainingRect)) {
        sourceRect.origin.y = CGRectGetMaxY(constrainingRect)-CGRectGetHeight(sourceRect);
    }

    return sourceRect;
}

@end
