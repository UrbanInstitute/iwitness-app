#import "PresentationFlowViewController.h"
#import "LineupViewController.h"
#import "PresentationFlowViewControllerDelegate.h"

@class RecordingTimeAvailableCalculator, LineupStore, PresentationStore, PresentationFlowViewControllerProvider, LineupViewControllerConfigurer;

@interface LineupsViewController : UIViewController<PresentationFlowViewControllerDelegate, LineupViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak, readonly) UIBarButtonItem *createLineupButton;
@property (weak, nonatomic, readonly) UITableView *lineupsTableView;

- (void)configureWithPresentationFlowViewControllerProvider:(PresentationFlowViewControllerProvider *)presentationFlowViewControllerProvider
                                                lineupStore:(LineupStore *)lineupStore
                                          presentationStore:(PresentationStore *)presentationStore
                           recordingTimeAvailableCalculator:(RecordingTimeAvailableCalculator *)timeAvailableCalculator
                             lineupViewControllerConfigurer:(LineupViewControllerConfigurer *)lineupViewControllerConfigurer;

- (IBAction)presentationCanceled:(UIStoryboardSegue *)segue;
@end
