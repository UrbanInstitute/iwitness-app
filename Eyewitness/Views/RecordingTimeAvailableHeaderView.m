#import "RecordingTimeAvailableHeaderView.h"
#import "EyewitnessTheme.h"
#import "RecordingTimeAvailableFormatter.h"
#import "UIImage+SinglePixelImage.h"

@interface RecordingTimeAvailableHeaderView ()
@property (weak, nonatomic) UILabel *label;
@end

@implementation RecordingTimeAvailableHeaderView

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        self.bounds = CGRectMake(0, 0, 768, 30);

        UILabel *label = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [EyewitnessTheme tableDetailLabelFont];
        [self.contentView addSubview:label];
        self.label = label;

        CGFloat separatorHeight = 1.0f/[UIScreen mainScreen].scale;
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-separatorHeight, CGRectGetWidth(self.bounds), separatorHeight)];
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        separator.backgroundColor = [EyewitnessTheme darkGrayColor];
        [self addSubview:separator];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundView.backgroundColor = [UIColor clearColor];

    if (self.backgroundView && [self.backgroundView.subviews count]==0) {
        UIToolbar *backgroundToolbar = [[UIToolbar alloc] initWithFrame:CGRectInset(self.backgroundView.bounds, 0, -10)];
        backgroundToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.backgroundView addSubview:backgroundToolbar];
        self.backgroundView.clipsToBounds = YES;
    }
}

- (void)setAvailableMinutes:(NSUInteger)availableMinutes {
    _availableMinutes = availableMinutes;
    RecordingTimeAvailableFormatter *formatter = [[RecordingTimeAvailableFormatter alloc] init];
    self.label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ available on device", nil), [formatter stringFromTimeAvailable:availableMinutes*60]];
}

- (void)setTimeAvailableStatus:(RecordingTimeAvailableStatus)timeAvailableStatus {
    _timeAvailableStatus = timeAvailableStatus;
    if (timeAvailableStatus == RecordingTimeAvailableStatusWarning) {
        self.contentView.backgroundColor = [EyewitnessTheme warnColor];
        self.label.textColor = [UIColor whiteColor];
    } else {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.label.textColor = [EyewitnessTheme darkerGrayColor];
    }
}

@end
