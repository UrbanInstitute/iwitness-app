#import "PhotoAssetMetadataManager.h"
#include <sys/xattr.h>

static const char * kPhotoLibraryURL = "com.ljaf.eyewitness.asset.library_url";
static const char * kPhotoLargestFaceRect = "com.ljaf.eyewitness.asset.face_rect";

@implementation PhotoAssetMetadataManager

- (NSURL *)libraryURLForPhotoURL:(NSURL *)photoURL {
    ssize_t dataSize = getxattr([photoURL fileSystemRepresentation], kPhotoLibraryURL, NULL, 0, 0, 0);
    if (dataSize == -1) { return nil; }

    char stringBuffer[dataSize];
    getxattr([photoURL fileSystemRepresentation], kPhotoLibraryURL, stringBuffer, dataSize, 0, 0);
    return [NSURL URLWithString:[NSString stringWithUTF8String:stringBuffer]];
}

- (void)setLibraryURL:(NSURL*)libraryURL forPhotoURL:(NSURL *)assetURL {
    const char * libraryPath = [[libraryURL absoluteString] UTF8String];
    setxattr([assetURL fileSystemRepresentation], kPhotoLibraryURL, libraryPath, strlen(libraryPath)+1, 0, 0);
}

- (CGRect)largestFaceRectForPhotoURL:(NSURL *)photoURL {
    ssize_t dataSize = getxattr([photoURL fileSystemRepresentation], kPhotoLargestFaceRect, NULL, 0, 0, 0);
    if (dataSize == -1) { return CGRectNull; }

    char buffer[dataSize];
    getxattr([photoURL fileSystemRepresentation], kPhotoLargestFaceRect, buffer, dataSize, 0, 0);
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:dataSize freeWhenDone:NO];
    NSDictionary *rectDict = data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;

    CGRect faceRect;
    if (CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)rectDict, &faceRect)) {
        return faceRect;
    } else {
        return CGRectNull;
    }
}

- (void)setLargestFaceRect:(CGRect)faceRect forPhotoURL:(NSURL *)photoURL {
    NSDictionary *rectDict = CFBridgingRelease(CGRectCreateDictionaryRepresentation(faceRect));
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rectDict];
    setxattr([photoURL fileSystemRepresentation], kPhotoLargestFaceRect, [data bytes], data.length, 0, 0);
}

@end
