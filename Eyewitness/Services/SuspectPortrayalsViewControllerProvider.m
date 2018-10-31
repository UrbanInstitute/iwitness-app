#import "SuspectPortrayalsViewControllerProvider.h"
#import "SuspectPortrayalsViewController.h"
#import "Person.h"

@implementation SuspectPortrayalsViewControllerProvider

- (SuspectPortrayalsViewController *)suspectPortrayalsViewControllerWithPerson:(Person *)person {
    SuspectPortrayalsViewController *controller = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectPortrayalsViewController"];
    [controller configureWithPerson:person];
    return controller;
}

@end
