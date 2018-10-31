#import "PresentationFlowViewController.h"
#import "OfficerCalibrationViewController.h"
#import "AudioLevelMeter.h"
#import "ScreenCaptureService.h"
#import "PhotoIDViewController.h"
#import "Presentation.h"
#import "PresentationRecorder.h"
#import "RecordingTimeAvailableCalculatorProvider.h"
#import "PresentationFlowViewControllerDelegate.h"
#import "PasswordValidator.h"
#import "AlertView.h"
#import "AudioPlayerService.h"
#import "KioskModeService.h"
#import "AnalyticsTracker.h"
#import "VideoPreviewView.h"
#import "PreparationViewController.h"
#import "AudioWarningViewController.h"
#import "Lineup.h"

@interface PresentationFlowViewController ()
@property (nonatomic, strong) Presentation *presentation;
@property (nonatomic, weak) id<PresentationFlowViewControllerDelegate> flowDelegate;
@property (nonatomic, strong) KioskModeService *kioskModeService;
@property (nonatomic, strong) PresentationRecorder *recorder;
@property (nonatomic, strong) PasswordValidator *passwordValidator;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic) BOOL hasStartedRecording;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AudioLevelMeter *audioLevelMeter;
@property (nonatomic, strong) VideoPreviewView *videoPreviewView;
@property (nonatomic) BOOL endingCaptureSession;
@property (strong, nonatomic) IBOutlet UIView *modalSpinnerContainer;
@end

@implementation PresentationFlowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
/* MOK removes
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerUpwardSwipeRecognized:)];
#ifndef FRANKIFIED
    recognizer.numberOfTouchesRequired = 2;
#endif
    recognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:recognizer];
    self.twoFingerUpwardSwipeRecognizer = recognizer;
 */
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configureTopViewController:self.topViewController];
    [self.kioskModeService enableKioskMode];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self endCaptureSessionWithCompletion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.kioskModeService disableKioskMode];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)configureWithPresentation:(Presentation *)presentation
             presentationRecorder:(PresentationRecorder *)presentationRecorder
                passwordValidator:(PasswordValidator *)passwordValidator
                 videoPreviewView:(VideoPreviewView *)videoPreviewView
                   captureSession:(AVCaptureSession *)captureSession
                  audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
                 kioskModeService:(KioskModeService *)kioskModeService
                     audioSession:(AVAudioSession *)audioSession
                     flowDelegate:(id<PresentationFlowViewControllerDelegate>)delegate {
    self.presentation = presentation;
    self.recorder = presentationRecorder;
    self.passwordValidator = passwordValidator;
    self.videoPreviewView = videoPreviewView;
    self.captureSession = captureSession;
    self.audioLevelMeter = audioLevelMeter;
    self.kioskModeService = kioskModeService;
    self.audioSession = audioSession;
    self.flowDelegate = delegate;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    [self configureTopViewController:viewController];
}

#pragma mark - Gesture Handlers
/* MOK REMOVES
- (IBAction)twoFingerUpwardSwipeRecognized:(UIGestureRecognizer *)recognizer {
    if (self.hasStartedRecording) {
        __block __weak UITextField *passwordField;
        AlertView *alert = [[AlertView alloc] initWithTitle:NSLocalizedString(@"OFFICER: Enter the word \"officer\" (case sensitive) to end the Presentation", nil)
                                                    message:nil
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                          otherButtonTitles:@[NSLocalizedString(@"Exit", nil)]
                                              cancelHandler:nil
                                        confirmationHandler:^(NSInteger otherButtonIndex) {
                                            if ([self.passwordValidator isValidPassword:passwordField.text]) {
                                                [self finishPresentation];
                                            } else {
                                                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Incorrect Password", nil)
                                                                            message:nil
                                                                           delegate:nil
                                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                  otherButtonTitles:nil] show];
                                            }
                                        }];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        passwordField = [alert textFieldAtIndex:0];
        [alert show];
    }
}
*/
#pragma mark - <PreparationViewControllerDelegate>

- (void)preparationViewControllerDidPresentOfficerIdentification:(PreparationViewController *)controller {
    [[AnalyticsTracker sharedInstance] trackPresentationStarted];
    [self.recorder startRecordingWithStartTime:CACurrentMediaTime()];
    self.hasStartedRecording = YES;
}

