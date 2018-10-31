#import <Foundation/Foundation.h>

@interface PhotoAssetMetadataManager : NSObject
- (NSURL *)libraryURLForPhotoURL:(NSURL *)photoURL;
- (void)setLibraryURL:(NSURL *)libraryURL forPhotoURL:(NSURL *)photoURL;

- (CGRect)largestFaceRectForPhotoURL:(NSURL *)photoURL;
- (void)setLargestFaceRect:(CGRect)faceRect forPhotoURL:(NSURL *)photoURL;
@end