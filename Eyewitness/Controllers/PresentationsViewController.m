#import <MediaPlayer/MediaPlayer.h>
#import "PresentationsViewController.h"
#import "PresentationCell.h"
#import "PresentationStore.h"
#import "presentation.h"
#import "MoviePlayerViewController.h"
#import "StitchingProgressIndicatorView.h"
#import "VideoStitcher.h"
#import "StitchingQueue.h"
#import "AlertView.h"
#import "RecordingTimeAvailableCalculator.h"
#import "RecordingTimeAvailableFormatter.h"
#import "EyewitnessTheme.h"
#import "RecordingTimeAvailableHeaderView.h"
#import "DefaultButton.h"
#import "AnalyticsTracker.h"
#import "Lineup.h"

@interface PresentationsViewController () <PresentationCellDelegate, UITableViewDataSource>
@property (nonatomic, strong) PresentationStore *presentationStore;
@property (nonatomic, strong) RecordingTimeAvailableCalculator *recordingTimeAvailableCalculator;
@property (nonatomic, weak) StitchingQueue *stitchingQueue;

@property (nonatomic, strong) NSArray *presentations;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation PresentationsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureWithPresentationStore:(PresentationStore *)presentationStore
      recordingTimeAvailableCalculator:(RecordingTimeAvailableCalculator *)timeAvailableCalculator
                        stitchingQueue:(StitchingQueue *)stitchingQueue {
    self.presentationStore = presentationStore;
    self.recordingTimeAvailableCalculator = timeAvailableCalculator;
    self.stitchingQueue = stitchingQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.tableView registerClass:[RecordingTimeAvailableHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([RecordingTimeAvailableHeaderView class])];

    //MOK removes
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self reloadPresentations];
    [self.tableView reloadData];
    [self.stitchingQueue addStitchingObserver:self];

    [self.tableView layoutIfNeeded];
    [self updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)[self.tableView headerViewForSection:0]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.stitchingQueue removeStitchingObserver:self];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - StitchingQueueObserver
- (void)stitchingQueue:(id)queue didUpdateProgress:(float)progress forPresentationUUID:(NSString *)presentationUUID {
    PresentationCell *cell = (PresentationCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForPresentationUUID:presentationUUID]];
    cell.indicatorView.progress = progress;
}

- (void)stitchingQueue:(id)queue didCompleteStitchingForPresentationUUID:(NSString *)presentationUUID {
    [self reloadPresentations];
    NSIndexPath *indexPath = [self indexPathForPresentationUUID:presentationUUID];
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)stitchingQueue:(StitchingQueue *)queue didCancelStitchingForPresentationUUID:(NSString *)presentationUUID {
    NSIndexPath *indexPath = [self indexPathForPresentationUUID:presentationUUID];
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - Accessors

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"MMMM dd, yyyy HH:mm"];
    }
    return _dateFormatter;
}

- (NSArray *)presentations {
    if (!_presentations) {
        NSArray *presentations = self.presentationStore.allPresentations;
        _presentations = [presentations sortedArrayUsingComparator:^NSComparisonResult(Presentation *pres1, Presentation *pres2) {
            return [pres2.date compare:pres1.date];
        }];
    }
    return _presentations;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.presentations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PresentationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PresentationCell" forIndexPath:indexPath];
    Presentation *presentation = self.presentations[indexPath.row];
    cell.caseIDLabel.text = presentation.lineup.caseID;
    cell.dateLabel.text = [self.dateFormatter stringFromDate:presentation.date];

    VideoStitcher *stitcher = [self.stitchingQueue stitcherForPresentation:presentation];

    if (stitcher) {
        cell.indicatorView.hidden = NO;
        cell.viewPresentationButton.hidden = YES;
        cell.indicatorView.progress = stitcher.progress;
    } else {
        cell.indicatorView.hidden = YES;
        cell.viewPresentationButton.hidden = NO;
        cell.viewPresentationButton.style = presentation.videoURL ? ButtonStylePrimary : ButtonStyleWarn;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this presentation?", nil)
                             message:NSLocalizedString(@"This cannot be undone.", nil)
                    cancelButtonTitle:NSLocalizedString(@"Delete", @"Delete")
                   otherButtonTitles:@[NSLocalizedString(@"Cancel", @"Cancel")]
                       cancelHandler:^{
                           Presentation *presentation = self.presentations[indexPath.row];
                           [self.presentationStore deletePresentation:presentation];
                           [self reloadPresentations];
                           [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                                 withRowAnimation:UITableViewRowAnimationAutomatic];
                           [self updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)[self.tableView headerViewForSection:0]];
                       } confirmationHandler:^(NSInteger otherButtonIndex) {
                           [self setEditing:NO animated:YES];
                       }] show];
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    RecordingTimeAvailableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([RecordingTimeAvailableHeaderView class])];
    [self updateRecordingTimeAvailableHeader:headerView];

    return headerView;
}

#pragma mark - <PresentationCellDelegate>

- (void)presentationCellDidTapViewPresentation:(PresentationCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Presentation *presentation = self.presentations[indexPath.row];
    if (presentation.videoURL) {
        AVURLAsset *presentationVideoAsset = [AVURLAsset URLAssetWithURL:presentation.videoURL options:nil];
        [presentationVideoAsset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AnalyticsTracker sharedInstance] trackPresentationPlaybackWithLength:(NSTimeInterval)CMTimeGetSeconds(presentationVideoAsset.duration)];
            });
        }];

        MoviePlayerViewController *videoPlayer = [[MoviePlayerViewController alloc] initWithContentURL:presentation.videoURL];
        [self.navigationController presentMoviePlayerViewControllerAnimated:videoPlayer];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Cannot show the video. It may still be in production." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

#pragma mark - Notification Handlers

- (void)applicationWillEnterForeground {
    [self updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)[self.tableView headerViewForSection:0]];
}

#pragma mark - Private

- (NSIndexPath *)indexPathForPresentationUUID:(NSString *)presentationUUID {
    NSInteger index = [self.presentations indexOfObjectPassingTest:^BOOL(Presentation *presentation, NSUInteger idx, BOOL *stop) {
        return *stop = [presentation.UUID isEqualToString:presentationUUID];
    }];
    return index==NSNotFound ? nil : [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)reloadPresentations {
    self.presentations = nil;
    [self.presentationStore reload];
}

- (void) updateRecordingTimeAvailableHeader:(RecordingTimeAvailableHeaderView *)headerView {
    headerView.availableMinutes = [self.recordingTimeAvailableCalculator calculateAvailableMinutesOfRecordingTime];
    headerView.timeAvailableStatus = [self.recordingTimeAvailableCalculator recordingTimeAvailableStatus];
}

@end
