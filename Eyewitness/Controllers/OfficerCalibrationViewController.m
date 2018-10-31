#import "OfficerCalibrationViewController.h"
#import "OfficerCalibrationViewControllerDelegate.h"
#import "AlertView.h"
#import "AnalyticsTracker.h"
#import "AudioLevelMeter.h"

@interface OfficerCalibrationViewController ()
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, weak) id<OfficerCalibrationViewControllerDelegate> delegate;
@end

@implementation OfficerCalibrationViewController

- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter audioSession:(AVAudioSession *)audioSession delegate:(id <OfficerCalibrationViewControllerDelegate>)delegate {
    [super configureWithAudioLevelMeter:audioLevelMeter];
    self.audioSession = audioSession;
    self.delegate = delegate;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.audioSession requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.continueButton.enabled = granted;
            if (!granted) {
                [[AnalyticsTracker sharedInstance] trackMicrophoneAccessDenied];

                AlertView *alert = [[AlertView alloc] initWithTitle:NSLocalizedString(@"Need Microphone Access", nil)
                                                            message:NSLocalizedString(@"Please adjust your Privacy settings in the Settings app to enable microphone access for the Eyewitness app.", nil)
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil
                                                      cancelHandler:^{
                                                          [self.delegate officerCalibrationViewControllerDidCancel:self];
                                                      }
                                                confirmationHandler:NULL];
                [alert show];
            }
        });
    }];
}

-(void)handleContinueButton {
    [self.delegate officerCalibrationViewControllerDidContinue:self];
}

@end
