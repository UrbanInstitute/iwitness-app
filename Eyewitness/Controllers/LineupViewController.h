@class LineupViewController, LineupStore, Lineup, PhotoAssetImporter, SuspectSearchSplitViewControllerProvider, SuspectCardView, PerpetratorDescriptionViewControllerProvider;
@class SuspectPortrayalsViewControllerProvider;
@class PersonSearchServiceProvider;

@protocol LineupViewControllerDelegate <NSObject>
- (void)lineupViewControllerDidComplete:(LineupViewController *)lineupViewController;
@end

@interface LineupViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic, readonly) UISwitch *audioOnlySwitch;
@property (weak, nonatomic, readonly) UILabel *audioOnlySwitchLabel;
@property (nonatomic, strong, readonly) Lineup *lineup;
@property (nonatomic, strong, readonly) LineupStore *lineupStore;

@property (weak, nonatomic, readonly) UITextField *caseIDTextField;
@property (weak, nonatomic, readonly) UITextField *suspectNameTextField;

@property (weak, nonatomic, readonly) UILabel *suspectPhotoRequiredLabel;

@property (strong, nonatomic, readonly) UIBarButtonItem *cancelButton;
@property (strong, nonatomic, readonly) UIBarButtonItem *doneButton;
@property (weak, nonatomic, readonly) UIBarButtonItem *deleteButton;
@property (weak, nonatomic, readonly) UIButton *chooseFromDBButton;

@property (weak, nonatomic, readonly) SuspectCardView *suspectCardView;

- (void)configureWithLineupStore:(LineupStore *)lineupStore lineup:(Lineup *)lineup photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter suspectSearchSplitViewControllerProvider:(SuspectSearchSplitViewControllerProvider *)suspectSearchSplitViewControllerProvider perpetratorDescriptionViewControllerProvider:(PerpetratorDescriptionViewControllerProvider *)perpetratorDescriptionViewControllerProvider suspectPortrayalsViewControllerProvider:(SuspectPortrayalsViewControllerProvider *)suspectPortrayalsViewControllerProvider personSearchServiceProvider:(PersonSearchServiceProvider *)personSearchServiceProvider delegate:(id <LineupViewControllerDelegate>)delegate;

- (IBAction)exitToLineup:(UIStoryboardSegue *)sender;

@end
