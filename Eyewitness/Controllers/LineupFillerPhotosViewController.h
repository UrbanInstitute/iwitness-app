#import <UIKit/UIKit.h>
#import "ImportingPhotoPickerViewControllerDelegate.h"

@class Lineup, PhotoAssetImporter;

@interface LineupFillerPhotosViewController : UIViewController<ImportingPhotoPickerViewControllerDelegate>
@property (weak, nonatomic, readonly) UICollectionView *photoCollectionView;
@property (weak, nonatomic, readonly) UILabel *fillerPhotosRequiredLabel;

- (void)configureWithLineup:(Lineup *)lineup photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter;
@end
