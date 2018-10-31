#import "StitchingProgressIndicatorView.h"
#import <QuartzCore/QuartzCore.h>

@interface StitchingProgressIndicatorView ()
@property (nonatomic, strong) UIView *clearView;
@end

@implementation StitchingProgressIndicatorView

- (void)layoutSubviews {
    [super layoutSubviews];

    UIColor *grayColor = [UIColor colorWithWhite:199.0f/255.0f alpha:1.0];

    self.layer.cornerRadius = 4.0f;
    self.layer.borderColor = grayColor.CGColor;
    self.layer.borderWidth = 1.0f;
    self.clipsToBounds = YES;

    UIView *emptyView = [[UIView alloc] initWithFrame:self.bounds];
    [emptyView addSubview:[self labelWithBackgroundColor:[UIColor clearColor] textColor:grayColor]];

    CGRect clearViewFrame = CGRectMake(0, 0, 0, self.bounds.size.height);
    self.clearView = [[UIView alloc] initWithFrame:clearViewFrame];
    self.clearView.backgroundColor = [UIColor clearColor];
    self.clearView.clipsToBounds = YES;
    [emptyView addSubview:self.clearView];

    UIView *fullView = [[UIView alloc] initWithFrame:self.bounds];
    [fullView addSubview:[self labelWithBackgroundColor:grayColor textColor:[UIColor whiteColor]]];
    [self.clearView addSubview:fullView];

    [self addSubview:emptyView];
}

- (void)setProgress:(float)progress {
    _progress = progress;
    CGFloat progressWidth = progress * self.bounds.size.width;
    [UIView animateWithDuration:0.1 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear) animations:^{

        self.clearView.frame = CGRectMake(0, 0, progressWidth, self.bounds.size.height);
    } completion:NULL];
}

- (UILabel *)labelWithBackgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor {
    UILabel *label = [[UILabel alloc] init];
    label.frame = self.bounds;
    label.text = @"PROCESSING";
    label.font = [UIFont fontWithName:@"Avenir-Black" size:17.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = backgroundColor;
    label.textColor = textColor;
    return label;
}

@end
