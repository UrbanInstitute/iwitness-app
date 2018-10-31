#import "AudioWarningViewController.h"
#import "AlertView.h"

static const float kMinimumOutputVolume = 0.5f;

@interface AudioWarningViewController ()
@property(weak, nonatomic, readwrite) IBOutlet UIButton *continueButton;
@property(weak, nonatomic, readwrite) IBOutlet UIBarButtonItem *cancelButton;
@property(strong, nonatomic) AVAudioSession *audioSession;
@end

@implementation AudioWarningViewController
- (void)dealloc {
    if(self.audioSession) {
        [self.audioSession removeObserver:self forKeyPath:@"outputVolume"];
    }
}

- (void)configureWithAudioSession:(AVAudioSession *)audioSession {
    if ([audioSession setActive:YES withOptions:0 error:nil]) {
        self.audioSession = audioSession;
        [self.audioSession addObserver:self forKeyPath:@"outputVolume" options:0 context:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkAudioLevel];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([@"outputVolume" isEqualToString:keyPath]) {
        self.continueButton.enabled = self.audioSession.outputVolume >= kMinimumOutputVolume;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - private

- (void)checkAudioLevel {
    if (!self.audioSession) {
        [[[AlertView alloc] initWithTitle:@"Cannot monitor audio levels"
                                  message:@"The audio levels cannot be monitored at this time.  "
                                          "Please check and adjust the audio levels using the volume buttons of the device, "
                                          "and tap “OK” to continue with the presentation."
                        cancelButtonTitle:@"OK"
                        otherButtonTitles:nil
                            cancelHandler:^{
                                [self performSegueWithIdentifier:@"pushPreparation" sender:self];
                            }
                      confirmationHandler:nil] show];
    } else if(self.audioSession.outputVolume >= kMinimumOutputVolume) {
        [self performSegueWithIdentifier:@"pushPreparation" sender:self];
    } else {
        self.continueButton.enabled = NO;
    }
}
@end
