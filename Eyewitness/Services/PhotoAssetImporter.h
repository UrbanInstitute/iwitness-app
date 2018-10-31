@class FaceLocator;
@class PhotoAssetMetadataManager;

@interface PhotoAssetImporter : NSObject

- (instancetype)initWithDestinationDirectory:(NSURL *)destinationDirectory faceLocator:(FaceLocator *)faceLocator metadataManager:(PhotoAssetMetadataManager *)metadataManager;
- (NSArray *)importAssets:(NSArray *)assets;
- (NSArray *)libraryURLsForImportedPhotoURLs:(NSArray *)photoURLs;
- (NSArray *)largestFaceRectsForImportedPhotoURLs:(NSArray *)photoURLs;

@end
