#import <Foundation/Foundation.h>

@class AudioLevelIndicatorView, AudioLevelMeter;

@interface PromptToSpeakViewController : UIViewController
@property (strong, nonatomic, readonly) AudioLevelMeter *audioLevelMeter;
@property (weak, nonatomic, readonly) AudioLevelIndicatorView *audioLevelIndicatorViewEnabled;
@property (weak, nonatomic, readonly) AudioLevelIndicatorView *audioLevelIndicatorViewDisabled;
@property (weak, nonatomic, readonly) UILabel *speakNowLabelEnabled;
@property (weak, nonatomic, readonly) UILabel *speakNowLabelDisabled;
@property (weak, nonatomic, readonly) UIImageView *speakNowEnabledImageView;

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter;
@end