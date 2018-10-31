#import <UIKit/UIKit.h>
#import "WitnessResponseViewControllerDelegate.h"
#import "PromptToSpeakViewController.h"

@class AudioLevelMeter, AudioPlayerService, AudioLevelIndicatorView;

@protocol WitnessResponseViewControllerDelegate;

@interface WitnessResponseViewController : PromptToSpeakViewController

@property (weak, nonatomic, readonly) UIButton *continueButton;
@property (weak, nonatomic, readonly) UILabel *witnessPromptLabel;
@property (weak, nonatomic) id<WitnessResponseViewControllerDelegate> delegate;

- (void)configureWithDelegate:(id<WitnessResponseViewControllerDelegate>)delegate
              audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
           audioPlayerService:(AudioPlayerService *)audioPlayerService;

@end
