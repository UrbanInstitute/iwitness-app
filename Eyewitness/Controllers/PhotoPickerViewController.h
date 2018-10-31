@class PhotoPickerViewController;
@class PhotoPickerDataSource;
@protocol PhotoPickerViewControllerDelegate;

@interface PhotoPickerViewController : UIViewController

@property (nonatomic, weak, readonly) UIBarButtonItem *cancelItem;
@property (nonatomic, weak, readonly) UISegmentedControl *albumTypeSegmentedControl;
@property (nonatomic, weak, readonly) UICollectionView *photosCollectionView;
@property (nonatomic, strong, readonly) PhotoPickerDataSource *dataSource;
@property (nonatomic, strong, readonly) NSMutableArray *selectedAssets;

- (void)configureWithDelegate:(id<PhotoPickerViewControllerDelegate>)delegate
                   dataSource:(PhotoPickerDataSource *)dataSource
               selectedAssetURLs:(NSArray *)selectedAssetURLs;

@end
