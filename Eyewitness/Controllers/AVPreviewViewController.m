#import "AudioLevelIndicatorView.h"
#import "AudioLevelMeter.h"
#import "AVPreviewViewController.h"

@interface AVPreviewViewController ()
@property (nonatomic, weak, readwrite) IBOutlet AudioLevelIndicatorView *audioLevelIndicatorView;
@property (nonatomic, weak, readwrite) IBOutlet UIButton *continueButton;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *directionsPromptLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *directionsPromptTopEdgeConstraint;
@property (nonatomic, strong) AudioLevelMeter *audioLevelMeter;
@end

@implementation AVPreviewViewController

- (void)dealloc {
    [self.audioLevelMeter removeObserver:self forKeyPath:@"averagePowerLevel" context:NULL];
    [self.audioLevelMeter removeObserver:self forKeyPath:@"peakHoldLevel" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.directionsPromptTopEdgeConstraint.constant = self.directionsPromptLabel.superview.frame.size.height;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.directionsPromptTopEdgeConstraint.constant = 5.f;
    [UIView animateWithDuration:0.5f animations:^{
        [self.directionsPromptLabel layoutIfNeeded];
    }];
}

- (IBAction)continueButtonTapped:(id)sender {
    self.continueButton.enabled = NO;
    self.directionsPromptTopEdgeConstraint.constant = -self.directionsPromptLabel.superview.frame.size.height;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.directionsPromptLabel layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self handleContinueButton];
                     }];
}

- (void)handleContinueButton {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-handleContinueButton not implemented!"
                                 userInfo:nil];
}

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter {
    self.audioLevelMeter = audioLevelMeter;
    if (self.audioLevelMeter) {
        [self.audioLevelMeter addObserver:self forKeyPath:@"averagePowerLevel" options:0 context:NULL];
        [self.audioLevelMeter addObserver:self forKeyPath:@"peakHoldLevel" options:0 context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"averagePowerLevel"]) {
        self.audioLevelIndicatorView.averagePowerLevel = self.audioLevelMeter.averagePowerLevel;
    } else if ([keyPath isEqualToString:@"peakHoldLevel"]) {
        self.audioLevelIndicatorView.peakHoldLevel = self.audioLevelMeter.peakHoldLevel;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
