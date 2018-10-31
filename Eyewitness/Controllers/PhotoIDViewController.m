#import "PhotoIDViewController.h"
#import "Presentation.h"
#import "QualifyIdentificationViewController.h"
#import "QualifyUncertaintyViewController.h"
#import "IdentificationCertaintyViewController.h"
#import "WitnessConfirmationViewController.h"
#import "WitnessResponseSelector.h"
#import "AudioLevelMeter.h"
#import "PhotoNumberLabel.h"
#import "AudioPlayerService.h"
#import "FBTweakInline.h"
#import "FeatureSwitches.h"

@interface PhotoIDViewController ()
@property (strong, nonatomic) Presentation *presentation;
@property (strong, nonatomic) AudioLevelMeter *audioLevelMeter;
@property (strong, nonatomic) AudioPlayerService *audioPlayerService;
@property (weak, nonatomic, readwrite) IBOutlet UIImageView *mugshotPhotoImageView;
@property (weak, nonatomic, readwrite) IBOutlet UIView *embedContainerView;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *recognitionPromptLabel;
@property (weak, nonatomic, readwrite) IBOutlet WitnessResponseSelector *responseSelector;
@property (weak, nonatomic, readwrite) IBOutlet PhotoNumberLabel *photoNumberLabel;

@end

@implementation PhotoIDViewController

- (void)configureWithPresentation:(Presentation *)presentation
                  audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
               audioPlayerService:(AudioPlayerService *)audioPlayerService {
    self.presentation = presentation;
    self.audioLevelMeter = audioLevelMeter;
    self.audioPlayerService = audioPlayerService;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photoNumberLabel.text = nil;
    self.responseSelector.allowNotSureResponse = [FeatureSwitches notSureResponseEnabled];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self localizeStrings];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.responseSelector.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.presentation) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"PhotoIDViewController must be configured with a presentation before loading the view"
                                     userInfo:nil];
    }
    [self performSegueWithIdentifier:@"embedPromptToSpeak" sender:self];
    [self updateDisplayForCurrentPhoto];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.destinationViewController isKindOfClass:[QualifyIdentificationViewController class]]) {
        [(QualifyIdentificationViewController *)segue.destinationViewController configureWithDelegate:self
                                                                                      audioLevelMeter:self.audioLevelMeter
                                                                                   audioPlayerService:[AudioPlayerService service]];
    } else if ([segue.destinationViewController isKindOfClass:[IdentificationCertaintyViewController class]]) {
        [(IdentificationCertaintyViewController *)segue.destinationViewController configureWithDelegate:self
                                                                                        audioLevelMeter:self.audioLevelMeter
                                                                                     audioPlayerService:[AudioPlayerService service]];
    } else if ([segue.destinationViewController isKindOfClass:[QualifyUncertaintyViewController class]]) {
        [(QualifyUncertaintyViewController *)segue.destinationViewController configureWithDelegate:self
                                                                                   audioLevelMeter:self.audioLevelMeter
                                                                                audioPlayerService:[AudioPlayerService service]];
    } else if ([segue.destinationViewController isKindOfClass:[PromptToSpeakViewController class]]) {
        [(PromptToSpeakViewController *) segue.destinationViewController configureWithAudioLevelMeter:self.audioLevelMeter];
    } else if ([segue.identifier isEqualToString:@"embedDenialConfirmation"]) {
        [(WitnessConfirmationViewController *)segue.destinationViewController configureForDenialWithDelegate:self audioLevelMeter:self.audioLevelMeter audioPlayerService:[AudioPlayerService service]];
    } else if ([segue.identifier isEqualToString:@"embedCertaintyConfirmation"]) {
        [(WitnessConfirmationViewController *)segue.destinationViewController configureForCertaintyWithDelegate:self audioLevelMeter:self.audioLevelMeter audioPlayerService:[AudioPlayerService service]];
    } else if ([segue.identifier isEqualToString:@"embedUncertaintyConfirmation"]) {
        [(WitnessConfirmationViewController *)segue.destinationViewController configureForUncertaintyWithDelegate:self audioLevelMeter:self.audioLevelMeter audioPlayerService:[AudioPlayerService service]];
    }
}

#pragma mark - Actions

- (IBAction)didSelectResponse:(WitnessResponseSelector *)sender {
    switch (sender.selectedResponse) {
        case WitnessResponseYes:
            [self performSegueWithIdentifier:@"embedIdentificationQualification" sender:self];
            break;
        case WitnessResponseNo:
            [self performSegueWithIdentifier:@"embedDenialConfirmation" sender:self];
            break;
        case WitnessResponseNotSure:
            [self performSegueWithIdentifier:@"embedUncertaintyQualification" sender:self];
            break;
        case WitnessResponseNone:
            break;
    }
}

- (void)showNextPhoto {
    if ([self.presentation advanceToNextPhoto]) {
        [self.responseSelector reset];
        [self updateDisplayForCurrentPhoto];
    } else {
        [self performSegueWithIdentifier:@"pushPresentationComplete" sender:self];
        self.mugshotPhotoImageView.image = nil;
        self.photoNumberLabel.text = nil;
    }
}

#pragma mark - <IdentificationCertaintyViewControllerDelegate>

- (void)identificationCertaintyViewControllerDidContinue:(IdentificationCertaintyViewController *)controller {
    [self performSegueWithIdentifier:@"embedCertaintyConfirmation" sender:self];
}

#pragma mark - <QualifyUncertaintyViewControllerDelegate>

- (void)qualifyUncertaintyViewControllerDidContinue:(QualifyUncertaintyViewController *)controller {
    [self performSegueWithIdentifier:@"embedUncertaintyConfirmation" sender:self];
}

#pragma mark - <QualifyIdentificationViewControllerDelegate>

- (void)qualifyIdentificationViewControllerDidContinue:(QualifyIdentificationViewController *)controller {
    [self performSegueWithIdentifier:@"embedIdentificationCertainty" sender:self];
}

#pragma mark - <WitnessConfirmationViewControllerDelegate>

- (void)witnessConfirmationViewControllerDidContinue:(WitnessConfirmationViewController *)controller {
    [self performSegueWithIdentifier:@"embedPromptToSpeak" sender:self];
    [self showNextPhoto];
}

#pragma mark - Unwind Segues

- (IBAction)unwindToPhotoIDViewController:(UIStoryboardSegue *)segue {
    [self.presentation rollBackToFirstPhoto];
    [self.responseSelector reset];
}

#pragma mark - Private

- (void)updateDisplayForCurrentPhoto {
    self.responseSelector.enabled = NO;
    [[self.audioPlayerService playSoundNamed:@"recognition_prompt"] then:^id(id value) {
        self.responseSelector.enabled = YES;
        return nil;
    } error:^id(NSError *error) {
        return nil;
    }];
    self.mugshotPhotoImageView.image = [UIImage imageWithContentsOfFile:[self.presentation.currentPhotoURL path]];
    self.photoNumberLabel.text = [@(self.presentation.currentPhotoIndex + 1) stringValue];
}

- (void)localizeStrings {
    self.recognitionPromptLabel.text = WitnessLocalizedString(@"Please state whether you recognize this person.", nil);
}

@end
