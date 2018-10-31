#import "LineupPhotosDataSource.h"
#import "LineupPhotoCell.h"
#import "PhotoAssetMetadataManager.h"
#import "UIImageView+FocusOnRect.h"

@interface LineupPhotosDataSource ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) id<LineupPhotoCellDelegate> cellDelegate;
@property (strong, nonatomic) PhotoAssetMetadataManager *metadataManager;
@end

@implementation LineupPhotosDataSource

- (void)configureWithLineupPhotoCellDelegate:(id <LineupPhotoCellDelegate>)photoCellDelegate metadataManager:(PhotoAssetMetadataManager *)metadataManager {
    self.cellDelegate = photoCellDelegate;
    self.metadataManager = metadataManager;
}

- (void)setMaximumNumberOfPhotos:(NSUInteger)maximumNumberOfPhotos {
    _maximumNumberOfPhotos = maximumNumberOfPhotos;
    [self.collectionView reloadData];
}

- (void)setPhotoURLs:(NSArray *)photoURLs {
    if ([photoURLs isEqual:_photoURLs] || photoURLs == _photoURLs) { return; }

    _photoURLs = photoURLs;
    [self.collectionView reloadData];
}

- (void)setEditing:(BOOL)editing {
    _editing = editing;

    for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
        if ([cell isKindOfClass:[LineupPhotoCell class]]) {
            [(LineupPhotoCell *)cell setEditing:editing];
        }
    }

    if ([self.collectionView numberOfItemsInSection:0] < [self collectionView:nil numberOfItemsInSection:0]) {
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.photoURLs.count
                                                                           inSection:0]]];
    } else if ([self.collectionView numberOfItemsInSection:0] > [self collectionView:nil numberOfItemsInSection:0]) {
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.photoURLs.count
                                                                           inSection:0]]];
    }
}

- (void)removePhotoURL:(NSURL *)photoURL {
    NSInteger oldPhotoURLsCount = [self.photoURLs count];
    NSInteger photoIndexToDelete = [self.photoURLs indexOfObject:photoURL];
    if (photoIndexToDelete == NSNotFound) { return; }

    NSIndexPath *indexPathToDelete = [NSIndexPath indexPathForItem:photoIndexToDelete inSection:0];
    NSMutableArray *newPhotoURLs = [self.photoURLs mutableCopy];
    [newPhotoURLs removeObjectAtIndex:photoIndexToDelete];

    _photoURLs = newPhotoURLs;

    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[ indexPathToDelete ]];
        if (self.isEditing && oldPhotoURLsCount == self.maximumNumberOfPhotos) {
            [self.collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:self.photoURLs.count inSection:0] ]];
        }
    } completion:nil];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isEditing && [self.photoURLs count] < self.maximumNumberOfPhotos) {
        return [self.photoURLs count] + 1;
    } else {
        return [self.photoURLs count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;

    if ([self isPlaceholderAtIndexPath:indexPath]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddPhotoCell" forIndexPath:indexPath];
    } else {
        LineupPhotoCell *lineupPhotoCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LineupPhotoCell" forIndexPath:indexPath];
        UIImageView *imageView = lineupPhotoCell.imageView;

        NSURL *photoURL = self.photoURLs[indexPath.item];

        UIImage *image = [UIImage imageWithContentsOfFile:[photoURL path]];
        imageView.image = image;

        [imageView focusOnImageRect:[self.metadataManager largestFaceRectForPhotoURL:photoURL]];

        [lineupPhotoCell setEditing:self.editing];
        [lineupPhotoCell configureWithDelegate:self.cellDelegate];

        cell = lineupPhotoCell;
    }

    return cell;
}

- (BOOL)isPlaceholderAtIndexPath:(NSIndexPath *)indexPath {
    return [self.photoURLs count] < self.maximumNumberOfPhotos && indexPath.item == [self.photoURLs count];
}

@end
