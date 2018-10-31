@class PasswordValidator;
@class AudioPlayerService;

@protocol PresentationCompleteViewControllerDelegate;

@interface PresentationCompleteViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak, readonly) UIButton *proceedButton;
@property (nonatomic, weak, readonly) UIButton *replayButton;
@property (nonatomic, weak, readonly) UIButton *finishButton;
@property (nonatomic, weak, readonly) UITextField *officerPasswordTextField;

@property (nonatomic, weak, readonly) UILabel *presentationCompleteLabel;
@property (nonatomic, weak, readonly) UILabel *returnDeviceLabel;
@property (nonatomic, weak) IBOutlet UILabel *passwordIncorrectLabel;

- (void)configureWithPasswordValidator:(PasswordValidator *)passwordValidator delegate:(id<PresentationCompleteViewControllerDelegate>)delegate audioPlayerService:(AudioPlayerService *)audioPlayerService;

@end
