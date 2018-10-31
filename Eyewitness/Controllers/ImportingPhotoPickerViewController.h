@class ImportingPhotoPickerViewController;
@class PhotoPickerDataSource;
@class PhotoAssetImporter;
@protocol ImportingPhotoPickerViewControllerDelegate;

@interface ImportingPhotoPickerViewController : UIViewController

@property (nonatomic, weak, readonly) UIBarButtonItem *cancelItem;
@property (nonatomic, weak, readonly) UISegmentedControl *albumTypeSegmentedControl;
@property (nonatomic, weak, readonly) UICollectionView *photosCollectionView;
@property (nonatomic, strong, readonly) PhotoPickerDataSource *dataSource;
@property (nonatomic, strong, readonly) NSMutableArray *selectedAssets;

- (void)configureWithDelegate:(id <ImportingPhotoPickerViewControllerDelegate>)delegate
                 assetLibrary:(ALAssetsLibrary *)assetsLibrary
            selectedPhotoURLs:(NSArray *)selectedPhotoURLs
           photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter;

@end
