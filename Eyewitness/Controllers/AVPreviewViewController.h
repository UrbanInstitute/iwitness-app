#import <Foundation/Foundation.h>

@class AudioLevelIndicatorView;
@class VideoPreviewView;
@class AudioLevelMeter;

@interface AVPreviewViewController : UIViewController
@property (nonatomic, weak, readonly) UIButton *continueButton;
@property (nonatomic, weak, readonly) AudioLevelIndicatorView *audioLevelIndicatorView;
@property (nonatomic, strong, readonly) AudioLevelMeter *audioLevelMeter;
@property (nonatomic, weak, readonly) UILabel *directionsPromptLabel;

- (void)handleContinueButton;
- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter;
@end