- (void)preparationViewControllerWillHideVideoPreview:(PreparationViewController *)controller {
    [self.recorder recordVideoPreviewEndTime:CACurrentMediaTime()];
}

#pragma mark - <WitnessInstructionsViewControllerDelegate>

- (void)witnessInstructionsViewControllerStartedPlayback:(WitnessInstructionsViewController *)viewController {
    [self.recorder recordInstructionsPlaybackStartTime:CACurrentMediaTime()];
}

- (void)witnessInstructionsViewControllerStoppedPlayback:(WitnessInstructionsViewController *)viewController {
    [self.recorder recordInstructionsPlaybackEndTime:CACurrentMediaTime()];
}

#pragma mark - <PresentationCompleteViewControllerDelegate>

- (void)presentationCompleteViewControllerDidFinish:(PresentationCompleteViewController *)controller {
    [self finishPresentation];
}

#pragma mark - private

- (void)finishPresentation {
    [self showModalSpinner];

    void(^endCaptureSessionAndNotifyDelegate)() = ^{
        [self endCaptureSessionWithCompletion:^{
            [self.flowDelegate presentationFlowViewControllerDidFinish:self];
        }];
    };

    [[self.recorder stopRecording] then:^id(id value) {
        endCaptureSessionAndNotifyDelegate();
        return nil;
    } error:^id(NSError *error) {
        endCaptureSessionAndNotifyDelegate();
        return nil;
    }];
    [self.audioLevelMeter stopMetering];

    [[AnalyticsTracker sharedInstance] trackPresentationCompleted];
}

- (void)showModalSpinner {
    self.modalSpinnerContainer.frame = self.view.bounds;
    [self.view addSubview:self.modalSpinnerContainer];
}

- (void)endCaptureSessionWithCompletion:(void(^)())completionBlock {
    if(self.captureSession.isRunning && !self.endingCaptureSession) {
        self.endingCaptureSession = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (AVCaptureOutput *output in self.captureSession.outputs) {
                [self.captureSession removeOutput:output];
            }
            for (AVCaptureInput *input in self.captureSession.inputs) {
                [self.captureSession removeInput:input];
            }
            [self.captureSession stopRunning];
            [self.audioSession setActive:NO withOptions:0 error:NULL];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.endingCaptureSession = NO;
                if (completionBlock) {
                    completionBlock();
                }
            });
        });
    }
}

- (void)configureTopViewController:(UIViewController *)topViewController {
    if ([topViewController isKindOfClass:[AudioWarningViewController class]]) {
        [(AudioWarningViewController *) topViewController configureWithAudioSession:self.audioSession];
    } else if ([topViewController isKindOfClass:[PhotoIDViewController class]]) {
        [(PhotoIDViewController *) topViewController configureWithPresentation:self.presentation
                                                               audioLevelMeter:self.audioLevelMeter
                                                            audioPlayerService:[AudioPlayerService service]];
    } else if ([topViewController isKindOfClass:[PresentationCompleteViewController class]]) {
        [(PresentationCompleteViewController *) topViewController configureWithPasswordValidator:self.passwordValidator
                                                                                        delegate:self
                                                                              audioPlayerService:[AudioPlayerService service]];
    } else if ([topViewController isKindOfClass:[WitnessInstructionsViewController class]]) {
        [(WitnessInstructionsViewController *) topViewController configureWithDelegate:self
                                                                  screenCaptureService:[[ScreenCaptureService alloc] init]
                                                                              avPlayer:[[AVPlayer alloc] initWithURL:[WitnessLocalization URLForInstructionalVideo]]];
    } else if ([topViewController isKindOfClass:[PreparationViewController class]]) {
        [self.audioLevelMeter startMetering];

        PreparationViewController *preparationViewController = (PreparationViewController *) topViewController;

        RecordingTimeAvailableCalculatorProvider *recordingTimeAvailableCalculatorProvider = [[RecordingTimeAvailableCalculatorProvider alloc] initWithScreenCaptureService:[[ScreenCaptureService alloc] init]];

        [preparationViewController configureWithCaseID:self.presentation.lineup.caseID
                                      videoPreviewView:self.presentation.lineup.audioOnly ? nil : self.videoPreviewView
                                       audioLevelMeter:self.audioLevelMeter
                                          audioSession:self.audioSession
                                              delegate:self
                      recordingTimeAvailableCalculator:[recordingTimeAvailableCalculatorProvider recordingTimeAvailableCalculator]];
    }
}

@end
