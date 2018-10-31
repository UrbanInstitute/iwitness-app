#import "SuspectSearchSplitViewController.h"
#import "SuspectSearchViewController.h"
#import "SuspectSearchResultsViewController.h"

@interface SuspectSearchSplitViewController ()
@property (nonatomic, weak, readwrite) SuspectSearchViewController *searchViewController;
@property (nonatomic, weak, readwrite) SuspectSearchResultsViewController *resultsViewController;
@end

@implementation SuspectSearchSplitViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.destinationViewController isKindOfClass:[SuspectSearchViewController class]]) {
        self.searchViewController = segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[SuspectSearchResultsViewController class]]) {
        self.resultsViewController = segue.destinationViewController;
    }
}

@end
