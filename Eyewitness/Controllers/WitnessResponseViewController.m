#import "WitnessResponseViewController.h"
#import "AudioLevelIndicatorView.h"
#import "AudioLevelMeter.h"
#import "AudioPlayerService.h"

@interface WitnessResponseViewController ()
@property (strong, nonatomic) AudioPlayerService *audioPlayerService;
@property (weak, nonatomic, readwrite) IBOutlet UIButton *continueButton;
@property (weak, nonatomic, readwrite) IBOutlet NSLayoutConstraint *witnessPromptTopEdgeConstraint;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *witnessPromptLabel;
@end

@implementation WitnessResponseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.continueButton.enabled = NO;
    self.witnessPromptTopEdgeConstraint.constant = self.witnessPromptLabel.superview.frame.size.height;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self localizeContinueButton];
    [self localizeStrings];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[self.audioPlayerService playSoundNamed:[self promptSoundName]] then:^id(id value) {
        self.continueButton.enabled = YES;
        return nil;
    } error:^id(NSError *error) { return nil; }];

    self.witnessPromptTopEdgeConstraint.constant = 5.f;

    [UIView animateWithDuration:0.5f animations:^{
        [self.witnessPromptLabel layoutIfNeeded];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.audioPlayerService stopPlaying];
}

- (void)configureWithDelegate:(id<WitnessResponseViewControllerDelegate>)delegate
              audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
           audioPlayerService:(AudioPlayerService *)audioPlayerService {
    [super configureWithAudioLevelMeter:audioLevelMeter];
    self.delegate = delegate;
    self.audioPlayerService = audioPlayerService;
}

- (IBAction)continueButtonTapped:(id)sender {
    self.continueButton.enabled = NO;
    self.witnessPromptTopEdgeConstraint.constant = -self.witnessPromptLabel.superview.frame.size.height;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.witnessPromptLabel layoutIfNeeded];
                         self.speakNowEnabledImageView.alpha = 0.0f;
                         self.speakNowLabelEnabled.alpha = 0.0f;
                         self.audioLevelIndicatorViewEnabled.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [self handleContinueButton];
                     }];
}

#pragma mark - Private
- (void)localizeContinueButton {
    [self.continueButton setTitle:WitnessLocalizedString(@"CONTINUE →", nil) forState:UIControlStateNormal];
}

- (void)handleContinueButton {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-handleContinueButton not implemented!"
                                 userInfo:nil];
}

- (NSString *)promptSoundName {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-promptSoundName not implemented!"
                                 userInfo:nil];
}

- (void)localizeStrings {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-localizeStrings not implemented!"
                                 userInfo:nil];
}

@end
