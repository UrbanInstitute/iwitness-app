#import "QualifyUncertaintyViewController.h"

@implementation QualifyUncertaintyViewController

- (void)handleContinueButton {
    [self.delegate qualifyUncertaintyViewControllerDidContinue:self];
}

- (NSString *)promptSoundName {
    return @"uncertainty_qualification";
}

#pragma mark - Private

- (void)localizeStrings {
    self.witnessPromptLabel.text = WitnessLocalizedString(@"Please explain.", nil);
}
@end
