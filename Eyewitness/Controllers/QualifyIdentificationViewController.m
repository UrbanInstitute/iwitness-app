#import "QualifyIdentificationViewController.h"

@implementation QualifyIdentificationViewController

- (void)handleContinueButton {
    [self.delegate qualifyIdentificationViewControllerDidContinue:self];
}

- (NSString *)promptSoundName {
    return @"identification_qualification";
}

#pragma mark - Private

- (void)localizeStrings {
    self.witnessPromptLabel.text = WitnessLocalizedString(@"Please state where you recognize this person from.", nil);
}
@end
