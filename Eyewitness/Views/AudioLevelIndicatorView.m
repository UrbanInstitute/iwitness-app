#import "AudioLevelIndicatorView.h"
#import "EyewitnessTheme.h"

@interface AudioLevelIndicatorView ()
@property (nonatomic, weak) IBOutlet UIView *meterContainer;
@property (nonatomic, weak) IBOutlet UIView *nubView;
@property (nonatomic, strong) CALayer *meterLayer;
@end

@implementation AudioLevelIndicatorView

- (void)awakeFromNib {
    self.accessibilityLabel = @"AudioLevelIndicator";

    self.meterLayer = [[CALayer alloc] init];
    self.meterLayer.backgroundColor = self.meterContainer.backgroundColor.CGColor;

    [self.meterContainer.layer addSublayer:self.meterLayer];
    self.meterContainer.backgroundColor = [UIColor clearColor];
}

- (void)setAveragePowerLevel:(CGFloat)averagePowerLevel {
    _averagePowerLevel = MIN(MAX(averagePowerLevel, 0.0f), 1.0f);
    self.meterLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.meterContainer.bounds) * self.averagePowerLevel, CGRectGetHeight(self.meterContainer.bounds));
}

- (void)setPeakHoldLevel:(CGFloat)peakHoldLevel {
    _peakHoldLevel = MIN(MAX(peakHoldLevel, 0.0f), 1.0f);

    CGFloat nextHorizontalPosition = self.peakHoldLevel * CGRectGetWidth(self.meterContainer.bounds);
    BOOL holdLevelIsFalling = (nextHorizontalPosition < self.nubView.layer.position.x);

    if (holdLevelIsFalling) {
        [UIView animateWithDuration:0.1 animations:^{
            self.nubView.layer.position = CGPointMake(nextHorizontalPosition, self.nubView.layer.position.y);
        }];
    } else {
        self.nubView.layer.position = CGPointMake(nextHorizontalPosition, self.nubView.layer.position.y);
    }
}

@end
