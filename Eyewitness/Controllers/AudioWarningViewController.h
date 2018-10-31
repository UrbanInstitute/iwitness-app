#import <UIKit/UIKit.h>

@interface AudioWarningViewController : UIViewController
@property(weak, nonatomic, readonly) UIButton *continueButton;
@property(weak, nonatomic, readonly) UIBarButtonItem *cancelButton;

- (void)configureWithAudioSession:(AVAudioSession *)audioSession;
@end
