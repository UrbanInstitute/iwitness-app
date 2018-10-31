#import "AVPreviewViewController.h"

@protocol OfficerIdentificationViewControllerDelegate;

@interface OfficerIdentificationViewController : AVPreviewViewController
- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter delegate:(id <OfficerIdentificationViewControllerDelegate>)delegate;
@end
