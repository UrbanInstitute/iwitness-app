#import "ImportingPhotoPickerViewController.h"
#import "PhotoPickerDataSource.h"
#import "ImportingPhotoPickerViewControllerDelegate.h"
#import "PhotoAssetImporter.h"
#import "FaceLocatorProvider.h"

@interface ImportingPhotoPickerViewController () <UICollectionViewDelegate>
@property (nonatomic, weak) id<ImportingPhotoPickerViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelItem;
@property (nonatomic, weak) IBOutlet UISegmentedControl *albumTypeSegmentedControl;
@property (nonatomic, weak, readwrite) IBOutlet UICollectionView *photosCollectionView;
@property (nonatomic, strong, readwrite) PhotoPickerDataSource *dataSource;
@property (nonatomic, strong, readwrite) NSMutableArray *selectedAssets;
@property(nonatomic, strong) PhotoAssetImporter *photoAssetImporter;
@end

@implementation ImportingPhotoPickerViewController

- (void)configureWithDelegate:(id <ImportingPhotoPickerViewControllerDelegate>)delegate
                 assetLibrary:(ALAssetsLibrary *)assetsLibrary
            selectedPhotoURLs:(NSArray *)selectedPhotoURLs
           photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter {

    self.delegate = delegate;
    self.photoAssetImporter = photoAssetImporter;
    self.dataSource = ({
        PhotoPickerDataSource *dataSource = [[PhotoPickerDataSource alloc] init];
        FaceLocatorProvider *faceLocatorProvider = [[FaceLocatorProvider alloc] init];
        [dataSource configureWithAssetsLibrary:assetsLibrary faceLocator:[faceLocatorProvider faceLocator] faceCache:[[NSCache alloc] init]];
        dataSource;
    });
    

    self.selectedAssets = [NSMutableArray array];
    NSArray *selectedAssetURLs = [self.photoAssetImporter libraryURLsForImportedPhotoURLs:selectedPhotoURLs];
    [[self.dataSource assetsForAssetURLs:selectedAssetURLs] then:^id(NSSet *selectedAssets) {
        if (selectedAssets) {
            self.selectedAssets = [[selectedAssets allObjects] mutableCopy];
            [self updateSelectButton];
        }
        return nil;
    } error:^id(NSError *error) {
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.photosCollectionView.allowsMultipleSelection = YES;

    if (!self.delegate) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"PhotoPickerViewController must be configured with a delegate" userInfo:nil];
    }

    if (!self.dataSource) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"PhotoPickerViewController must be configured with a data source" userInfo:nil];
    } else {
        self.photosCollectionView.dataSource = self.dataSource;
    }

    [self selectItemsWithSelectedAssets];
    [self updateSelectButton];
}

- (IBAction)cancelTapped:(id)sender {
    [self.delegate photoPickerViewControllerDidCancel:self];
}

- (IBAction)albumTypeValueChanged:(UISegmentedControl *)sender {
    [[self.dataSource changeAlbumType:sender.selectedSegmentIndex] then:^id(id value) {
        [self.photosCollectionView reloadData];
        [self selectItemsWithSelectedAssets];
        return nil;
    } error:^id(NSError *error) {
        return nil;
    }];
}

- (void)selectItemsWithSelectedAssets {
    for (ALAsset *asset in self.selectedAssets) {
        NSIndexPath *indexPath = [self.dataSource indexPathForAsset:asset];
        if (indexPath) {
            [self.photosCollectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
    }
}

- (void)updateSelectButton {
    NSInteger numberOfSelectedItems = self.selectedAssets.count;
    NSString *format = (numberOfSelectedItems == 1 ? @"Select Photo" : @"Select %d Photos");
    NSString *title = [NSString stringWithFormat:format, numberOfSelectedItems];
    UIBarButtonItem *selectPhotosBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:title
                                                  //MOK changes
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(selectPhotosTapped:)];
    switch (numberOfSelectedItems) {
        case 0:
            self.navigationItem.rightBarButtonItem = nil;
            break;
        default:
            self.navigationItem.rightBarButtonItem = selectPhotosBarButtonItem;
            break;
    }
}

- (void)selectPhotosTapped:(id)sender {
    [self.delegate photoPickerViewController:self didImportPhotoURLs:[[self.photoAssetImporter importAssets:self.selectedAssets] copy]];
}

#pragma mark - <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger maximumSelectionCount = [self.delegate maximumSelectionCountForPhotoPickerViewController:self];
    if (maximumSelectionCount <= 1 && self.selectedAssets.count > 0) {
        [self.selectedAssets removeAllObjects];
        NSIndexPath *selectedIndexPath = collectionView.indexPathsForSelectedItems.firstObject;
        [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];

        return YES;
    }

    if (collectionView.indexPathsForSelectedItems.count < maximumSelectionCount) {
        return YES;
    }

    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedAssets addObject:[self.dataSource assetAtIndexPath:indexPath]];
    [self updateSelectButton];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *assetToRemove = [self.dataSource assetAtIndexPath:indexPath];
    NSInteger indexOfAssetToRemove = [self.selectedAssets indexOfObjectPassingTest:^BOOL(ALAsset *obj, NSUInteger idx, BOOL *stop) {
        NSURL *assetURL = [assetToRemove valueForProperty:ALAssetPropertyAssetURL];
        return [assetURL isEqual:[obj valueForProperty:ALAssetPropertyAssetURL]];
    }];
    [self.selectedAssets removeObjectAtIndex:indexOfAssetToRemove];
    [self updateSelectButton];
}

@end
