#import "AVPreviewViewController.h"

@protocol WitnessIdentificationViewControllerDelegate;

@interface WitnessIdentificationViewController : AVPreviewViewController

@property (nonatomic, weak, readonly) UILabel *speakNowLabel;

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter delegate:(id<WitnessIdentificationViewControllerDelegate>)delegate;
@end
