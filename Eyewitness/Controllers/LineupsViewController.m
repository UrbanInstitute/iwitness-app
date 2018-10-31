#import "LineupsViewController.h"
#import "LineupStore.h"
#import "LineupCell.h"
#import "Lineup.h"
#import "Presentation.h"
#import "PresentationStore.h"
#import "RecordingTimeAvailableCalculator.h"
#import "RecordingTimeAvailableHeaderView.h"
#import "PresentationFlowViewControllerProvider.h"
#import "LineupViewControllerConfigurer.h"

@interface LineupsViewController () <LineupCellDelegate>

@property (nonatomic, strong) PresentationFlowViewControllerProvider *presentationFlowViewControllerProvider;
@property (nonatomic, strong) LineupStore *lineupStore;
@property (nonatomic, strong) PresentationStore *presentationStore;
@property (nonatomic, strong) RecordingTimeAvailableCalculator *recordingTimeAvailableCalculator;
@property (nonatomic, strong) LineupViewControllerConfigurer *lineupViewControllerConfigurer;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *createLineupButton;
@property (nonatomic, weak) IBOutlet UITableView *lineupsTableView;

@property (nonatomic, strong) NSArray *lineups;

@property(nonatomic, strong) Presentation *presentedPresentation;
@end

@implementation LineupsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureWithPresentationFlowViewControllerProvider:(PresentationFlowViewControllerProvider *)presentationFlowViewControllerProvider
                                                lineupStore:(LineupStore *)lineupStore
                                          presentationStore:(PresentationStore *)presentationStore
                           recordingTimeAvailableCalculator:(RecordingTimeAvailableCalculator *)timeAvailableCalculator
                             lineupViewControllerConfigurer:(LineupViewControllerConfigurer *)lineupViewControllerConfigurer {
    self.presentationFlowViewControllerProvider = presentationFlowViewControllerProvider;
    self.lineupStore = lineupStore;
    self.presentationStore = presentationStore;
    self.recordingTimeAvailableCalculator = timeAvailableCalculator;
    self.lineupViewControllerConfigurer = lineupViewControllerConfigurer;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:@"ShowCreateLineup"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        [self.lineupViewControllerConfigurer configureLineupViewControllerForLineupCreation:(LineupViewController *)navigationController.topViewController];
    } else if ([segue.identifier isEqualToString:@"ShowEditLineup"]) {
        NSIndexPath *indexPath = [self.lineupsTableView indexPathForCell:sender];
        UINavigationController *navigationController = segue.destinationViewController;
        [self.lineupViewControllerConfigurer configureLineupViewController:(LineupViewController *)navigationController.topViewController
                                                          forEditingLineup:self.lineups[indexPath.item]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lineupsTableView.tableFooterView = [[UIView alloc] init];
    [self.lineupsTableView registerClass:[RecordingTimeAvailableHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([RecordingTimeAvailableHeaderView class])];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.lineups = [self.lineupStore allLineups];

    NSIndexPath *selectedIndexPath = [[self.lineupsTableView indexPathsForSelectedRows] firstObject];
    [self.lineupsTableView reloadData];
    if (selectedIndexPath) {
        [self.lineupsTableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

    [self.lineupsTableView layoutIfNeeded];
    [self updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)[self.lineupsTableView headerViewForSection:0]];
}

#pragma mark - <PresentationFlowViewControllerDelegate>

- (void)presentationFlowViewControllerDidFinish:(PresentationFlowViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - <LineupViewControllerDelegate>

- (void)lineupViewControllerDidComplete:(LineupViewController *)lineupViewController {
    if ([self.lineupsTableView indexPathsForSelectedRows]) {
        [self.lineupsTableView deselectRowAtIndexPath:[[self.lineupsTableView indexPathsForSelectedRows] firstObject] animated:NO];
    }

    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self.navigationController popToViewController:self animated:YES];
    }

    NSInteger indexOfEditedLineup = [self.lineups indexOfObject:lineupViewController.lineup];
    if (indexOfEditedLineup != NSNotFound) {
        [self.lineupsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfEditedLineup inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self updateCellHeightsAfterSelectionChangedAnimated:NO];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.lineups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LineupCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([LineupCell class]) forIndexPath:indexPath];
    Lineup *lineup = self.lineups[indexPath.row];
    cell.caseID = lineup.caseID;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    cell.dateString = [formatter stringFromDate:lineup.creationDate];
    cell.presentToWitnessButton.enabled = lineup.valid;

    return cell;
}

#pragma mark - <UITableViewDelegate>

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    for (NSIndexPath *selectedIndexPath in [tableView indexPathsForSelectedRows]) {
        [tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateCellHeightsAfterSelectionChangedAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateCellHeightsAfterSelectionChangedAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView indexPathsForSelectedRows] containsObject:indexPath]) {
        return 176;
    } else {
        return tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    RecordingTimeAvailableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([RecordingTimeAvailableHeaderView class])];
    [self updateRecordingTimeAvailableHeader:headerView];

    return headerView;
}

#pragma mark - <LineupCellDelegate>

- (void)lineupCellDidRequestEditing:(LineupCell *)cell {
    [self performSegueWithIdentifier:@"ShowEditLineup" sender:cell];
}

- (void)lineupCellDidRequestPresentation:(LineupCell *)cell {
    NSIndexPath *indexPath = [self.lineupsTableView indexPathForCell:cell];
    self.presentedPresentation = [self.presentationStore createPresentationWithLineup:self.lineups[indexPath.row]];
    PresentationFlowViewController *presentationFlowViewController = [self.presentationFlowViewControllerProvider presentationFlowViewControllerWithPresentation:self.presentedPresentation
                                                                                                                                                    flowDelegate:self];
    [self presentViewController:presentationFlowViewController animated:YES completion:NULL];
}

#pragma mark - Unwind Segue

- (IBAction)presentationCanceled:(UIStoryboardSegue *)segue {
    [self.presentationStore deletePresentation:self.presentedPresentation];
    self.presentedPresentation = nil;
}

#pragma mark - Notification Handlers

- (void)applicationWillEnterForeground {
    [self updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)[self.lineupsTableView headerViewForSection:0]];
}

#pragma mark - private

- (void)updateCellHeightsAfterSelectionChangedAnimated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.3f : 0 animations:^{
        [self.lineupsTableView beginUpdates];
        [self.lineupsTableView endUpdates];
        [self.lineupsTableView layoutIfNeeded];
    }];
}

- (void)updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)headerView {
    headerView.availableMinutes = [self.recordingTimeAvailableCalculator calculateAvailableMinutesOfRecordingTime];
    headerView.timeAvailableStatus = [self.recordingTimeAvailableCalculator recordingTimeAvailableStatus];
}

@end
