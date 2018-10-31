#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class WitnessInstructionsViewController, ScreenCaptureService, PlayerView, SubtitlesView, PixelBufferView;

@protocol WitnessInstructionsViewControllerDelegate <NSObject>

- (void)witnessInstructionsViewControllerStartedPlayback:(WitnessInstructionsViewController *)viewController;
- (void)witnessInstructionsViewControllerStoppedPlayback:(WitnessInstructionsViewController *)viewController;

@end

@interface WitnessInstructionsViewController : UIViewController

@property (weak, nonatomic, readonly) UIButton *replayInstructionsButton;
@property (weak, nonatomic, readonly) UIButton *confirmInstructionsButton;
@property (weak, nonatomic, readonly) UIView *moviePlayerContainer;
@property (weak, nonatomic, readonly) PixelBufferView *moviePixelBufferView;
@property (weak, nonatomic, readonly) PlayerView *playerView;
@property (weak, nonatomic, readonly) UILabel *confirmationPromptLabel;
@property (weak, nonatomic, readonly) SubtitlesView *subtitlesView;

- (void)configureWithDelegate:(id <WitnessInstructionsViewControllerDelegate>)delegate
         screenCaptureService:(ScreenCaptureService *)screenCaptureService
                     avPlayer:(AVPlayer *)avPlayer;
@end
