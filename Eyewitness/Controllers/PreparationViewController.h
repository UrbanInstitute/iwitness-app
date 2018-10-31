#import "AVPreviewViewController.h"
#import "OfficerCalibrationViewControllerDelegate.h"
#import "EmbedContainer.h"
#import "OfficerIdentificationViewControllerDelegate.h"
#import "WitnessCalibrationViewControllerDelegate.h"
#import "WitnessIdentificationViewControllerDelegate.h"

@class RecordingTimeAvailableCalculator, AudioLevelMeter;
@protocol PreparationViewControllerDelegate;

@interface PreparationViewController : UIViewController<EmbedContainer, OfficerCalibrationViewControllerDelegate, OfficerIdentificationViewControllerDelegate, WitnessCalibrationViewControllerDelegate, WitnessIdentificationViewControllerDelegate>

@property (nonatomic, weak, readonly) UILabel *availableTimeLabel;
@property (nonatomic, weak, readonly) UIView *availableTimeLabelContainer;
@property (nonatomic, weak, readonly) UIView *outerVideoPreviewContainerView;
@property (nonatomic, weak, readonly) UIBarButtonItem *cancelButton;
@property (nonatomic, weak, readonly) UIButton *startButton;
@property (nonatomic, weak, readonly) UIView *videoPreviewContainerView;

- (void)configureWithCaseID:(NSString *)caseID
           videoPreviewView:(VideoPreviewView *)videoPreviewView
            audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
               audioSession:(AVAudioSession *)audioSession
                   delegate:(id <PreparationViewControllerDelegate>)delegate
        recordingTimeAvailableCalculator:(RecordingTimeAvailableCalculator *)recordingTimeAvailableCalculator;

@end
