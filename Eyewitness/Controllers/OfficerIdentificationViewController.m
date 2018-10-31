#import "OfficerIdentificationViewController.h"
#import "AudioLevelMeter.h"
#import "OfficerIdentificationViewControllerDelegate.h"

@interface OfficerIdentificationViewController ()
@property (weak, nonatomic) id <OfficerIdentificationViewControllerDelegate> delegate;
@end

@implementation OfficerIdentificationViewController
- (void)configureWithAudioLevelMeter:(AudioLevelMeter *)audioLevelMeter delegate:(id<OfficerIdentificationViewControllerDelegate>) delegate {
    [super configureWithAudioLevelMeter:audioLevelMeter];
    self.delegate = delegate;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.delegate officerIdentificationViewControllerDidAppear:self];
}


-(void)handleContinueButton {
    [self.delegate officerIdentificationViewControllerDidContinue:self];
}

@end
