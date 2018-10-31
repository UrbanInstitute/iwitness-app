#import "SuspectSearchResultsViewController.h"
#import "SuspectPortrayalsViewController.h"
#import "SuspectSearchResultsHeaderView.h"
#import "SuspectCardView.h"
#import "PersonSearchService.h"
#import "PersonResultCell.h"
#import "FaceLoader.h"
#import "Person.h"

@interface SuspectSearchResultsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) PersonSearchService *personSearchService;
@property (nonatomic, strong) NSArray *personResults;
@end

@implementation SuspectSearchResultsViewController
//MOK Adds
@dynamic view;

- (void)configureWithPersonSearchService:(PersonSearchService *)personSearchService {
    self.personSearchService = personSearchService;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.identifier isEqualToString:@"ShowSuspectPortrayals"]) {
        SuspectPortrayalsViewController *suspectPortrayalsViewController = segue.destinationViewController;
        NSIndexPath *indexPath = [self.view.collectionView indexPathForCell:sender];
        [suspectPortrayalsViewController configureWithPerson:self.personResults[indexPath.item]];
    }
}

#pragma mark - <SuspectSearchViewControllerDelegate>

- (void)suspectSearchViewController:(SuspectSearchViewController *)suspectSearchViewController didRequestSearchWithFirstName:(NSString *)firstName lastName:(NSString *)lastName suspectID:(NSString *)suspectID {
    [[self.personSearchService personResultsForFirstName:firstName lastName:lastName suspectID:suspectID] then:^id(NSArray *personResults) {
        self.personResults = personResults;
        [self.view.collectionView reloadData];
        return nil;
    } error:^id(NSError *error) {
        return nil;
    }];
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    static SuspectCardView *_suspectCardView = nil;

    if(!_suspectCardView) {
        _suspectCardView = [[SuspectCardView alloc] init];
    }

    [_suspectCardView configureWithPerson:self.personResults[indexPath.item] faceLoader:[FaceLoader faceLoader]];

    return _suspectCardView.intrinsicContentSize;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.personResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PersonResultCell *cell = (PersonResultCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PersonResultCell" forIndexPath:indexPath];
    [cell configureWithPerson:self.personResults[indexPath.item] faceLoader:[FaceLoader faceLoader]];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        SuspectSearchResultsHeaderView *headerView = (SuspectSearchResultsHeaderView *)[self.view.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SuspectSearchResultsHeaderView" forIndexPath:indexPath];

        if (!self.personResults) {
            headerView.numberOfResultsLabel.text = @"";
        } else if (self.personResults.count == 1) {
            headerView.numberOfResultsLabel.text = NSLocalizedString(@"1 result", nil);
        } else {
            headerView.numberOfResultsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld results", nil), self.personResults.count];
        }

        self.view.suspectSearchResultsHeaderView = headerView;
        return headerView;
    }

    return nil;
}

@end
