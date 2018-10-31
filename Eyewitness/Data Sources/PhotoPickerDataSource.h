typedef NS_ENUM(NSInteger, PhotoPickerAlbumType) {
    PhotoPickerAlbumTypeLastImport,
    PhotoPickerAlbumTypeAllImported,
    PhotoPickerAlbumTypeCameraRoll
};

@class FaceLocator;

@interface PhotoPickerDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, readonly) PhotoPickerAlbumType albumType;
@property (nonatomic, strong, readonly) ALAssetsLibrary *assetsLibrary;

- (void)configureWithAssetsLibrary:(ALAssetsLibrary *)assetsLibrary faceLocator:(FaceLocator *)faceLocator faceCache:(NSCache *)faceCache;
- (ALAsset *)assetAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForAsset:(ALAsset *)asset;
- (KSPromise *)changeAlbumType:(PhotoPickerAlbumType)albumType;
- (KSPromise *)assetsForAssetURLs:(NSArray *)assetURLs;
@end
