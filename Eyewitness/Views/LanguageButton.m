#import "LanguageButton.h"
#import "EyewitnessTheme.h"

@implementation LanguageButton

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setUp];
}

- (void)setUp {
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 4.0f;
    self.backgroundColor = UIColor.whiteColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.minimumScaleFactor = FLT_MIN;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [EyewitnessTheme buttonTextFont];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    self.layer.borderColor = self.tintColor.CGColor;
}

@end
