#import "WitnessIdentificationViewController.h"
#import "AudioLevelMeter.h"
#import "WitnessIdentificationViewControllerDelegate.h"

@interface WitnessIdentificationViewController ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel *speakNowLabel;
@property(nonatomic, weak) id <WitnessIdentificationViewControllerDelegate> delegate;
@end

@implementation WitnessIdentificationViewController

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter delegate:(id <WitnessIdentificationViewControllerDelegate>)delegate {
    [super configureWithAudioLevelMeter:audioLevelMeter];
    self.delegate = delegate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self localizeStrings];
}

-(void)handleContinueButton {
    [self.delegate witnessIdentificationViewControllerDidContinue:self];
}

#pragma mark - Private

- (void)localizeStrings {
    self.speakNowLabel.text = WitnessLocalizedString(@"SPEAK NOW", nil);
    self.directionsPromptLabel.text = WitnessLocalizedString(@"Please state your name for the record and then press the “Continue →” button below.", nil);
    [self.continueButton setTitle:WitnessLocalizedString(@"CONTINUE →", nil) forState:UIControlStateNormal];
}

@end
