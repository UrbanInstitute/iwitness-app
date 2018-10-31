#import "LineupPhotoCellDelegate.h"

@class FaceLocator;
@class PhotoAssetMetadataManager;

@interface LineupPhotosDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, strong) NSArray *photoURLs;
@property (nonatomic, assign) NSUInteger maximumNumberOfPhotos;
@property (assign, nonatomic, getter=isEditing) BOOL editing;

- (void)configureWithLineupPhotoCellDelegate:(id <LineupPhotoCellDelegate>)photoCellDelegate metadataManager:(PhotoAssetMetadataManager *)metadataManager;

- (void)removePhotoURL:(NSURL *)photoURL;

@end
