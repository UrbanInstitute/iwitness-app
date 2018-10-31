#import "WitnessConfirmationViewController.h"
#import "AudioLevelIndicatorView.h"
#import "AudioLevelMeter.h"
#import "AudioPlayerService.h"

typedef NS_ENUM(NSUInteger, ConfirmationType) {
    ConfirmationTypeDenial = 1,
    ConfirmationTypeUncertainty,
    ConfirmationTypeCertainty
};

@interface WitnessConfirmationViewController ()
@property (weak, nonatomic, readwrite) IBOutlet UILabel *denialConfirmationLabel;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *uncertaintyConfirmationLabel;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *certaintyConfirmationLabel;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *speakNowLabel;
@property (assign, nonatomic) ConfirmationType confirmationType;
@property (weak, nonatomic) id<WitnessConfirmationViewControllerDelegate> delegate;
@property (strong, nonatomic) AudioLevelMeter *audioLevelMeter;
@property (strong, nonatomic) AudioPlayerService *audioPlayerService;
@property (weak, nonatomic, readwrite) IBOutlet UIButton *continueButton;
@property (weak, nonatomic, readwrite) IBOutlet AudioLevelIndicatorView *audioLevelIndicatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *denialConfirmationLabelTopEdgeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uncertaintyConfirmationLabelTopEdgeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *certaintyConfirmationLabelTopEdgeConstraint;
@property (copy, nonatomic) NSString *audioPromptSoundName;
@end

@implementation WitnessConfirmationViewController

- (void)dealloc {
    [self.audioLevelMeter removeObserver:self forKeyPath:@"averagePowerLevel" context:NULL];
    [self.audioLevelMeter removeObserver:self forKeyPath:@"peakHoldLevel" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.continueButton.enabled = NO;
    self.denialConfirmationLabel.hidden = self.uncertaintyConfirmationLabel.hidden = self.certaintyConfirmationLabel.hidden = YES;
    CGFloat offscreenConstraintConstantValue = self.certaintyConfirmationLabel.superview.frame.size.height;
    switch (self.confirmationType) {
        case ConfirmationTypeCertainty:
            self.certaintyConfirmationLabel.hidden = NO;
            self.certaintyConfirmationLabelTopEdgeConstraint.constant = offscreenConstraintConstantValue;
            self.audioPromptSoundName = @"identification_continue";
            break;

        case ConfirmationTypeUncertainty:
            self.uncertaintyConfirmationLabel.hidden = NO;
            self.uncertaintyConfirmationLabelTopEdgeConstraint.constant = offscreenConstraintConstantValue;
            self.audioPromptSoundName = @"uncertainty_continue";
            break;

        case ConfirmationTypeDenial:
            self.denialConfirmationLabel.hidden = NO;
            self.denialConfirmationLabelTopEdgeConstraint.constant = offscreenConstraintConstantValue;
            self.continueButton.enabled = YES;
            self.audioPromptSoundName = @"denial_continue";
            break;

        default:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"WitnessConfirmationViewController must be configured for certainty, uncertainty or denial"
                                         userInfo:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self localizeStrings];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[self.audioPlayerService playSoundNamed:self.audioPromptSoundName] then:^id(id value) {
        self.continueButton.enabled = YES;
        return nil;
    } error:^id(NSError *error) { return nil; }];

    self.denialConfirmationLabelTopEdgeConstraint.constant = self.certaintyConfirmationLabelTopEdgeConstraint.constant = self.uncertaintyConfirmationLabelTopEdgeConstraint.constant = 5.f;
    [UIView animateWithDuration:0.5f animations:^{
        [self.denialConfirmationLabel layoutIfNeeded];
        [self.uncertaintyConfirmationLabel layoutIfNeeded];
        [self.certaintyConfirmationLabel layoutIfNeeded];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.audioPlayerService stopPlaying];
}

- (void)configureForCertaintyWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate audioLevelMeter:(AudioLevelMeter *)audioLevelMeter audioPlayerService:(AudioPlayerService *)audioPlayerService {
    self.confirmationType = ConfirmationTypeCertainty;
    [self configureWithDelegate:delegate
                audioLevelMeter:audioLevelMeter
             audioPlayerService:audioPlayerService];
}

- (void)configureForUncertaintyWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate audioLevelMeter:(AudioLevelMeter *)audioLevelMeter audioPlayerService:(AudioPlayerService *)audioPlayerService {
    self.confirmationType = ConfirmationTypeUncertainty;
    [self configureWithDelegate:delegate
                audioLevelMeter:audioLevelMeter
             audioPlayerService:audioPlayerService];
}

- (void)configureForDenialWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate audioLevelMeter:(AudioLevelMeter *)audioLevelMeter audioPlayerService:(AudioPlayerService *)audioPlayerService {
    self.confirmationType = ConfirmationTypeDenial;
    [self configureWithDelegate:delegate
                audioLevelMeter:audioLevelMeter
             audioPlayerService:audioPlayerService];
}

- (void)configureWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate audioLevelMeter:(AudioLevelMeter *)audioLevelMeter audioPlayerService:(AudioPlayerService *)audioPlayerService {
    self.delegate = delegate;
    self.audioPlayerService = audioPlayerService;
    self.audioLevelMeter = audioLevelMeter;
    if (self.audioLevelMeter) {
        [self.audioLevelMeter addObserver:self forKeyPath:@"averagePowerLevel" options:0 context:NULL];
        [self.audioLevelMeter addObserver:self forKeyPath:@"peakHoldLevel" options:0 context:NULL];
    }
}

- (IBAction)continueButtonTapped:(id)sender {
    self.continueButton.enabled = NO;
    self.denialConfirmationLabelTopEdgeConstraint.constant = self.certaintyConfirmationLabelTopEdgeConstraint.constant = self.uncertaintyConfirmationLabelTopEdgeConstraint.constant = -self.certaintyConfirmationLabel.superview.frame.size.height;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.denialConfirmationLabel layoutIfNeeded];
                         [self.uncertaintyConfirmationLabel layoutIfNeeded];
                         [self.certaintyConfirmationLabel layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         [self.delegate witnessConfirmationViewControllerDidContinue:self];
                     }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"averagePowerLevel"]) {
        self.audioLevelIndicatorView.averagePowerLevel = self.audioLevelMeter.averagePowerLevel;
    } else if ([keyPath isEqualToString:@"peakHoldLevel"]) {
        self.audioLevelIndicatorView.peakHoldLevel = self.audioLevelMeter.peakHoldLevel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Private

- (void)localizeStrings {
    self.denialConfirmationLabel.text = WitnessLocalizedString(@"You stated you do not recognize this person; tap “Continue →” to move to the next photo.", nil);
    self.uncertaintyConfirmationLabel.text = WitnessLocalizedString(@"You stated you are not sure if you recognize this person; tap “Continue →” to move to the next photo.", nil);
    self.certaintyConfirmationLabel.text = WitnessLocalizedString(@"The presentation will continue until you have reviewed all photos.", nil);
    self.speakNowLabel.text = WitnessLocalizedString(@"RECORDING", nil);
    [self.continueButton setTitle:WitnessLocalizedString(@"CONTINUE →", nil) forState:UIControlStateNormal];
}


@end
