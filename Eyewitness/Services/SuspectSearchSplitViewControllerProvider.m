#import "SuspectSearchSplitViewControllerProvider.h"
#import "SuspectSearchViewController.h"
#import "SuspectSearchSplitViewController.h"
#import "SuspectSearchResultsViewController.h"
#import "PersonSearchService.h"
#import "PersonSearchServiceProvider.h"

@implementation SuspectSearchSplitViewControllerProvider

- (SuspectSearchSplitViewController *)suspectSearchSplitViewControllerWithCaseID:(NSString *)caseID {
    SuspectSearchSplitViewController *viewController = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectSearchSplitViewController"];
    (void)[viewController view];
    [viewController.searchViewController configureWithCaseID:caseID delegate:viewController.resultsViewController];
    [viewController.resultsViewController configureWithPersonSearchService:[[[PersonSearchServiceProvider alloc] init] personSearchService]];
    return viewController;
}

@end
