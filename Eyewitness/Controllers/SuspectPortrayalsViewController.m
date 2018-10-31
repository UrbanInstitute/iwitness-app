#import "SuspectPhotoDetailViewController.h"
#import "SuspectPortrayalsViewController.h"
#import "SuspectCardView.h"
#import "SuspectPortrayalCell.h"
#import "FaceLoader.h"
#import "Portrayal.h"
#import "Person.h"

@interface SuspectPortrayalsViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) Person *person;
@end

@implementation SuspectPortrayalsViewController
@dynamic view;

- (void)configureWithPerson:(Person *)person {
    self.person = person;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"%@: %@, %@ %@", NSLocalizedString(@"ID", nil), self.person.systemID, self.person.firstName, self.person.lastName];

    self.view.collectionView.allowsMultipleSelection = YES;

    NSUInteger selectedPortrayalIndex = [self.person.portrayals indexOfObject:self.person.selectedPortrayal];
    [self.view.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:selectedPortrayalIndex inSection:0]
                                           animated:NO
                                     scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[SuspectPhotoDetailViewController class]]) {
        SuspectPhotoDetailViewController *controller =  segue.destinationViewController;
        Portrayal *portrayal = self.person.portrayals[[self.view.collectionView indexPathForCell:sender].item];
        [controller configureWithDelegate:self person:self.person portrayal:portrayal];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view.suspectCardView configureWithPerson:self.person faceLoader:[FaceLoader faceLoader]];
}

#pragma mark - <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"presentSuspectDetail" sender:[self.view.collectionView cellForItemAtIndexPath:indexPath]];
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"presentSuspectDetail" sender:[self.view.collectionView cellForItemAtIndexPath:indexPath]];
    return NO;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.person.portrayals.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SuspectPortrayalCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SuspectPortrayalCell" forIndexPath:indexPath];
    Portrayal *portrayal  = self.person.portrayals[indexPath.item];
    [cell configureWithPortrayal:portrayal];
    return cell;
}

#pragma mark - <SuspectPhotoDetailViewControllerDelegate>

- (void)suspectPhotoDetailViewControllerDidCancel:(SuspectPhotoDetailViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)suspectPhotoDetailViewController:(SuspectPhotoDetailViewController *)controller didSelectPortrayal:(Portrayal *)portrayal {
    for (NSIndexPath *selectedIndexPath in self.view.collectionView.indexPathsForSelectedItems) {
        [self.view.collectionView deselectItemAtIndexPath:selectedIndexPath animated:NO];
    }

    NSUInteger portrayalIndex = [self.person.portrayals indexOfObject:portrayal];

    self.person.selectedPortrayal = self.person.portrayals[portrayalIndex];

    NSIndexPath *portrayalIndexPath = [NSIndexPath indexPathForItem:portrayalIndex inSection:0];
    [self.view.collectionView selectItemAtIndexPath:portrayalIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];

    [self dismissViewControllerAnimated:YES completion:nil];
}
@end