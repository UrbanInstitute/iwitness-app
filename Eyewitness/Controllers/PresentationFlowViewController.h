#import "WitnessInstructionsViewController.h"
#import "PresentationCompleteViewController.h"
#import "PresentationCompleteViewControllerDelegate.h"
#import "PreparationViewControllerDelegate.h"

@class Presentation, PresentationStore, PresentationRecorder, AudioLevelMeter, PasswordValidator, KioskModeService, VideoPreviewView;

@protocol PresentationFlowViewControllerDelegate;

@interface PresentationFlowViewController : UINavigationController <WitnessInstructionsViewControllerDelegate, PresentationCompleteViewControllerDelegate, PreparationViewControllerDelegate>

@property (nonatomic, readonly) Presentation *presentation;
@property (strong, nonatomic, readonly) UIView *modalSpinnerContainer;
@property (nonatomic, weak) IBOutlet UIGestureRecognizer *twoFingerUpwardSwipeRecognizer;

- (void)configureWithPresentation:(Presentation *)presentation
             presentationRecorder:(PresentationRecorder *)presentationRecorder
                passwordValidator:(PasswordValidator *)passwordValidator
                 videoPreviewView:(VideoPreviewView *)videoPreviewView
                   captureSession:(AVCaptureSession *)captureSession
                  audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
                 kioskModeService:(KioskModeService *)kioskModeService
                     audioSession:(AVAudioSession *)audioSession
                     flowDelegate:(id<PresentationFlowViewControllerDelegate>)delegate;
@end
