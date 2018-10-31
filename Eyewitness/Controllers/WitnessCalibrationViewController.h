#import "AVPreviewViewController.h"

@protocol WitnessCalibrationViewControllerDelegate;
@class AudioLevelMeter;

@interface WitnessCalibrationViewController : AVPreviewViewController
@property (nonatomic, weak, readonly) UIButton *languageSelectionButton;

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter delegate:(id <WitnessCalibrationViewControllerDelegate>)delegate;
@end
