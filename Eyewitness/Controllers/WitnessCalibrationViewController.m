#import "WitnessCalibrationViewController.h"
#import "LanguagesViewController.h"
#import "NSLocale+LanguageDescription.h"
#import "AudioLevelMeter.h"
#import "WitnessCalibrationViewControllerDelegate.h"

@interface WitnessCalibrationViewController () <LanguagesViewControllerDelegate>
@property (nonatomic, weak, readwrite) IBOutlet UIButton *languageSelectionButton;
@property (weak, nonatomic) id <WitnessCalibrationViewControllerDelegate> delegate;
@property (nonatomic, strong) UIPopoverController *languageSelectionPopoverController;
@end

@implementation WitnessCalibrationViewController

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter delegate:(id<WitnessCalibrationViewControllerDelegate>) delegate {
    [super configureWithAudioLevelMeter:audioLevelMeter];
    self.delegate = delegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [WitnessLocalization setWitnessLanguageCode:@"en"];

    [self localizeStrings];
}

-(void)handleContinueButton {
    [self.delegate witnessCalibrationViewControllerDidContinue:self];
}

- (IBAction)languageSelectionButtonTapped:(UIButton *)sender {
    LanguagesViewController *languagesViewController = [[LanguagesViewController alloc] initWithDelegate:self];
    self.languageSelectionPopoverController = [[UIPopoverController alloc] initWithContentViewController:languagesViewController];
    [self.languageSelectionPopoverController presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - <LanguagesViewControllerDelegate>

- (void)languagesViewController:(LanguagesViewController *)controller didSelectLanguageWithCode:(NSString *)code {
    [self.languageSelectionPopoverController dismissPopoverAnimated:YES];
    [self localizeStrings];
}

#pragma mark - private

- (void)localizeStrings {
    [self.languageSelectionButton setTitle:[[NSLocale languageDescriptionForCode:[WitnessLocalization witnessLanguageCode]] uppercaseString]
                                  forState:UIControlStateNormal];
}

@end
