#import "PromptToSpeakViewController.h"
#import "AudioLevelMeter.h"
#import "AudioLevelIndicatorView.h"

@interface PromptToSpeakViewController ()
@property (strong, nonatomic, readwrite) AudioLevelMeter *audioLevelMeter;
@property (weak, nonatomic, readwrite) IBOutlet AudioLevelIndicatorView *audioLevelIndicatorViewEnabled;
@property (weak, nonatomic, readwrite) IBOutlet AudioLevelIndicatorView *audioLevelIndicatorViewDisabled;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *speakNowLabelEnabled;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *speakNowLabelDisabled;
@property (weak, nonatomic, readwrite) IBOutlet UIImageView *speakNowEnabledImageView;
@end

@implementation PromptToSpeakViewController
- (void)dealloc {
    [self.audioLevelMeter removeObserver:self forKeyPath:@"averagePowerLevel" context:NULL];
    [self.audioLevelMeter removeObserver:self forKeyPath:@"peakHoldLevel" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.speakNowEnabledImageView.alpha = 0.0f;
    self.audioLevelIndicatorViewEnabled.alpha = 0.0f;
    self.speakNowLabelEnabled.alpha = 0.0f;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self localizeSpeakNowStrings];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.5f animations:^{
        self.speakNowEnabledImageView.alpha = 1.0f;
        self.speakNowLabelEnabled.alpha = 1.0f;
        self.audioLevelIndicatorViewEnabled.alpha = 1.0f;
    }];
}

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter {
    self.audioLevelMeter = audioLevelMeter;
    if (self.audioLevelMeter) {
        [self.audioLevelMeter addObserver:self forKeyPath:@"averagePowerLevel" options:0 context:NULL];
        [self.audioLevelMeter addObserver:self forKeyPath:@"peakHoldLevel" options:0 context:NULL];
    }
}

#pragma mark - Private

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"averagePowerLevel"]) {
        self.audioLevelIndicatorViewEnabled.averagePowerLevel = self.audioLevelMeter.averagePowerLevel;
        self.audioLevelIndicatorViewDisabled.averagePowerLevel = self.audioLevelMeter.averagePowerLevel;
    } else if ([keyPath isEqualToString:@"peakHoldLevel"]) {
        self.audioLevelIndicatorViewEnabled.peakHoldLevel = self.audioLevelMeter.peakHoldLevel;
        self.audioLevelIndicatorViewDisabled.peakHoldLevel = self.audioLevelMeter.peakHoldLevel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)localizeSpeakNowStrings {
    self.speakNowLabelEnabled.text = WitnessLocalizedString(@"SPEAK NOW", nil);
    self.speakNowLabelDisabled.text = WitnessLocalizedString(@"SPEAK NOW", nil);
}
@end