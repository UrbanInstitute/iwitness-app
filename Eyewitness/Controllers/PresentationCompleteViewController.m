#import "PresentationCompleteViewController.h"
#import "PresentationCompleteViewControllerDelegate.h"
#import "PasswordValidator.h"
#import "AudioPlayerService.h"

@interface PresentationCompleteViewController ()
@property (nonatomic, strong) PasswordValidator *passwordValidator;
@property (nonatomic, weak) id<PresentationCompleteViewControllerDelegate> delegate;
@property (nonatomic, strong) AudioPlayerService *audioPlayerService;

@property (nonatomic, weak, readwrite) IBOutlet UILabel *presentationCompleteLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *returnDeviceLabel;
@property (nonatomic, weak) IBOutlet UITextField *officerPasswordTextField;

@property (nonatomic, weak) IBOutlet UIButton *proceedButton;
@property (nonatomic, weak) IBOutlet UIButton *replayButton;
@property (nonatomic, weak) IBOutlet UIButton *finishButton;

@end

@implementation PresentationCompleteViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self localizeStrings];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!self.delegate) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Must configure PresentationCompleteViewController with a delegate" userInfo:nil];
    }

    [self.audioPlayerService playSoundNamed:@"presentation_complete"];
}

- (void)configureWithPasswordValidator:(PasswordValidator *)passwordValidator delegate:(id<PresentationCompleteViewControllerDelegate>)delegate audioPlayerService:(AudioPlayerService *)audioPlayerService {
    self.passwordValidator = passwordValidator;
    self.delegate = delegate;
    self.audioPlayerService = audioPlayerService;
}

- (void)checkPassword {
    if ([self.passwordValidator isValidPassword:self.officerPasswordTextField.text]) {
        self.passwordIncorrectLabel.hidden = YES;

        self.officerPasswordTextField.enabled = NO;
        self.proceedButton.enabled = NO;

        self.replayButton.hidden = NO;
        self.finishButton.hidden = NO;

        [self.officerPasswordTextField endEditing:YES];
    } else {
        self.passwordIncorrectLabel.hidden = NO;
    }
}

- (IBAction)proceedButtonTapped:(UIButton *)sender {
    [self checkPassword];
}

- (IBAction)finishButtonTapped:(UIButton *)sender {
    [self.delegate presentationCompleteViewControllerDidFinish:self];
}

- (IBAction)replayButtonTapped:(UIButton *)sender {
    [self performSegueWithIdentifier:@"UnwindForReplayPresentation" sender:sender];
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self checkPassword];
    return YES;
}

#pragma mark - Private

- (void)localizeStrings {
    self.presentationCompleteLabel.text = WitnessLocalizedString(@"Presentation Complete.", nil);
    self.returnDeviceLabel.text = WitnessLocalizedString(@"Please return this device to the Officer.", nil);
}


@end
