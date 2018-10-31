#import "IdentificationCertaintyViewController.h"

@implementation IdentificationCertaintyViewController

- (void)handleContinueButton {
    [self.delegate identificationCertaintyViewControllerDidContinue:self];
}

- (NSString *)promptSoundName {
    return @"identification_certainty";
}

#pragma mark - Private

- (void)localizeStrings {
    self.witnessPromptLabel.text = WitnessLocalizedString(@"Please state how certain you are of this identification.", nil);
}


@end
