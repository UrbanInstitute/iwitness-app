#import "WitnessConfirmationViewControllerDelegate.h"

@class AudioLevelMeter, AudioLevelIndicatorView, AudioPlayerService;

@interface WitnessConfirmationViewController : UIViewController

@property (weak, nonatomic, readonly) UILabel *denialConfirmationLabel;
@property (weak, nonatomic, readonly) UILabel *uncertaintyConfirmationLabel;
@property (weak, nonatomic, readonly) UILabel *certaintyConfirmationLabel;
@property (weak, nonatomic, readonly) UILabel *speakNowLabel;

@property (weak, nonatomic, readonly) AudioLevelIndicatorView *audioLevelIndicatorView;

@property (weak, nonatomic, readonly) UIButton *continueButton;

- (void)configureForCertaintyWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate
                          audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
                       audioPlayerService:(AudioPlayerService *)audioPlayerService;
- (void)configureForUncertaintyWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate
                            audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
                         audioPlayerService:(AudioPlayerService *)audioPlayerService;
- (void)configureForDenialWithDelegate:(id<WitnessConfirmationViewControllerDelegate>)delegate
                       audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
                    audioPlayerService:(AudioPlayerService *)audioPlayerService;

@end
