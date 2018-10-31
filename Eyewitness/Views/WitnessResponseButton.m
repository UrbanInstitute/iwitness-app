#import "WitnessResponseButton.h"
#import "EyewitnessTheme.h"

static const float kRatioOfRightPaddingToImageMaxX = 3.f / 8.f;

@interface WitnessResponseButton ()
@property(nonatomic, strong) UIImageView *glyphImageView;
@end

@implementation WitnessResponseButton

- (id)init {
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setUp];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self setTitleColor:self.tintColor forState:UIControlStateNormal];
    [self setTitleColor:self.tintColor forState:UIControlStateHighlighted];
    [self updateBackgroundAndBorderColors];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    [self updateBackgroundAndBorderColors];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self updateBackgroundAndBorderColors];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateBackgroundAndBorderColors];
}

- (void)setImage:(UIImage *)image {
    self.glyphImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (self.glyphImageView.image) {
        self.titleEdgeInsets = UIEdgeInsetsMake(0.f, CGRectGetMaxX(self.glyphImageView.frame), 0.f, kRatioOfRightPaddingToImageMaxX * CGRectGetMaxX(self.glyphImageView.frame));
    } else {
        self.titleEdgeInsets = UIEdgeInsetsZero;
    }
}

#pragma mark - private

- (void)updateBackgroundAndBorderColors {
    if (self.enabled) {
        if (self.selected) {
            self.backgroundColor = self.tintColor;
            self.glyphImageView.tintColor = UIColor.whiteColor;
        } else if (self.highlighted) {
            self.backgroundColor = [self.tintColor colorWithAlphaComponent:0.25f];
            self.glyphImageView.tintColor = self.tintColor;
        } else {
            self.backgroundColor = UIColor.whiteColor;
            self.glyphImageView.tintColor = self.tintColor;
        }
        self.layer.borderColor = self.tintColor.CGColor;
    } else {
        self.backgroundColor = EyewitnessTheme.lightGrayColor;
        self.glyphImageView.tintColor = EyewitnessTheme.darkGrayColor;
        self.layer.borderColor = EyewitnessTheme.lightGrayColor.CGColor;
    }
}

- (void)setUp {
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 4.0f;
    self.titleLabel.font = EyewitnessTheme.buttonTextFont;
    self.glyphImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 46, 46)];
        [self addSubview:imageView];
        imageView;
    });
    [self setTitleColor:EyewitnessTheme.darkGrayColor forState:UIControlStateDisabled];
    [self setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    [self setTitleColor:UIColor.whiteColor forState:UIControlStateSelected | UIControlStateHighlighted];

    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.minimumScaleFactor = FLT_MIN;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

@end
