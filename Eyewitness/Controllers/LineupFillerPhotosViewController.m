#import "LineupFillerPhotosViewController.h"
#import "PhotoAssetMetadataManager.h"
#import "LineupPhotosDataSource.h"
#import "LineupPhotoCell.h"
#import "Lineup.h"
#import "ImportingPhotoPickerViewController.h"
#import "PhotoAssetImporter.h"

@interface LineupFillerPhotosViewController () <LineupPhotoCellDelegate>

@property (nonatomic, strong) Lineup *lineup;
@property (weak, nonatomic, readwrite) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *fillerPhotosRequiredLabel;
@property (strong, nonatomic) IBOutlet LineupPhotosDataSource *lineupPhotosDataSource;
@property(nonatomic, strong) PhotoAssetImporter *photoAssetImporter;
@end

@implementation LineupFillerPhotosViewController

- (void)configureWithLineup:(Lineup *)lineup
         photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter {
    self.lineup = lineup;
    [self.lineupPhotosDataSource configureWithLineupPhotoCellDelegate:self
                                                      metadataManager:[[PhotoAssetMetadataManager alloc] init]];
    self.lineupPhotosDataSource.maximumNumberOfPhotos = [Lineup maximumNumberOfFillerPhotos];
    self.photoAssetImporter = photoAssetImporter;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    for(NSIndexPath *indexPath in self.photoCollectionView.indexPathsForSelectedItems) {
        [self.photoCollectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    self.lineupPhotosDataSource.photoURLs = self.lineup.fillerPhotosFileURLs;
    self.fillerPhotosRequiredLabel.text = [NSString stringWithFormat:@"AT LEAST %lu FILLERS REQUIRED FOR PRESENTATION", (unsigned long)[Lineup minimumNumberOfFillerPhotos]];
    [self updateValidationLabel];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!editing) {
        self.lineupPhotosDataSource.photoURLs = self.lineup.fillerPhotosFileURLs;
        [self updateValidationLabel];
    }
    self.lineupPhotosDataSource.editing = editing;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"ShowPhotoPickerForFillers"]) {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        ImportingPhotoPickerViewController *controller = (ImportingPhotoPickerViewController *)[[segue destinationViewController] topViewController];
        [controller configureWithDelegate:self assetLibrary:assetsLibrary selectedPhotoURLs:self.lineup.fillerPhotosFileURLs photoAssetImporter:self.photoAssetImporter];
    }
}

#pragma mark - <LineupPhotoCell>
- (void)lineupPhotoCellDidDelete:(LineupPhotoCell *)cell {
    NSInteger indexToDelete = [self.photoCollectionView indexPathForCell:cell].item;
    NSURL *photoURLToDelete = [self.lineup.fillerPhotosFileURLs objectAtIndex:indexToDelete];

    NSMutableArray *array = [self.lineup.fillerPhotosFileURLs mutableCopy];
    [array removeObjectAtIndex:indexToDelete];
    self.lineup.fillerPhotosFileURLs = [array copy];

    [self.lineupPhotosDataSource removePhotoURL:photoURLToDelete];

    [self updateValidationLabel];
}

#pragma mark - <PhotoPickerViewControllerDelegate>
- (NSUInteger)maximumSelectionCountForPhotoPickerViewController:(ImportingPhotoPickerViewController *)controller {
    return [Lineup maximumNumberOfFillerPhotos];
}

- (void)photoPickerViewController:(ImportingPhotoPickerViewController *)controller didImportPhotoURLs:(NSArray *)photoURLs {
    self.lineupPhotosDataSource.photoURLs = self.lineup.fillerPhotosFileURLs = photoURLs;
    [self updateValidationLabel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)photoPickerViewControllerDidCancel:(ImportingPhotoPickerViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private
- (void)updateValidationLabel {
    self.fillerPhotosRequiredLabel.hidden = self.lineup.fillerPhotosFileURLs.count >= [Lineup minimumNumberOfFillerPhotos];
}
@end
