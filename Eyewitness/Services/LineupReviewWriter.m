#import "LineupReviewWriter.h"
#import "Lineup.h"
#import "LineupViewController.h"
#import "LineupFillerPhotosViewController.h"
#import "Presentation.h"

static const float kBottomPadding = 10.f;

@implementation LineupReviewWriter

- (void)writeLineupReviewForPresentation:(Presentation *)presentation {
    CGRect letterSizeRect = CGRectMake(0.f, 0.f, 612.f, 792.f);

    LineupViewController *lineupVC = [self setUpLineupViewControllerForWritingPDFForLineup:presentation.lineup];

    UIGraphicsBeginPDFContextToFile(presentation.temporaryLineupReviewURL.path, CGRectZero, nil);
    UIGraphicsBeginPDFPageWithInfo(letterSizeRect, nil);

    CGFloat heightRatio = CGRectGetHeight(letterSizeRect) / CGRectGetHeight(lineupVC.view.bounds);
    CGFloat widthRatio = CGRectGetWidth(letterSizeRect) / CGRectGetWidth(lineupVC.view.bounds);

    if(heightRatio < widthRatio) {
//MOK casts
        [lineupVC.view drawViewHierarchyInRect:CGRectMake(fabsf((float)(
                                                                CGRectGetWidth(lineupVC.view.bounds) * heightRatio - CGRectGetWidth(letterSizeRect))) / 2.f, 0.f, CGRectGetWidth(lineupVC.view.bounds) * heightRatio, CGRectGetHeight(lineupVC.view.bounds) * heightRatio) afterScreenUpdates:YES];
    } else {
        [lineupVC.view drawViewHierarchyInRect:CGRectMake(0.f, 0.f, CGRectGetWidth(lineupVC.view.bounds) * widthRatio, CGRectGetHeight(lineupVC.view.bounds) * widthRatio) afterScreenUpdates:YES];
    }

    UIGraphicsEndPDFContext();
}

#pragma mark - private

- (LineupViewController *)setUpLineupViewControllerForWritingPDFForLineup:(Lineup *)lineup {
    CGRect maxViewSize = CGRectMake(0.f, 44.f, 768.f, 1354.f);
    LineupViewController *lineupVC = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupViewController"];
    [lineupVC configureWithLineupStore:nil lineup:lineup photoAssetImporter:nil suspectSearchSplitViewControllerProvider:nil perpetratorDescriptionViewControllerProvider:nil suspectPortrayalsViewControllerProvider:nil personSearchServiceProvider:nil delegate:nil];

    lineupVC.view.frame = maxViewSize;
    [lineupVC viewWillAppear:NO];
    [lineupVC viewDidAppear:NO];
    lineupVC.editing = NO;
    lineupVC.audioOnlySwitch.hidden = lineupVC.audioOnlySwitchLabel.hidden = YES;

    [self sizeViewToFitAllCells:lineupVC];

    return lineupVC;
}

- (void)sizeViewToFitAllCells:(LineupViewController *)lineupVC {
    CGPoint lastCellBottomRightInViewSpace = [self getBottomRightPointThatFitsAllCells:lineupVC];
    [lineupVC.view resizeTo:CGSizeMake(CGRectGetWidth(lineupVC.view.bounds), lastCellBottomRightInViewSpace.y + kBottomPadding)];
}

- (CGPoint)getBottomRightPointThatFitsAllCells:(LineupViewController *)lineupVC {
    [lineupVC.view snapshotViewAfterScreenUpdates:YES];

    LineupFillerPhotosViewController *lineupFillerPhotosViewController = [lineupVC.childViewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class == %@", [LineupFillerPhotosViewController class]]].firstObject;
    NSInteger numberOfCells = [lineupFillerPhotosViewController.photoCollectionView numberOfItemsInSection:0];
    UICollectionViewCell *lastCell = [lineupFillerPhotosViewController.photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:numberOfCells - 1 inSection:0]];

    [lineupFillerPhotosViewController.photoCollectionView layoutIfNeeded];

    CGPoint lastCellBottomRight = CGPointMake(CGRectGetMaxX(lastCell.frame), CGRectGetMaxY(lastCell.frame));
    CGPoint lastCellBottomRightInViewSpace = [lineupVC.view convertPoint:lastCellBottomRight fromView:lineupFillerPhotosViewController.photoCollectionView];
    return lastCellBottomRightInViewSpace;
}

@end