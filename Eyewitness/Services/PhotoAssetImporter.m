#import "PhotoAssetImporter.h"
#import "FaceLocator.h"
#import "PhotoAssetMetadataManager.h"

@interface PhotoAssetImporter ()
@property (nonatomic, strong) NSURL *destinationDirectory;
@property (nonatomic, strong) FaceLocator *faceLocator;
@property (nonatomic, strong) PhotoAssetMetadataManager *metadataManager;
@end

@implementation PhotoAssetImporter

- (instancetype)init {
    return [self initWithDestinationDirectory:nil faceLocator:nil metadataManager:nil];
}

- (instancetype)initWithDestinationDirectory:(NSURL *)destinationDirectory faceLocator:(FaceLocator *)faceLocator metadataManager:(PhotoAssetMetadataManager *)metadataManager {
    if (!destinationDirectory) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"PhotoAssetImporter: must specify a valid destination directory" userInfo:nil];
    }

    if (self = [super init]) {
        self.destinationDirectory = destinationDirectory;
        self.faceLocator = faceLocator;
        self.metadataManager = metadataManager;
    }
    return self;
}

- (NSArray *)importAssets:(NSArray *)assets {
    NSMutableArray *importedURLs = [[NSMutableArray alloc] init];

    for (ALAsset *asset in assets) {
        NSURL *libraryURL = [asset valueForProperty:ALAssetPropertyAssetURL];

        ALAssetRepresentation *representation = [asset defaultRepresentation];
        CGImageRef cgImage = [representation fullScreenImage];
        if (cgImage) {
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            NSData *pngRepresentation = UIImagePNGRepresentation(image);

            NSURL *importURL = [self uniqueURLForImporting];
            if ([pngRepresentation writeToURL:importURL atomically:YES]) {
                [importedURLs addObject:importURL];
                [self.metadataManager setLibraryURL:libraryURL forPhotoURL:importURL];

                if (self.faceLocator) {
                    CGRect faceRect = [self.faceLocator locateLargestFaceInImage:image];
                    if (!CGRectEqualToRect(faceRect, CGRectNull)) {
                        [self.metadataManager setLargestFaceRect:faceRect forPhotoURL:importURL];
                    }
                }
            }
        }
    }

    return importedURLs;
}

- (NSURL *)uniqueURLForImporting {
    return [[self.destinationDirectory URLByAppendingPathComponent:[[[NSUUID alloc] init] UUIDString]] URLByAppendingPathExtension:@"png"];
}

- (NSArray *)libraryURLsForImportedPhotoURLs:(NSArray *)photoURLs {
    NSMutableArray *libraryURLs = [NSMutableArray array];
    for (NSURL *photoURL in photoURLs) {
        NSURL *libraryURL = [self.metadataManager libraryURLForPhotoURL:photoURL];
        if (libraryURL) {
            [libraryURLs addObject:libraryURL];
        }
    }
    return [libraryURLs copy];
}

- (NSArray *)largestFaceRectsForImportedPhotoURLs:(NSArray *)photoURLs {
    NSMutableArray *faceRects = [NSMutableArray array];
    for (NSURL *photoURL in photoURLs) {
        CGRect faceRect = [self.metadataManager largestFaceRectForPhotoURL:photoURL];
        [faceRects addObject:[NSValue valueWithCGRect:faceRect]];
    }
    return [faceRects copy];
}

@end
