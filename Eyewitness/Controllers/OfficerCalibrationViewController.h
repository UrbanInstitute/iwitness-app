#import "AVPreviewViewController.h"

@class RecordingTimeAvailableCalculator;
@class AudioLevelMeter;
@protocol OfficerCalibrationViewControllerDelegate;

@interface OfficerCalibrationViewController : AVPreviewViewController
- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter audioSession:(AVAudioSession *)audioSession delegate:(id <OfficerCalibrationViewControllerDelegate>)delegate;
@end
