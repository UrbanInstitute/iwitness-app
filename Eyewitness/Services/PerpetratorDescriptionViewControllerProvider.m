#import "PerpetratorDescriptionViewControllerProvider.h"
#import "PerpetratorDescriptionViewController.h"
#import "PerpetratorDescription.h"

@implementation PerpetratorDescriptionViewControllerProvider

- (PerpetratorDescriptionViewController *)perpetratorDescriptionViewControllerWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription {
    PerpetratorDescriptionViewController *controller = [[UIStoryboard storyboardWithName:@"WitnessDescription" bundle:nil] instantiateInitialViewController];
    [controller configureWithCaseID:caseID perpetratorDescription:perpetratorDescription];
    return controller;
}

@end
