#import <UIKit/UIKit.h>
#import "EmbedContainer.h"
#import "WitnessConfirmationViewControllerDelegate.h"
#import "WitnessResponseViewControllerDelegate.h"

@class Presentation, PresentationFlowViewController, PhotoNumberLabel, AudioPlayerService, AudioLevelMeter, WitnessResponseSelector;

@interface PhotoIDViewController : UIViewController<EmbedContainer, WitnessResponseViewControllerDelegate, WitnessConfirmationViewControllerDelegate>

@property (weak, nonatomic, readonly) UIImageView *mugshotPhotoImageView;
@property (weak, nonatomic, readonly) UILabel *recognitionPromptLabel;
@property (weak, nonatomic, readonly) WitnessResponseSelector *responseSelector;
@property (weak, nonatomic, readonly) PhotoNumberLabel *photoNumberLabel;

- (void)configureWithPresentation:(Presentation *)presentation
                  audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
               audioPlayerService:(AudioPlayerService *)audioPlayerService;
- (IBAction)unwindToPhotoIDViewController:(UIStoryboardSegue *)segue;

@end
