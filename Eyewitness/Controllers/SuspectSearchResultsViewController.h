#import <UIKit/UIKit.h>
#import "SuspectSearchResultsView.h"
#import "SuspectSearchViewController.h"
#import "SuspectSearchViewControllerDelegate.h"

@class PersonSearchService;

@interface SuspectSearchResultsViewController : UIViewController <SuspectSearchViewControllerDelegate>
@property (nonatomic, retain) SuspectSearchResultsView *view;

- (void)configureWithPersonSearchService:(PersonSearchService *)personSearchService;

@end
